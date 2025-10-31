{
  config,
  pkgs,
  ...
}: {
  systemd.tmpfiles.rules = [
    "d /data/postgresql/${config.services.postgresql.package.psqlSchema} 0755 postgres postgres - -"
  ];

  services.postgresql = {
    enable = true;

    dataDir = "/data/postgresql/${config.services.postgresql.package.psqlSchema}";
  };
}
