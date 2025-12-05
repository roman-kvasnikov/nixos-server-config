{
  config,
  lib,
  pkgs,
  hostname,
  ...
}: let
  cfg = config.services.resticctl;
in {
  options.services.resticctl = {
    enable = lib.mkEnableOption "Enable Restic backups";

    repository = lib.mkOption {
      description = "Restic repository (S3 or SFTP)";
      type = lib.types.str;
      # default = "s3:https://s3.twcstorage.ru/1f382b96-c34b0ea3-eb1f-4476-b009-6e99275d7b19/backups/${hostname}";
      default = "sftp:backup@192.168.1.11:/home/backup/backups/${hostname}";
    };

    passwordFile = lib.mkOption {
      description = "File with RESTIC_PASSWORD";
      type = lib.types.path;
      default = config.age.secrets.restic-password.path;
    };

    environmentFile = lib.mkOption {
      description = "File with S3 credentials for Restic.";
      type = lib.types.nullOr lib.types.path;
      default = null;
      # default = config.age.secrets.s3-env.path;
    };

    schedule = lib.mkOption {
      description = "Systemd OnCalendar schedule (e.g., daily, weekly, hourly)";
      type = lib.types.str;
      default = "04:00";
    };

    prune = lib.mkOption {
      description = "Retention policy for restic prune.";
      type = lib.types.attrsOf lib.types.str;
      default = {
        keepDaily = "7";
        keepWeekly = "4";
        keepMonthly = "6";
      };
    };

    serialize = lib.mkOption {
      description = ''
        If true, ensures that restic backup jobs run sequentially (not in parallel)
        by adding After= dependencies between them.
        This prevents repository lock conflicts when using a shared repo.
      '';
      type = lib.types.bool;
      default = true;
    };

    jobs = lib.mkOption {
      description = "All Restic backup jobs";

      type = lib.types.attrsOf (lib.types.submodule ({name, ...}: {
        options = {
          paths = lib.mkOption {
            description = "Paths to backup.";
            type = lib.types.listOf lib.types.path;
          };
        };
      }));

      default = {};
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      restic
    ];

    services.restic.backups = let
      jobNames = lib.attrNames cfg.jobs;
    in
      lib.listToAttrs (lib.imap0
        (index: name: let
          job = cfg.jobs.${name};
          prevJobName =
            if index > 0
            then builtins.elemAt jobNames (index - 1)
            else null;

          afterDeps =
            if cfg.serialize && prevJobName != null
            then ["After=restic-backup-${prevJobName}.service"]
            else [];

          serviceTuning = [
            "Nice=10"
            "IOSchedulingClass=idle"
          ];
        in {
          name = name;
          value = {
            initialize = true;
            repository = cfg.repository;
            passwordFile = cfg.passwordFile;
            environmentFile = lib.mkIf (cfg.environmentFile != null) cfg.environmentFile;
            paths = job.paths;

            extraBackupArgs = [
              "--tag ${name}"
            ];

            timerConfig = {
              OnCalendar = cfg.schedule;
              Persistent = true;
            };

            pruneOpts = [
              "--keep-daily ${cfg.prune.keepDaily}"
              "--keep-weekly ${cfg.prune.keepWeekly}"
              "--keep-monthly ${cfg.prune.keepMonthly}"
            ];

            # extraOptions = afterDeps ++ serviceTuning;

            # extraOptions =
            #   afterDeps
            #   ++ [
            #     "After=wake-backup-server.service"
            #   ]
            #   ++ lib.optional (index == (builtins.length jobNames - 1)) "OnSuccess=shutdown-backup-server.service"
            #   ++ serviceTuning;

            extraOptions = lib.unique (
              afterDeps
              ++ ["After=wake-backup-server.service"] # обязательно после пробуждения сервера
              ++ lib.optional (index == (builtins.length jobNames - 1)) "OnSuccess=shutdown-backup-server.service"
              ++ serviceTuning
            );
          };
        })
        jobNames);

    # 1. Сервис пробуждения бэкап-сервера
    systemd.services.wake-backup-server = {
      description = "Wake backup server before restic backup";
      serviceConfig = {
        Type = "oneshot";
      };
      path = [pkgs.wakeonlan pkgs.openssh];
      script = ''
        MAC="1c:1b:0d:8b:d7:1f"
        BACKUP_IP="192.168.1.11"

        echo "→ Sending Wake-on-LAN magic packet to $MAC"
        wakeonlan "$MAC"

        echo "→ Waiting for backup server to accept SSH…"
        until ssh -o ConnectTimeout=3 -o StrictHostKeyChecking=no \
            backup@$BACKUP_IP "echo ok" >/dev/null 2>&1; do
          sleep 60
        done

        echo "→ Backup server is online."
      '';
    };

    # 2. Сервис выключения бэкап-сервера после завершения restic
    systemd.services.shutdown-backup-server = {
      description = "Shutdown backup server after all restic jobs finish";
      serviceConfig = {
        Type = "oneshot";
      };
      path = [pkgs.openssh];
      script = ''
        BACKUP_IP="192.168.1.11"

        echo "→ Shutting down backup server..."
        ssh backup@$BACKUP_IP "sudo shutdown -h now"
      '';
    };

    age.secrets = {
      restic-password = {
        file = ../../../secrets/restic.password.age;
        owner = "root";
        group = "root";
        mode = "0400";
      };
      s3-env = {
        file = ../../../secrets/s3.env.age;
        owner = "root";
        group = "root";
        mode = "0400";
      };
    };
  };
}
