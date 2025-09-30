{
  services = {
    samba = {
      enable = true;
    };
  };

  networking.firewall.allowedTCPPorts = [135 139 445];
  networking.firewall.allowedUDPPorts = [137 138];
}
