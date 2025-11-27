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
      description = "Interface name for the WireGuard VPN Connection";
      type = lib.types.str;
      default = "wg0";
    };

    privateKey = lib.mkOption {
      description = "Private key for the WireGuard VPN Connection";
      type = lib.types.str;
      default = "qOAgXb4UMZQja0U9mawZmWMDYALiY83q+pxrlnswFVk=";
    };

    publicKey = lib.mkOption {
      description = "Public key for the WireGuard VPN Connection";
      type = lib.types.str;
      default = "tEeF3aLdO7Oka3didAHSFXdDfSVY1PsqpRW/c++sbVI=";
    };

    ips = lib.mkOption {
      description = "IPs for the WireGuard VPN Connection";
      type = lib.types.listOf lib.types.str;
      default = ["10.0.0.2/24"];
    };

    endpoint = lib.mkOption {
      description = "Endpoint for the WireGuard VPN Connection";
      type = lib.types.str;
      default = "77.232.136.6:51820";
    };

    allowedIPs = lib.mkOption {
      description = "Allowed IPs for the WireGuard VPN Connection";
      type = lib.types.listOf lib.types.str;
      default = ["10.0.0.1/32"];
    };

    persistentKeepalive = lib.mkOption {
      description = "Persistent keepalive for the WireGuard VPN Connection";
      type = lib.types.int;
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
