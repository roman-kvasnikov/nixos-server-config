{config, ...}: let
  dataDir = "/data/postgresql/${config.services.postgresql.package.psqlSchema}";
in {
  systemd.tmpfiles.rules = [
    "d ${dataDir} 0755 postgres postgres - -"
  ];

  services.postgresql = {
    enable = true;

    dataDir = dataDir;
  };
}
