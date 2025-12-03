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
      # Локальные сокеты - pgbouncer
      local all all peer map=pgbouncer

      # TCP-подключения — по паролю
      host all all 127.0.0.1/32 md5
      host all all ::1/128 md5
    '';

    identMap = ''
      # Mapping        SystemUser     DatabaseUser
      # -----------------------------------------
      # pgbouncer может представляться любым из этих пользователей
      pgbouncer        pgbouncer       nextcloud
      pgbouncer        pgbouncer       immich
      pgbouncer        pgbouncer       paperless
      pgbouncer        pgbouncer       vaultwarden
      pgbouncer        pgbouncer       postgres

      # сервисы напрямую (если будут подключаться без pgbouncer)
      pgbouncer        nextcloud       nextcloud
      pgbouncer        immich          immich
      pgbouncer        paperless       paperless
      pgbouncer        vaultwarden     vaultwarden
      pgbouncer        postgres        postgres
    '';

    # ensureUsers = [
    #   {
    #     name = cfgHomelab.adminUser;

    #     ensureClauses = {
    #       superuser = true;
    #       createrole = true;
    #       createdb = true;
    #     };
    #   }
    # ];

    # initialScript = pkgs.writeText "init-postgres-user" ''
    #   ALTER USER postgres WITH ENCRYPTED PASSWORD '1234567890';
    # '';
  };
}
