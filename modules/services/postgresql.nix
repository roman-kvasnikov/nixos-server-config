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
      # postgres может подключаться через peer (без пароля)
      local all postgres peer
      local all linkwarden peer
      local all paperless peer
      local all vaulwarden peer

      # Остальные через пароль
      local all all trust
    '';
  };
}
