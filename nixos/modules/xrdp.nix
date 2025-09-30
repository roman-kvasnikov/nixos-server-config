{
  services = {
    xrdp.enable = true;
    xrdp.defaultWindowManager = "startxfce4";
  };

  networking.firewall.allowedTCPPorts = [3389]; # порт RDP
}
