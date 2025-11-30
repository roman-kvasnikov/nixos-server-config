{
  config,
  hostname,
  ...
}: let
  cfgHomelab = config.homelab;
in {
  networking = {
    hostName = hostname;

    networkmanager = {
      enable = true;

      dns = "none";
    };

    # nameservers = cfgHomelab.nameservers;
  };
}
