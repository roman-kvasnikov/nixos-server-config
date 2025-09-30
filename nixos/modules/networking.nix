{hostname, ...}: {
  networking = {
    hostName = hostname;

    networkmanager = {
      enable = true;
    };

    firewall = {
      enable = true;

      allowPing = false;
      logRefusedConnections = true;
    };
  };
}
