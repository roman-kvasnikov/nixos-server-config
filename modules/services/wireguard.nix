{
  config,
  lib,
  ...
}: let
  cfg = config.services.wireguardctl;
in {
  options.services.wireguardctl = {
    enable = lib.mkEnableOption "Enable WireGuard VPN Connection";

    interface = lib.mkOption {
      type = lib.types.str;
      description = "Interface name for the WireGuard VPN Connection";
      default = "wg0";
    };

    privateKey = lib.mkOption {
      type = lib.types.str;
      description = "Private key for the WireGuard VPN Connection";
      default = "qOAgXb4UMZQja0U9mawZmWMDYALiY83q+pxrlnswFVk=";
    };

    publicKey = lib.mkOption {
      type = lib.types.str;
      description = "Public key for the WireGuard VPN Connection";
      default = "tEeF3aLdO7Oka3didAHSFXdDfSVY1PsqpRW/c++sbVI=";
    };

    ips = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "IPs for the WireGuard VPN Connection";
      default = ["10.0.0.2/24"];
    };

    endpoint = lib.mkOption {
      type = lib.types.str;
      description = "Endpoint for the WireGuard VPN Connection";
      default = "77.232.136.6:51820";
    };

    allowedIPs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "Allowed IPs for the WireGuard VPN Connection";
      default = ["10.0.0.1/32"];
    };

    persistentKeepalive = lib.mkOption {
      type = lib.types.int;
      description = "Persistent keepalive for the WireGuard VPN Connection";
      default = 25;
    };
  };

  config = lib.mkIf cfg.enable {
    networking = {
      wireguard = {
        interfaces = {
          ${cfg.interface} = {
            ips = cfg.ips;
            privateKey = cfg.privateKey;

            peers = [
              {
                endpoint = cfg.endpoint;
                allowedIPs = cfg.allowedIPs;
                publicKey = cfg.publicKey;
                persistentKeepalive = cfg.persistentKeepalive;
              }
            ];
          };
        };
      };
    };
  };
}
