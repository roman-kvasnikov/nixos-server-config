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
        listen_port = 0;
        # pool_mode = "session";
        # auth_type = "peer";
      };
    };
  };
}
