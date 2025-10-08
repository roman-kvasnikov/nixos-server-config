{config, ...}: let
  cfgServer = config.server;
in {
  services.openssh = {
    enable = true;

    openFirewall = true;

    settings = {
      AllowUsers = [cfgServer.adminUser];
      # PasswordAuthentication = false;
      # PermitRootLogin = "no";
      # X11Forwarding = false;
    };
  };
}
