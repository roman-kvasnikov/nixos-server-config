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
        listen_port = 6432;
        auth_type = "trust";
        auth_file = "/etc/pgbouncer/userslist.txt";
        admin_users = "postgres";
      };
    };
  };

  environment.etc."pgbouncer/userslist.txt".text = ''
    "nextcloud" ""
    "immich" ""
    "linkwarden" ""
    "paperless" ""
    "vaultwarden" ""
    "postgres" ""
  '';
}
