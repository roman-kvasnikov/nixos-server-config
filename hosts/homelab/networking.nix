{hostname, ...}: {
  networking = {
    hostName = hostname;
    #useDHCP = true;

    networkmanager = {
      enable = true;
    };
  };
}
