{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.homelab.services.nextcloud-backup-ctl;
  cfgHomelab = config.homelab;
in {
  options.homelab.services.nextcloud-backup-ctl = {
    enable = lib.mkEnableOption "Enable automatic Nextcloud backups";

    resticRepository = lib.mkOption {
      type = lib.types.str;
      description = "Restic repository URL (e.g. s3:https://s3.example.com/nextcloud-backups)";
      default = "s3:${config.homelab.s3Backups.s3-url}/${config.homelab.s3Backups.s3-bucket}/${config.homelab.s3Backups.s3-dir}/nextcloud";
    };

    resticPasswordFile = lib.mkOption {
      type = lib.types.path;
      description = "Path to the Restic password file.";
      default = config.age.secrets.restic-password.path;
    };

    resticEnvironmentFile = lib.mkOption {
      type = lib.types.path;
      description = "Path to file containing S3 credentials (AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY / AWS_REGION).";
      default = config.homelab.s3Backups.s3-env-file;
    };

    resticPruneOpts = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "Restic prune options for retention policy.";
      default = ["--keep-daily 7" "--keep-weekly 4" "--keep-monthly 6"];
    };

    backupDir = lib.mkOption {
      type = lib.types.path;
      description = "Directory to store temporary Nextcloud backups before uploading to Restic.";
      default = "/var/backup/nextcloud";
    };

    pgsqlDbName = lib.mkOption {
      type = lib.types.str;
      description = "PostgreSQL database name for Nextcloud.";
      default = "nextcloud";
    };

    schedule = lib.mkOption {
      type = lib.types.str;
      description = "Systemd OnCalendar expression (e.g. daily, hourly, 03:00).";
      default = "daily";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.prepare-nextcloud-backup = {
      description = "Prepare and create cold Nextcloud backup for Restic";
      serviceConfig = {
        Type = "oneshot";
        User = "root";
        ExecStart = pkgs.writeShellScript "prepare-nextcloud-backup" ''
          #!${pkgs.bash}/bin/bash
          export PATH=${pkgs.gzip}/bin:${pkgs.gnutar}/bin:${pkgs.util-linux}/bin:$PATH

          set -euo pipefail

          echo "[Nextcloud Backup] Starting..."

          BACKUP_DIR=${cfg.backupDir}
          DATE=$(date +"%Y-%m-%d_%H-%M-%S")
          mkdir -p "$BACKUP_DIR"

          echo "[Nextcloud Backup] Stopping Nextcloud services..."
          systemctl stop phpfpm-nextcloud.service nginx.service redis-nextcloud.service || true

          echo "[Nextcloud Backup] Dumping PostgreSQL..."
          runuser -u postgres -- ${config.services.postgresql.package}/bin/pg_dump \
            --username postgres \
            --no-owner \
            --clean \
            ${cfg.pgsqlDbName} | gzip > "$BACKUP_DIR/db-$DATE.sql.gz"

          echo "[Nextcloud Backup] Archiving data..."
          tar -czf "$BACKUP_DIR/files-$DATE.tar.gz" ${config.services.nextcloud.home}/data ${config.services.nextcloud.home}/config

          echo "[Nextcloud Backup] Starting Nextcloud services..."
          systemctl start nginx.service phpfpm-nextcloud.service redis-nextcloud.service || true

          echo "[Nextcloud Backup] Cleaning up old local backups..."
          find "$BACKUP_DIR" -type f -mtime +3 -delete

          echo "[Nextcloud Backup] Done!"
        '';
      };
    };

    systemd.timers.prepare-nextcloud-backup = {
      description = "Daily Nextcloud data preparation for Restic";
      wantedBy = ["timers.target"];
      timerConfig = {
        OnCalendar = cfg.schedule;
        Persistent = true;
      };
    };

    services.restic.backups.nextcloud = {
      repository = cfg.resticRepository;
      passwordFile = cfg.resticPasswordFile;
      environmentFile = cfg.resticEnvironmentFile;
      pruneOpts = cfg.resticPruneOpts;
      paths = [cfg.backupDir];
      timerConfig = {
        OnCalendar = cfg.schedule;
        Persistent = true;
      };
      extraBackupArgs = ["--verbose"];
    };
  };
}
