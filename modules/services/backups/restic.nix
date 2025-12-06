{
  config,
  lib,
  pkgs,
  hostname,
  ...
}: let
  cfg = config.services.resticctl;
  cfgBackupCtl = config.services.backupctl;
in {
  options.services.resticctl = {
    enable = lib.mkEnableOption "Enable Restic backups";

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
        in {
          inherit name;

          value = {
            initialize = true;
            repository = cfgBackupCtl.repository;
            passwordFile = cfgBackupCtl.passwordFile;
            environmentFile = lib.mkIf (cfgBackupCtl.environmentFile != null) cfgBackupCtl.environmentFile;
            paths = job.paths;

            extraBackupArgs = ["--tag ${name}"];

            timerConfig = {
              OnCalendar = cfgBackupCtl.schedule;
              Persistent = true;
            };

            pruneOpts = [
              "--keep-daily ${cfgBackupCtl.prune.keepDaily}"
              "--keep-weekly ${cfgBackupCtl.prune.keepWeekly}"
              "--keep-monthly ${cfgBackupCtl.prune.keepMonthly}"
            ];
          };
        })
        jobNames);

    systemd.services = let
      jobNames = lib.attrNames cfg.jobs;
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
}
