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
        listen_addr = "*";
        listen_port = 6432;

        unix_socket_dir = "/run/postgresql";

        admin_users = "postgres";

        auth_type = "trust";
        auth_file = "/etc/pgbouncer/userslist.txt";

        max_client_conn = 500;
        # pool_mode = "transaction";
        # default_pool_size = 20;
      };
    };
  };

  environment.etc."pgbouncer/userslist.txt".text = ''
    "postgres" "postgres"
  '';
}
