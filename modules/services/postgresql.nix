{config, ...}: let
  cfgHomelab = config.homelab;
in {
  services.postgresql = {
    enable = true;

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
  };
}
