{
  config,
  lib,
  ...
}: let
  cfgHomelab = config.homelab;
in {
  imports = [
    ../../modules/homelab
    ../../modules/programs
    ../../modules/services
  ];

  networking.interfaces.${cfgHomelab.interface} = {
    useDHCP = true;

    wakeOnLan = {
      enable = true;
      policy = "magic";
    };
  };
}
