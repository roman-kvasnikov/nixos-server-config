{
  config,
  pkgs,
  ...
}: let
  cfgHomelab = config.homelab;
in {
  systemd.tmpfiles.rules = [
    "d ${config.services.postgresql.dataDir} 700 postgres postgres - -"
  ];

  services.postgresql = {
    enable = true;

    dataDir = "/mnt/data/AppData/Postgresql/${config.services.postgresql.package.psqlSchema}";

    authentication = ''
      # локальные сокеты — peer (по системному пользователю)
      local all all peer

      # TCP-подключения — по паролю
      host all all 127.0.0.1/32 md5
      host all all ::1/128 md5
    '';

    ensureUsers = [
      {
        name = cfgHomelab.adminUser;

        ensureClauses = {
          superuser = true;
          createrole = true;
          createdb = true;
        };
      }
    ];

    initialScript = pkgs.writeText "init-postgres-user" ''
      ALTER USER romank WITH ENCRYPTED PASSWORD '123';
    '';
  };
}
