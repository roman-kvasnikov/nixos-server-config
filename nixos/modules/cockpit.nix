{
  services.cockpit = {
    enable = true;

    port = 9090;

    openFirewall = true;

    settings = {
      WebService = {
        AllowUnencrypted = true;
      };
    };
  };

  # networking.firewall.allowedTCPPorts = [9090];
}
