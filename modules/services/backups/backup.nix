{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.backupctl;
in {
  options.services.backupctl = {
    enable = lib.mkEnableOption "Enable global Backup system";

    jobs = lib.mkOption {
      description = "All backup jobs";

      type = lib.types.attrsOf (lib.types.submodule ({name, ...}: {
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
      }));

      default = {};
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

      resticctl = {
        enable = true;

        jobs = let
          jobsWithPaths = lib.filterAttrs (_: job: job.paths != []) cfg.jobs;
        in
          {
            postgresql.paths = ["/mnt/data/AppData/Postgresql/backups"];
            secrets.paths = ["/mnt/data/Secrets"];
          }
          // lib.mapAttrs (_: job: builtins.removeAttrs job ["database"]) jobsWithPaths;
      };
    };
  };
}
