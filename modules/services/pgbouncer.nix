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

        auth_type = "trust";
        auth_file = "/etc/pgbouncer/userslist.txt";

        pool_mode = "transaction";
        max_client_conn = 5000;
        default_pool_size = 20;
        reserve_pool_size = 5;
      };

      databases = {
        "*" = "host=/run/postgresql port=5432";
      };
    };
  };

  environment.etc."pgbouncer/userslist.txt".text = ''
    "postgres" ""
  '';
}
