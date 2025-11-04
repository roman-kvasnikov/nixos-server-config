{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.homelab.services.resticctl;
in {
  options.homelab.services.resticctl = {
    enable = lib.mkEnableOption "Enable global Restic backup system";

    defaults = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      description = "Default restic backup settings (prune schedule, etc.)";
      default = {
        schedule = "daily";
        keepDaily = "7";
        keepWeekly = "4";
        keepMonthly = "6";
      };
    };

    jobs = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule ({name, ...}: {
        options = {
          enable = lib.mkEnableOption "Enable Restic backup job";

          repository = lib.mkOption {
            type = lib.types.str;
            description = "Restic repository (e.g., s3:https://s3.example.com/my-repo)";
            default = "${config.homelab.restic.repository}/${name}";
          };

          environmentFile = lib.mkOption {
            type = lib.types.path;
            description = "File with RESTIC_PASSWORD and optionally S3 credentials.";
            default = config.homelab.restic.environmentFile;
          };

          paths = lib.mkOption {
            type = lib.types.listOf lib.types.path;
            description = "Paths to backup.";
          };

          schedule = lib.mkOption {
            type = lib.types.str;
            description = "Systemd OnCalendar schedule (e.g., daily, weekly, hourly)";
            default = cfg.defaults.schedule;
          };

          prune = lib.mkOption {
            type = lib.types.attrsOf lib.types.str;
            description = "Retention policy for restic prune.";
            default = {
              daily = cfg.defaults.keepDaily;
              weekly = cfg.defaults.keepWeekly;
              monthly = cfg.defaults.keepMonthly;
            };
          };
        };
      }));
      description = "All Restic backup jobs";
      default = {};
    };
  };

  config = lib.mkIf cfg.enable {
    services.restic.backups =
      lib.mapAttrs
      (name: job:
        lib.mkIf job.enable {
          initialize = true;
          repository = job.repository;
          environmentFile = job.environmentFile;
          paths = job.paths;
          timerConfig = {
            OnCalendar = job.schedule;
            Persistent = true;
          };
          pruneOpts = [
            "--keep-daily ${job.prune.daily}"
            "--keep-weekly ${job.prune.weekly}"
            "--keep-monthly ${job.prune.monthly}"
          ];
        })
      cfg.jobs;
  };
}
