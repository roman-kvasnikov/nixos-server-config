{
  config,
  hostname,
  ...
}: let
  cfgHomelab = config.homelab;
in {
  networking = {
    hostName = hostname;
    #useDHCP = true;

    # useResolved = false;
    nameservers = cfgHomelab.nameservers;

    networkmanager = {
      enable = true;
    };
  };
}
