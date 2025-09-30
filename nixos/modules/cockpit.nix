{
  services.cockpit.enable = true;
  networking.firewall.allowedTCPPorts = [9090]; # Web UI
}
