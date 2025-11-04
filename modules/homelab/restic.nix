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
        schedule = "04:00";
        keepDaily = "7";
        keepWeekly = "4";
        keepMonthly = "6";
      };
    };

    serialize = lib.mkOption {
      type = lib.types.bool;
      description = ''
        If true, ensures that restic backup jobs run sequentially (not in parallel)
        by adding After= dependencies between them.
        This prevents repository lock conflicts when using a shared repo.
      '';
      default = true;
    };

    jobs = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule ({name, ...}: {
        options = {
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

          database = lib.mkOption {
            type = lib.types.str;
            description = "Database name to backup.";
            default = null;
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
    services.postgresqlBackup = let
      databasesToBackup = lib.filter (database: database != null) (lib.map (job: job.database) (lib.attrValues cfg.jobs));
    in {
      enable = true;

      databases = databasesToBackup;
      location = "/var/lib/postgresql/backups";
    };

    homelab.services.resticctl = {
      jobs.postgresql = {
        paths = ["/var/lib/postgresql/backups"];
      };
    };

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

            extraOptions = afterDeps ++ serviceTuning;
          };
        })
        jobNames);
  };

  # config = lib.mkIf cfg.enable {
  #   services.restic.backups =
  #     lib.mapAttrs
  #     (name: job:
  #       lib.mkIf job.enable {
  #         initialize = true;
  #         repository = job.repository;
  #         environmentFile = job.environmentFile;
  #         paths = job.paths;
  #         timerConfig = {
  #           OnCalendar = job.schedule;
  #           Persistent = true;
  #         };
  #         pruneOpts = [
  #           "--keep-daily ${job.prune.daily}"
  #           "--keep-weekly ${job.prune.weekly}"
  #           "--keep-monthly ${job.prune.monthly}"
  #         ];
  #       })
  #     cfg.jobs;
  # };
}
