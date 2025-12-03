{
  config,
  pkgs,
  ...
}: let
  cfgHomelab = config.homelab;
in {
  services.pgbouncer = {
    enable = true;

    settings = {
      pgbouncer = {
        listen_addr = "/run/pgbouncer";
        auth_type = "trust";
        auth_file = "/etc/pgbouncer/userslist.txt";
      };

      databases = {
        "*" = "host=/run/postgresql port=5432";
      };
    };
  };

  environment.etc."pgbouncer/userslist.txt".text = ''
    "nextcloud" ""
  '';
}
