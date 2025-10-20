{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.homelab.services.sambactl;
  cfgServer = config.server;
in {
  options.homelab.services.sambactl = {
    enable = lib.mkEnableOption "Enable Samba (SMB/CIFS) file sharing";

    users = lib.mkOption {
      description = "Samba users with their passwords";
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          passwordFile = lib.mkOption {
            description = "Path to file containing the user's Samba password";
            type = lib.types.path;
            example = "/run/secrets/samba-user-password";
          };

          # Опциональные группы для пользователя
          groups = lib.mkOption {
            description = "Additional groups for this user";
            type = lib.types.listOf lib.types.str;
            default = [];
          };
        };
      });
      default = {};
      example = lib.literalExpression ''
        {
          alice = {
            passwordFile = "/run/secrets/alice-samba-password";
            groups = [ "media" "documents" ];
          };
          bob = {
            passwordFile = "/run/secrets/bob-samba-password";
          };
        }
      '';
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
          path = lib.mkOption {
            description = "Path to the shared directory";
            type = lib.types.path;
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
    # Создаем пользователей для Samba
    users.users =
      lib.mapAttrs (name: userCfg: {
        isNormalUser = true;
        extraGroups = [cfgServer.systemGroup] ++ userCfg.groups;
      })
      cfg.users;

    environment.systemPackages = with pkgs; [
      samba
      cifs-utils
    ];

    # Создаем директории для шар с правильными правами
    systemd.tmpfiles.rules = lib.flatten (
      lib.mapAttrsToList (
        name: share: let
          user =
            if share.forceUser != null
            then share.forceUser
            else cfgServer.systemUser;
          group =
            if share.forceGroup != null
            then share.forceGroup
            else cfgServer.systemGroup;
          # Для приватных шар используем более строгие права
          mode =
            if share.public
            then "0775"
            else "0770";
        in "d ${share.path} ${mode} ${user} ${group} - -"
      )
      cfg.shares
    );

    # Скрипт для создания паролей пользователей Samba
    systemd.services."samba-users-setup" = {
      description = "Setup Samba users and passwords";
      wantedBy = ["multi-user.target"];
      before = ["smb.service"];
      after = ["network.target"];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        User = "root";
      };

      script = ''
        # Создаем пользователей Samba с паролями из файлов
        ${lib.concatStringsSep "\n" (
          lib.mapAttrsToList (username: userCfg: ''
            if [ -f "${userCfg.passwordFile}" ]; then
              echo "Setting up Samba user: ${username}"
              # Удаляем пользователя если существует
              ${pkgs.samba}/bin/pdbedit -x -u ${username} 2>/dev/null || true
              # Добавляем пользователя с паролем
              (cat "${userCfg.passwordFile}"; echo; cat "${userCfg.passwordFile}") | \
                ${pkgs.samba}/bin/smbpasswd -a -s ${username}
              ${pkgs.samba}/bin/smbpasswd -e ${username}
            else
              echo "Warning: Password file not found for user ${username}"
            fi
          '')
          cfg.users
        )}

        # Также создаем системного пользователя для публичных шар (с простым паролем)
        echo "Setting up system Samba user: ${cfgServer.systemUser}"
        ${pkgs.samba}/bin/pdbedit -x -u ${cfgServer.systemUser} 2>/dev/null || true
        echo -e "guest\nguest" | ${pkgs.samba}/bin/smbpasswd -a -s ${cfgServer.systemUser}
        ${pkgs.samba}/bin/smbpasswd -e ${cfgServer.systemUser}
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
              "invalid users" = ["root"]; # Исправлено: теперь это список
              "hosts allow" = ["192.168.0.0/16" "10.0.0.0/8" "127.0.0.1" "localhost"]; # Исправлено: теперь это список
              "hosts deny" = ["0.0.0.0/0"]; # Исправлено: теперь это список
              "guest account" = cfgServer.systemUser;
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
                "path" = share.path;
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
                  "force user" = cfgServer.systemUser;
                  "force group" = cfgServer.systemGroup;
                }
                else
                  {
                    "public" = "no";
                    "guest ok" = "no";
                    "valid users" = lib.concatStringsSep " " share.validUsers; # Для valid users нужна строка с пробелами
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
