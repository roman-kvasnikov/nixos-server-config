{
  config,
  lib,
  ...
}: let
  cfgHomelab = config.homelab;
in {
  security = {
    sudo = {
      enable = true;

      wheelNeedsPassword = false; # true - требует пароль для выполнения sudo.
      execWheelOnly = true; # true - позволяет только пользователям из группы wheel выполнять sudo.
    };

    polkit.enable = true;
  };

  networking = {
    firewall = {
      enable = true;

      allowPing = true; # запрещаем ICMP-пинги (опционально)
      allowedTCPPorts = lib.mkDefault []; # разрешённых TCP портов нет
      allowedUDPPorts = lib.mkDefault []; # разрешённых UDP портов нет

      logRefusedConnections = true;
    };
  };

  services = {
    openssh = {
      enable = true;

      openFirewall = true;

      settings = {
        AllowUsers = [cfgHomelab.adminUser];
        # PasswordAuthentication = false;
        # PermitRootLogin = "no";
        # X11Forwarding = false;
      };
    };

    fail2ban.enable = true;
  };
}
