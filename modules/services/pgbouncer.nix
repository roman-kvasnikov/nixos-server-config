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
        listen_addr = "127.0.0.1";
        listen_port = 6432;

        unix_socket_dir = "/run/pgbouncer";

        admin_users = "postgres";

        auth_type = "md5";
        auth_file = "/etc/pgbouncer/userslist.txt";

        max_client_conn = 500;
        # pool_mode = "transaction";
        # default_pool_size = 20;
      };

      databases = {
        "*" = "host=/run/postgresql port=5432";
        immich = "host=/run/postgresql port=5432 dbname=immich auth_user=immich";
      };
    };
  };

  environment.etc."pgbouncer/userslist.txt".text = ''
    "postgres" "postgres"
    "immich" "immich"
  '';
}
