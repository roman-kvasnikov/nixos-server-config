{config, ...}: let
  cfgHomelab = config.homelab;
  cfgAcme = config.services.acmectl;
  cfgNginx = config.services.nginxctl;

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
    inherit system cfgHomelab cfgAcme cfgNginx denyExternal;
  };
}
