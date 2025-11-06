{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.resticctl;
in {
  options.services.resticctl = {
    enable = lib.mkEnableOption "Enable Restic backups";

    repository = lib.mkOption {
      description = "Restic repository (e.g., s3:https://s3.example.com/my-repo)";
      type = lib.types.str;
      default = config.homelab.restic.repository;
    };

    environmentFile = lib.mkOption {
      description = "File with RESTIC_PASSWORD and optionally S3 credentials.";
      type = lib.types.path;
      default = config.homelab.restic.environmentFile;
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
            environmentFile = cfg.environmentFile;
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

            extraOptions = afterDeps ++ serviceTuning;
          };
        })
        jobNames);
  };
}
