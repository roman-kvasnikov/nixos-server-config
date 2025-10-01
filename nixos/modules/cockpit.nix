{
  services.cockpit = {
    enable = true;

    port = 9090;

    openFirewall = true;

    settings = {
      WebService = {
        AllowUnencrypted = true;
        ProtocolHeader = "X-Forwarded-Proto";
      };
    };
  };

  # networking.firewall.allowedTCPPorts = [9090];
}
