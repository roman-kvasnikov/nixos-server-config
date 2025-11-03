{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.nextcloudResticBackup;
in {
  options.services.nextcloudResticBackup = {
    enable = lib.mkEnableOption "Enable automatic Nextcloud backups via Restic";

    backupDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/backup/nextcloud";
      description = "Directory to store temporary Nextcloud backups before uploading to Restic.";
    };

    resticRepository = lib.mkOption {
      type = lib.types.str;
      description = "Restic repository URL (e.g. s3:https://s3.example.com/nextcloud-backups)";
    };

    passwordFile = lib.mkOption {
      type = lib.types.path;
      description = "Path to the Restic password file.";
    };

    environmentFile = lib.mkOption {
      type = lib.types.path;
      description = "Path to file containing S3 credentials (AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY).";
    };

    pgDatabase = lib.mkOption {
      type = lib.types.str;
      default = "nextcloud";
      description = "PostgreSQL database name for Nextcloud.";
    };

    retention = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = ["--keep-daily 7" "--keep-weekly 4" "--keep-monthly 6"];
      description = "Restic prune options for retention policy.";
    };

    schedule = lib.mkOption {
      type = lib.types.str;
      default = "daily";
      description = "Systemd OnCalendar expression (e.g. daily, hourly, 03:00).";
    };
  };

  config = lib.mkIf cfg.enable {
    # === Сервис: подготовка бэкапа Nextcloud ===
    systemd.services.prepare-nextcloud-backup = {
      description = "Prepare Nextcloud data and database dump for Restic backup";
      serviceConfig = {
        Type = "oneshot";
        User = "root";
        ExecStart = pkgs.writeShellScript "prepare-nextcloud-backup" ''
          set -euo pipefail
          BACKUP_DIR=${cfg.backupDir}
          DATE=$(date +"%Y-%m-%d_%H-%M-%S")
          mkdir -p "$BACKUP_DIR"

          echo "[Nextcloud Backup] Stopping Nextcloud services..."
          systemctl stop nextcloud-phpfpm.service nginx.service

          echo "[Nextcloud Backup] Dumping PostgreSQL database..."
          sudo -u postgres pg_dump ${cfg.pgDatabase} > "$BACKUP_DIR/db-$DATE.sql"

          echo "[Nextcloud Backup] Archiving data directory..."
          tar -czf "$BACKUP_DIR/files-$DATE.tar.gz" /var/lib/nextcloud/data /var/lib/nextcloud/config

          echo "[Nextcloud Backup] Restarting services..."
          systemctl start nginx.service nextcloud-phpfpm.service

          # Clean up local backups older than 3 days
          find "$BACKUP_DIR" -type f -mtime +3 -delete
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

    # === Restic backup service ===
    services.restic.backups.nextcloud = {
      repository = cfg.resticRepository;
      passwordFile = cfg.passwordFile;
      environmentFile = cfg.environmentFile;
      paths = [cfg.backupDir];
      pruneOpts = cfg.retention;
      timerConfig = {
        OnCalendar = cfg.schedule;
        Persistent = true;
      };
      extraBackupArgs = ["--verbose"];
    };
  };
}
