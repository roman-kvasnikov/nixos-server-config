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
          ips = ["10.100.0.2/24"];
          listenPort = 51820;
          # privateKeyFile = "/root/wireguard-keys/private";
          privateKey = "yAnz5TF+lXXJte14tji3zlMNq+hd2rYUIgJBgB3fBmk=";

          peers = [
            {
              allowedIPs = ["10.100.0.1/32"];
              # endpoint = "demo.wireguard.io:12913";
              publicKey = "xTIBA5rboUvnH4htodjb6e697QjLERt1NAB4mZqp8Dg=";
              persistentKeepalive = 25;
            }
          ];
        };
      };
    };
  };

  services.fail2ban.enable = true;
}
