{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.homelab.services.sambactl;
  cfgHomelab = config.homelab;
in {
  options.homelab.services.sambactl = {
    enable = lib.mkEnableOption "Enable Samba (SMB/CIFS) file sharing";

    sharesDir = lib.mkOption {
      description = "Directory for Samba sharing paths";
      type = lib.types.path;
      default = "/data/Shares";
    };

    users = lib.mkOption {
      description = "List of Samba users";
      type = lib.types.listOf lib.types.str;
      default = [];
    };

    environmentFile = lib.mkOption {
      description = "Path to environment file for Samba";
      type = lib.types.nullOr lib.types.path;
      default = null;
    };

    globalSettings = lib.mkOption {
      description = "Global Samba (SMB/CIFS) parameters";
      type = lib.types.attrsOf (lib.types.oneOf [
        lib.types.str
        (lib.types.listOf lib.types.str)
        lib.types.bool
        lib.types.int
      ]);
      default = {};
    };

    shares = lib.mkOption {
      description = "Samba shares configuration";

      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          directory = lib.mkOption {
            description = "Name of the shared directory";
            type = lib.types.str;
          };

          comment = lib.mkOption {
            description = "Share comment/description";
            type = lib.types.str;
            default = "";
          };

          public = lib.mkOption {
            description = "Whether this is a public share";
            type = lib.types.bool;
            default = true;
          };

          browseable = lib.mkOption {
            description = "Whether share is visible in network browsing";
            type = lib.types.bool;
            default = true;
          };

          writeable = lib.mkOption {
            description = "Whether share is writeable";
            type = lib.types.bool;
            default = true;
          };

          validUsers = lib.mkOption {
            description = "List of users allowed to access this share";
            type = lib.types.listOf lib.types.str;
            default = [];
          };

          forceUser = lib.mkOption {
            description = "Force all operations to be done as this user";
            type = lib.types.nullOr lib.types.str;
            default = null;
          };

          forceGroup = lib.mkOption {
            description = "Force all operations to be done as this group";
            type = lib.types.nullOr lib.types.str;
            default = null;
          };

          extraConfig = lib.mkOption {
            description = "Extra parameters for this share";
            type = lib.types.attrsOf (lib.types.oneOf [
              lib.types.str
              (lib.types.listOf lib.types.str)
              lib.types.bool
              lib.types.int
            ]);
            default = {};
          };
        };
      });

      default = {};
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      samba
      cifs-utils
    ];

    users = {
      users =
        lib.genAttrs cfg.users (_: {
          isNormalUser = true;
          extraGroups = ["samba"];
        })
        // {
          samba = {
            isSystemUser = true;
            group = "samba";
          };
        };

      groups.samba = {};
    };

    # Создаем директории для Samba shares с правильными правами
    systemd.tmpfiles.rules =
      ["d ${cfg.sharesDir} 0755 root root - -"]
      ++ lib.flatten (
        lib.mapAttrsToList (
          name: share: let
            user =
              if share.forceUser != null
              then share.forceUser
              else "samba";
            group =
              if share.forceGroup != null
              then share.forceGroup
              else "samba";
            # Для приватных шар используем более строгие права
            mode =
              if share.public
              then "0775"
              else "0770";
          in "d ${cfg.sharesDir}/${share.directory} ${mode} ${user} ${group} - -"
        )
        cfg.shares
      );

    # Скрипт для создания паролей пользователей Samba
    systemd.services."samba-users-setup" = {
      description = "Setup Samba users and passwords";
      before = ["smb.service"];
      after = ["network.target" "agenix.service"];
      wants = ["agenix.service"];
      wantedBy = ["multi-user.target"];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        User = "root";
        EnvironmentFile = cfg.environmentFile;
        Environment = "PATH=${pkgs.coreutils}/bin:${pkgs.samba}/bin:${pkgs.glibc.bin}/bin";
      };

      # Добавляем путь к интерпретатору
      path = with pkgs; [coreutils samba glibc.bin];

      script = ''
        set -euo pipefail
        sleep 2

        echo "Setting up Samba users from environment file"

        users_list="${lib.concatStringsSep " " cfg.users}"

        if [ -z "$users_list" ]; then
          echo "No users defined in configuration."
        else
          for username in $users_list; do
            echo "Processing user: $username"

            # Получаем пароль из переменной окружения с таким же именем
            var_name="SAMBA_\$username_PASSWORD"
            PASSWORD=$(printenv "$var_name" || true)

            if [ -z "$PASSWORD" ]; then
              echo "⚠️ Warning: no password for user '$username' in environment file ($var_name)."
              continue
            fi

            echo "Creating/updating Samba account for '$username'..."

            # Удаляем, если уже есть (чтобы обновить)
            ${pkgs.samba}/bin/pdbedit -x -u "$username" 2>/dev/null || true

            # Добавляем с паролем
            printf "%s\n%s\n" "$PASSWORD" "$PASSWORD" | \
              ${pkgs.samba}/bin/smbpasswd -a -s "$username"

            # Включаем пользователя
            ${pkgs.samba}/bin/smbpasswd -e "$username"

            echo "✅ User '$username' configured successfully."
          done
        fi

        echo ""
        echo "Checking system Samba user..."

        if id "samba" &>/dev/null; then
          echo "Setting up system Samba user..."

          ${pkgs.samba}/bin/pdbedit -x -u samba 2>/dev/null || true
          printf "guest\nguest\n" | ${pkgs.samba}/bin/smbpasswd -a -s samba
          ${pkgs.samba}/bin/smbpasswd -e samba

          echo "✅ System Samba user configured successfully."
        else
          echo "⚠️ System Samba user does not exist, skipping Samba setup for this user."
        fi

        echo ""
        echo "Samba users setup completed."
      '';
    };

    services.samba = {
      enable = true;

      openFirewall = true;

      settings =
        {
          global = lib.mkMerge [
            {
              "workgroup" = "WORKGROUP";
              "server string" = "${config.networking.hostName} Samba Server";
              "netbios name" = config.networking.hostName;
              "security" = "user";
              "invalid users" = ["root"];
              "hosts allow" = ["192.168.0.0/16" "10.0.0.0/8" "127.0.0.1" "localhost"];
              "hosts deny" = ["0.0.0.0/0"];
              "guest account" = "samba";
              "map to guest" = "bad user";
              "passdb backend" = "tdbsam";
              "printing" = "bsd";
              "printcap name" = "/dev/null";
              "load printers" = "no";
              "disable spoolss" = "yes";

              # Улучшенная производительность
              "use sendfile" = "yes";
              "min protocol" = "SMB2";
              "max protocol" = "SMB3";

              # Логирование
              "log file" = "/var/log/samba/log.%m";
              "max log size" = "10000";
              "log level" = "1";
            }
            cfg.globalSettings
          ];
        }
        // (
          lib.mapAttrs (
            name: share: let
              baseConfig = {
                "path" = "${cfg.sharesDir}/${share.directory}";
                "browseable" =
                  if share.browseable
                  then "yes"
                  else "no";
                "read only" =
                  if share.writeable
                  then "no"
                  else "yes";
                "writeable" =
                  if share.writeable
                  then "yes"
                  else "no";
                "create mask" = "0664";
                "directory mask" = "0775";
                "preserve case" = "yes";
                "short preserve case" = "yes";
              };

              publicConfig =
                if share.public
                then {
                  "public" = "yes";
                  "guest ok" = "yes";
                  "force user" = "samba";
                  "force group" = "samba";
                }
                else
                  {
                    "public" = "no";
                    "guest ok" = "no";
                    "valid users" = lib.concatStringsSep " " share.validUsers;
                  }
                  // lib.optionalAttrs (share.forceUser != null) {
                    "force user" = share.forceUser;
                  }
                  // lib.optionalAttrs (share.forceGroup != null) {
                    "force group" = share.forceGroup;
                  };

              commentConfig = lib.optionalAttrs (share.comment != "") {
                "comment" = share.comment;
              };
            in
              baseConfig // publicConfig // commentConfig // share.extraConfig
          )
          cfg.shares
        );
    };

    # Samba Web Service Discovery для Windows 10/11
    services.samba-wsdd = {
      enable = true;

      openFirewall = true;

      workgroup = "WORKGROUP";
      hostname = config.networking.hostName;
    };

    # Avahi для обнаружения в сети
    services.avahi = {
      enable = true;

      openFirewall = true;

      publish = {
        enable = true;
        addresses = true;
        domain = true;
        hinfo = true;
        userServices = true;
        workstation = true;
      };

      nssmdns4 = true;

      extraServiceFiles = {
        smb = ''
          <?xml version="1.0" standalone='no'?><!--*-nxml-*-->
          <!DOCTYPE service-group SYSTEM "avahi-service.dtd">
          <service-group>
            <name replace-wildcards="yes">%h SMB</name>
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
