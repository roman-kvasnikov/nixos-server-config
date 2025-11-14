{
  config,
  hostname,
  ...
}: let
  cfgHomelab = config.homelab;
in {
  networking = {
    hostId = "8425e349";
    hostName = hostname;

    networkmanager = {
      enable = true;

      dns = "none";
    };

    nameservers = cfgHomelab.nameservers;
  };
}
