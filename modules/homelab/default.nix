{
  config,
  lib,
  ...
}: let
  cfgHomelab = config.homelab;

  denyExternal = ''
    allow ${cfgHomelab.subnet}; # Разрешаем локальный трафик
    allow ${cfgHomelab.vpnSubnet}; # Разрешаем VPN трафик
    deny all;
  '';
in {
  imports = [
    ./homepage.nix
    ./samba.nix
    ./clouds
    ./media
    ./monitoring
    ./services
  ];

  _module.args = {
    inherit denyExternal;
  };
}
