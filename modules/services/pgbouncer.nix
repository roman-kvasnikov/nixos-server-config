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
        auth_type = "hba";
        auth_file = "/etc/pgbouncer/userlist.txt";
        auth_hba_file = "/etc/pgbouncer/pg_hba.conf";
      };
    };
  };

  environment.etc."pgbouncer/userlist.txt".text = ''
    "nextcloud" ""
  '';

  environment.etc."pgbouncer/pg_hba.conf".text = ''
    local all all peer
  '';
}
