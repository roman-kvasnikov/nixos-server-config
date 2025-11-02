{lib, ...}: {
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

      allowPing = false; # запрещаем ICMP-пинги (опционально)
      allowedTCPPorts = lib.mkDefault []; # разрешённых TCP портов нет
      allowedUDPPorts = lib.mkDefault [51820]; # Разрешен один UDP порт для WireGuard

      logRefusedConnections = true;
    };

    wireguard = {
      interfaces = {
        wg0 = {
          ips = ["10.0.0.2/24"];
          listenPort = 51820;
          privateKey = "qOAgXb4UMZQja0U9mawZmWMDYALiY83q+pxrlnswFVk=";

          peers = [
            {
              allowedIPs = ["10.0.0.1/32"];
              publicKey = "tEeF3aLdO7Oka3didAHSFXdDfSVY1PsqpRW/c++sbVI=";
              persistentKeepalive = 25;
            }
          ];
        };
      };
    };
  };

  services.fail2ban.enable = true;
}
