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
      default = "/data/shares";
    };

    users = lib.mkOption {
      description = "Samba users with their passwords";
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          passwordFile = lib.mkOption {
            description = "Path to file containing the user's Samba password";
            type = lib.types.path;
            example = config.age.secrets.user-samba-password.path;
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
            passwordFile = config.age.secrets.alice-samba-password.path;
            groups = [ "media" "documents" ];
          };
          bob = {
            passwordFile = config.age.secrets.bob-samba-password.path;
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

    # Создаем пользователей для Samba
    users.users =
      lib.mapAttrs (username: userCfg: {
        isNormalUser = true;
        extraGroups = [cfgHomelab.systemGroup] ++ userCfg.groups;
      })
      cfg.users;

    # Создаем директории для шар с правильными правами
    systemd.tmpfiles.rules =
      ["d ${cfg.sharesDir} 0755 root root - -"]
      ++ lib.flatten (
        lib.mapAttrsToList (
          name: share: let
            user =
              if share.forceUser != null
              then share.forceUser
              else cfgHomelab.systemUser;
            group =
              if share.forceGroup != null
              then share.forceGroup
              else cfgHomelab.systemGroup;
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
      wantedBy = ["multi-user.target"];
      before = ["smb.service"];
      after = ["network.target" "agenix.service"];
      wants = ["agenix.service"];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        User = "root";
        # Добавляем переменную окружения для отладки
        Environment = "PATH=${pkgs.coreutils}/bin:${pkgs.samba}/bin:${pkgs.glibc.bin}/bin";
      };

      # Добавляем путь к интерпретатору
      path = with pkgs; [coreutils samba glibc.bin];

      script = ''
        sleep 2

        # Создаем пользователей Samba с паролями из файлов
        ${lib.concatStringsSep "\n" (
          lib.mapAttrsToList (username: userCfg: ''

            # Ждем пока файл с паролем появится (максимум 10 секунд)
            COUNTER=0
            while [ ! -f "${userCfg.passwordFile}" ] && [ $COUNTER -lt 10 ]; do
              echo "Waiting for password file ${userCfg.passwordFile} to appear..."
              sleep 1
              COUNTER=$((COUNTER + 1))
            done

            if [ -f "${userCfg.passwordFile}" ]; then
              echo "Setting up Samba user: ${username}"

              # Читаем пароль из файла (убираем лишние переносы строк)
              PASSWORD=$(cat "${userCfg.passwordFile}" | tr -d '\n')

              # Удаляем пользователя если существует
              ${pkgs.samba}/bin/pdbedit -x -u ${username} 2>/dev/null || true

              # Добавляем пользователя с паролем используя printf для точного форматирования
              printf "%s\n%s\n" "$PASSWORD" "$PASSWORD" | \
                ${pkgs.samba}/bin/smbpasswd -a -s ${username}

              # Включаем пользователя
              ${pkgs.samba}/bin/smbpasswd -e ${username}

              echo "User ${username} configured successfully"
            else
              echo "Warning: Password file not found for user ${username} at ${userCfg.passwordFile}"
            fi
          '')
          cfg.users
        )}

        # Также создаем системного пользователя для публичных шар
        if id "${cfgHomelab.systemUser}" &>/dev/null; then
          echo "Setting up system Samba user: ${cfgHomelab.systemUser}"
          ${pkgs.samba}/bin/pdbedit -x -u ${cfgHomelab.systemUser} 2>/dev/null || true
          printf "guest\nguest\n" | ${pkgs.samba}/bin/smbpasswd -a -s ${cfgHomelab.systemUser}
          ${pkgs.samba}/bin/smbpasswd -e ${cfgHomelab.systemUser}
          echo "System user ${cfgHomelab.systemUser} configured successfully"
        else
          echo "System user ${cfgHomelab.systemUser} does not exist, skipping Samba setup for this user"
        fi
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
              "guest account" = cfgHomelab.systemUser;
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
                  "force user" = cfgHomelab.systemUser;
                  "force group" = cfgHomelab.systemGroup;
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
