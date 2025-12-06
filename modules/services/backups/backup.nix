{
  config,
  lib,
  pkgs,
  hostname,
  ...
}: let
  cfg = config.services.backupctl;
in {
  options.services.backupctl = {
    enable = lib.mkEnableOption "Enable global Backup system";

    backupServerMac = lib.mkOption {
      description = "MAC address of the backup server";
      type = lib.types.str;
      default = "1c:1b:0d:8b:d7:1f";
    };

    backupServerIp = lib.mkOption {
      description = "IP address of the backup server";
      type = lib.types.str;
      default = "192.168.1.11";
    };

    repository = lib.mkOption {
      description = "Restic repository (S3 or SFTP)";
      type = lib.types.str;
      default = "sftp:backup@${cfg.backupServerIp}:/home/backup/backups/${hostname}";
    };

    passwordFile = lib.mkOption {
      description = "File with RESTIC_PASSWORD";
      type = lib.types.path;
      default = config.age.secrets.restic-password.path;
    };

    environmentFile = lib.mkOption {
      description = "File with S3 credentials for Restic";
      type = lib.types.nullOr lib.types.path;
      default = null;
    };

    schedule = lib.mkOption {
      description = "Systemd OnCalendar schedule (e.g., daily, weekly, hourly)";
      type = lib.types.str;
      default = "03:00";
    };

    prune = lib.mkOption {
      description = "Retention policy for restic prune";
      type = lib.types.attrsOf lib.types.str;
      default = {
        keepDaily = "7";
        keepWeekly = "4";
        keepMonthly = "6";
      };
    };

    serialize = lib.mkOption {
      description = "Run backup jobs sequentially instead of in parallel";
      type = lib.types.bool;
      default = true;
    };

    jobs = lib.mkOption {
      description = "All backup jobs";
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            database = lib.mkOption {
              description = "Database name to backup";
              type = lib.types.nullOr lib.types.str;
              default = null;
            };
            paths = lib.mkOption {
              description = "Paths to backup";
              type = lib.types.listOf lib.types.path;
              default = [];
            };
          };
        }
      );
      default = {};
    };
  };

  config = lib.mkIf cfg.enable (
    let
      # Собираем все базы данных для бекапа (исключаем null)
      databasesToBackup = lib.filter (db: db != null) (
        lib.mapAttrsToList (_: job: job.database) cfg.jobs
      );
      hasDbBackups = databasesToBackup != [];

      # Собираем jobs с непустыми paths
      jobsWithPaths = lib.filterAttrs (_: job: job.paths != []) cfg.jobs;

      # Формируем финальный набор restic jobs
      resticJobs =
        # Добавляем postgresql job если есть бекапы БД
        (lib.optionalAttrs hasDbBackups {
          postgresql.paths = [config.services.postgresqlBackup.location];
        })
        # Добавляем все jobs с paths (убираем поле database)
        // lib.mapAttrs (_: job: {inherit (job) paths;}) jobsWithPaths;

      resticJobNames = lib.attrNames resticJobs;

      # Общие настройки для всех restic jobs
      mkResticJob = name: paths: {
        initialize = true;

        repository = cfg.repository;
        passwordFile = cfg.passwordFile;
        environmentFile = lib.mkIf (cfg.environmentFile != null) cfg.environmentFile;

        inherit paths;

        extraBackupArgs = ["--tag ${name}"];

        timerConfig = {
          OnCalendar = cfg.schedule;
          Persistent = true;
        };

        pruneOpts = [
          "--keep-daily ${cfg.prune.keepDaily}"
          "--keep-weekly ${cfg.prune.keepWeekly}"
          "--keep-monthly ${cfg.prune.keepMonthly}"
        ];
      };

      # Настройки systemd для job с учётом сериализации и WoL
      mkSystemdOverrides = index: name: let
        prevJobName =
          if index > 0
          then builtins.elemAt resticJobNames (index - 1)
          else null;
        isLast = index == (builtins.length resticJobNames - 1);
      in {
        after =
          ["wake-backup-server.service"]
          ++ lib.optional (cfg.serialize && prevJobName != null) "restic-backups-${prevJobName}.service";

        wants = ["wake-backup-server.service"];

        onSuccess = lib.optional isLast "shutdown-backup-server.service";
        onFailure = lib.optional isLast "shutdown-backup-server.service";

        serviceConfig = {
          Nice = 10;
          IOSchedulingClass = "idle";
        };
      };
    in {
      services.postgresqlBackup = lib.mkIf hasDbBackups {
        enable = true;
        databases = databasesToBackup;
        location = "/mnt/data/AppData/Postgresql/backups";
      };

      environment.systemPackages = with pkgs; [
        restic
      ];

      services.restic.backups =
        lib.mapAttrs
        (name: job: mkResticJob name job.paths)
        resticJobs;

      systemd.services =
        # Overrides для restic jobs
        lib.listToAttrs (
          lib.imap0
          (index: name: {
            name = "restic-backups-${name}";
            value = mkSystemdOverrides index name;
          })
          resticJobNames
        )
        # WoL сервисы
        // {
          wake-backup-server = {
            description = "Wake backup server before restic backup";
            serviceConfig.Type = "oneshot";
            path = [pkgs.wakeonlan pkgs.openssh];
            script = ''
              MAC="${cfg.backupServerMac}"
              BACKUP_IP="${cfg.backupServerIp}"

              echo "→ Sending Wake-on-LAN magic packet to $MAC"
              wakeonlan "$MAC"

              echo "→ Waiting for backup server to accept SSH..."
              until ssh -o ConnectTimeout=10 backup@$BACKUP_IP "echo ok" >/dev/null 2>&1; do
                sleep 60
              done

              echo "→ Backup server is online."
            '';
          };

          shutdown-backup-server = {
            description = "Shutdown backup server after all restic jobs finish";
            serviceConfig.Type = "oneshot";
            path = [pkgs.openssh];
            script = ''
              BACKUP_IP="${cfg.backupServerIp}"

              echo "→ Shutting down backup server..."
              ssh backup@$BACKUP_IP "sudo shutdown -h now"
            '';
          };
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
    }
  );
}
