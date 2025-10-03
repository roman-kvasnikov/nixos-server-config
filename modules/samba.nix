{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.sambactl;
in {
  options.services.sambactl = {
    enable = lib.mkEnableOption {
      description = "Enable Samba";
      default = false;
    };

    passwordFile = lib.mkOption {
      description = "Path to Samba password file";
      type = lib.types.path;
      default = /dev/null;
    };

    users = lib.mkOption {
      description = "List of users to create Samba accounts for";
      type = lib.types.listOf lib.types.str;
      default = [];
      example = ["user1" "user2"];
    };

    globalSettings = lib.mkOption {
      description = "Global Samba parameters";
      type = lib.types.attrsOf lib.types.str;
      default = {};
      example = {
        "browseable" = "yes";
        "writeable" = "yes";
        "read only" = "no";
        "guest ok" = "no";
      };
    };

    commonSettings = lib.mkOption {
      description = "Parameters applied to each share";
      type = lib.types.attrsOf lib.types.str;
      default = {};
      example = {
        "security" = "user";
        "invalid users" = ["root"];
      };
      apply = old:
        lib.attrsets.mergeAttrsList [
          {
            "public" = "yes";
            "preserve case" = "yes";
            "short preserve case" = "yes";
            "browseable" = "yes";
            "writeable" = "yes";
            "guest ok" = "yes";
            "read only" = "no";
            "create mask" = "0644";
            "directory mask" = "0755";
            "force user" = "nobody";
            "force group" = "nogroup";
          }
          old
        ];
    };

    shares = lib.mkOption {
      description = "Samba shares";
      type = lib.types.attrs;
      default = {};
      example = lib.literalExpression ''
        CoolShare = {
          "path" = "/mnt/CoolShare";
          ...
        };
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [config.services.samba.package];

    systemd.tmpfiles.rules = map (
      share: let
        shareSettings = cfg.commonSettings // share;
      in "d ${shareSettings."path"} 0775 ${shareSettings."force user"} ${shareSettings."force group"} - -"
    ) (lib.attrValues cfg.shares);

    systemd.services.samba-user-sync = {
      description = "Sync Samba users from shares configuration with system passwords";
      before = ["samba-smbd.service"];
      wantedBy = ["multi-user.target"];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;

        ExecStart = pkgs.writeShellScript "samba-user-sync" ''
          users='${lib.concatStringsSep " " cfg.users}'

          for user in $users; do
            # Проверить, что пользователь существует в системе
            if id "$user" >/dev/null 2>&1; then
              if ! smbpasswd -e "$user" >/dev/null 2>&1; then
                echo "Creating Samba user: $user"
                # Создать пользователя Samba без пароля сначала
                smbpasswd -a "$user" -n
                smbpasswd -e "$user"
                echo "Samba user $user created"
              else
                echo "Samba user $user already exists"
              fi

              # Синхронизировать пароль с системным
              echo "Syncing password for user: $user"
              # Получить системный пароль и установить его в Samba
              system_password=$(getent shadow "$user" | cut -d: -f2)
              if [ "$system_password" != "*" ] && [ "$system_password" != "!" ] && [ -n "$system_password" ]; then
                # Установить системный пароль в Samba
                echo "$user:$system_password" | smbpasswd -s
                echo "Password synced for user: $user"
              else
                echo "Warning: No system password found for user $user, using default"
                # Установить пароль по умолчанию
                echo "$user:changeme" | smbpasswd -s
                echo "Default password 'changeme' set for user: $user"
              fi
            else
              echo "Warning: System user $user does not exist, skipping Samba user creation"
            fi
          done
        '';
      };
    };

    services.samba = {
      enable = true;

      openFirewall = true;

      settings =
        {
          global = lib.mkMerge [
            {
              "workgroup" = lib.mkDefault "WORKGROUP";
              "server string" = lib.mkDefault config.networking.hostName;
              "netbios name" = lib.mkDefault config.networking.hostName;
              "security" = lib.mkForce "user";
              "invalid users" = lib.mkForce ["root"];
              "hosts allow" = lib.mkForce "192.168.1.0/24 127.0.0.1 localhost";
              "hosts deny" = lib.mkForce "0.0.0.0/0";
              "guest account" = lib.mkForce "nobody";
              "map to guest" = lib.mkForce "bad user";
              "passdb backend" = lib.mkForce "tdbsam";
            }
            cfg.globalSettings
          ];
        }
        // builtins.mapAttrs (_name: value: cfg.commonSettings // value) cfg.shares;
    };

    services.samba-wsdd = {
      enable = true;

      openFirewall = true;
    };

    services.avahi = {
      enable = true;

      openFirewall = true;

      publish = {
        enable = true;

        userServices = true;
      };

      nssmdns4 = true;

      extraServiceFiles = {
        smb = ''
          <?xml version="1.0" standalone='no'?><!--*-nxml-*-->
          <!DOCTYPE service-group SYSTEM "avahi-service.dtd">
          <service-group>
            <name replace-wildcards="yes">%h</name>
            <service>
              <type>_smb._tcp</type>
              <port>445</port>
            </service>
          </service-group>
        '';
      };
    };
  };
}
