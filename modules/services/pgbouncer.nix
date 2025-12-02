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
        pool_mode = "session";
        auth_type = "trust";
      };
    };
  };
}
