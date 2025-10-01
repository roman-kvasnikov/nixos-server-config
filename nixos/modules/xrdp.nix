{
  services.xrdp = {
    enable = true;

    defaultWindowManager = "startxfce4";
  };

  networking.firewall.allowedTCPPorts = [3389];
}
