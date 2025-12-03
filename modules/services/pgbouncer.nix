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
        unix_socket_dir = "/run/pgbouncer";
        listen_addr = "/run/pgbouncer";
        listen_port = 6432;

        admin_users = "postgres";

        auth_type = "trust";
        auth_file = "/etc/pgbouncer/userslist.txt";

        pool_mode = "transaction";
        max_client_conn = 200;
        default_pool_size = 20;
      };
    };
  };

  environment.etc."pgbouncer/userslist.txt".text = ''
    "postgres" ""
  '';
}
