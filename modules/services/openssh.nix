{config, ...}: let
  cfgHomelab = config.homelab;
in {
  services.openssh = {
    enable = true;

    openFirewall = true;

    settings = {
      AllowUsers = [cfgHomelab.adminUser];
      # PasswordAuthentication = false;
      # PermitRootLogin = "no";
      # X11Forwarding = false;
    };
  };
}
