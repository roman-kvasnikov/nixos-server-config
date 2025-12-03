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
      pgbouncer pgbouncer postgres
      pgbouncer postgres  postgres
    '';

    # identMap = ''
    #   # Mapping        SystemUser     DatabaseUser
    #   # -----------------------------------------
    #   # pgbouncer может представляться любым из этих пользователей
    #   pgbouncer        pgbouncer       postgres
    #   pgbouncer        pgbouncer       immich
    #   pgbouncer        pgbouncer       linkwarden
    #   pgbouncer        pgbouncer       nextcloud
    #   pgbouncer        pgbouncer       paperless
    #   pgbouncer        pgbouncer       vaultwarden

    #   # сервисы напрямую (если будут подключаться без pgbouncer)
    #   pgbouncer        postgres        postgres
    #   pgbouncer        immich          immich
    #   pgbouncer        linkwarden      linkwarden
    #   pgbouncer        nextcloud       nextcloud
    #   pgbouncer        paperless       paperless
    #   pgbouncer        vaultwarden     vaultwarden
    # '';
  };
}
