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

  services.ethtool.enable = true;

  networking.interfaces.${cfgHomelab.interface} = {
    useDHCP = true;
    ethtoolOptions = {
      wol = "g";
    };
  };
}
