{
  services = {
    immich = {
      enable = true;

      port = 2283;
    };
  };

  networking.firewall.allowedTCPPorts = [2283]; # Web UI
}
