{
  services.cockpit = {
    enable = true;

    port = 9090;

    settings = {
      WebService = {
        AllowUnencrypted = true;
      };
    };
  };

  networking.firewall.allowedTCPPorts = [9090];
}
