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
        auth_type = "md5";
        auth_file = "/etc/pgbouncer/userslist.txt";
      };
    };
  };

  environment.etc."pgbouncer/userslist.txt".text = ''
    "nextcloud" "password"
  '';
}
