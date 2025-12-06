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
      description = "File with S3 credentials for Restic.";
      type = lib.types.nullOr lib.types.path;
      default = null;
    };

    schedule = lib.mkOption {
      description = "Systemd OnCalendar schedule (e.g., daily, weekly, hourly)";
      type = lib.types.str;
      default = "03:00";
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

    jobs = lib.mkOption {
      description = "All backup jobs";

      type = lib.types.attrsOf (
        lib.types.submodule (
          {name, ...}: {
            options = {
              database = lib.mkOption {
                description = "Database name to backup.";
                type = lib.types.nullOr lib.types.str;
                default = null;
              };

              paths = lib.mkOption {
                description = "Paths to backup.";
                type = lib.types.listOf lib.types.path;
                default = [];
              };
            };
          }
        )
      );

      default = {
        database = null;
        paths = [];
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services = {
      postgresqlBackup = let
        databasesToBackup =
          lib.filter (database: database != null)
          (lib.map (job: job.database) (lib.attrValues cfg.jobs));
      in {
        enable = databasesToBackup != [];

        databases = databasesToBackup;
        location = "/mnt/data/AppData/Postgresql/backups";
      };

      restic.backups = let
        jobs = let
          jobsWithPaths = lib.filterAttrs (_: job: job.paths != []) cfg.jobs;
        in
          {
            postgresql.paths = lib.mkIf (config.services.postgresqlBackup.enable) [config.services.postgresqlBackup.location];
          }
          // lib.mapAttrs (_: job: builtins.removeAttrs job ["database"]) jobsWithPaths;

        jobNames = lib.attrNames jobs;
      in
        lib.listToAttrs (lib.imap0
          (index: name: let
            job = jobs.${name};
          in {
            inherit name;

            value = {
              initialize = true;
              repository = cfg.repository;
              passwordFile = cfg.passwordFile;
              environmentFile = lib.mkIf (cfg.environmentFile != null) cfg.environmentFile;
              paths = job.paths;

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
          })
          jobNames);

      systemd.services = let
        jobs = let
          jobsWithPaths = lib.filterAttrs (_: job: job.paths != []) cfg.jobs;
        in
          {
            postgresql.paths = lib.mkIf (config.services.postgresqlBackup.enable) [config.services.postgresqlBackup.location];
          }
          // lib.mapAttrs (_: job: builtins.removeAttrs job ["database"]) jobsWithPaths;

        jobNames = lib.attrNames jobs;
      in
        lib.listToAttrs (lib.imap0
          (index: name: let
            prevJobName =
              if index > 0
              then builtins.elemAt jobNames (index - 1)
              else null;
            isLast = index == (builtins.length jobNames - 1);
          in {
            name = "restic-backups-${name}";

            value = {
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
          })
          jobNames)
        // {
          wake-backup-server = {
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
              until ssh -o ConnectTimeout=10 backup@$BACKUP_IP "echo ok" >/dev/null 2>&1; do
                sleep 60
              done

              echo "→ Backup server is online."
            '';
          };

          shutdown-backup-server = {
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
  };
}
