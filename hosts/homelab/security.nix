{lib, ...}: {
  security = {
    sudo = {
      enable = true;

      wheelNeedsPassword = false; # true - требует пароль для выполнения sudo.
      execWheelOnly = true; # true - позволяет только пользователям из группы wheel выполнять sudo.
    };

    polkit.enable = true;
  };

  networking.firewall = {
    enable = true;

    allowPing = false; # запрещаем ICMP-пинги (опционально)
    allowedTCPPorts = lib.mkDefault []; # разрешённых TCP портов нет
    allowedUDPPorts = lib.mkDefault []; # разрешённых UDP портов нет

    logRefusedConnections = true;
  };

  services.fail2ban.enable = true;
}
