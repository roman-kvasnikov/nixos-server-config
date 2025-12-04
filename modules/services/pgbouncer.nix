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

        admin_users = "postgres";

        auth_type = "md5";
        auth_file = "/etc/pgbouncer/userslist.txt";

        pool_mode = "transaction";
        max_client_conn = 500;
        default_pool_size = 20;
      };
    };
  };

  environment.etc."pgbouncer/userslist.txt".text = ''
    "postgres" "md53175bce1d3201d16594cebf9d7eb3f9d"
    "pgbounce" "md50933e178e4d78061b63ad05a469c62c3"
  '';
}
