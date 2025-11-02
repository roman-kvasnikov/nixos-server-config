# https://nohup.no/nixos-nixos/
{
  config,
  lib,
  ...
}: let
  cfg = config.services.nginxctl;
in {
  options.services.nginxctl = {
    enable = lib.mkEnableOption "Enable Nginx";
  };

  config = lib.mkIf cfg.enable {
    services.nginx = {
      enable = true;

      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;

      virtualHosts."_" = {
        default = true;

        listen = [
          {
            addr = "0.0.0.0";
            port = 80;
            ssl = false;
          }
          {
            addr = "0.0.0.0";
            port = 443;
            ssl = true;
          }
        ];

        locations."/" = {
          return = "404";
        };
      };
    };

    users.users.nginx.extraGroups = ["acme"];

    networking.firewall.allowedTCPPorts = [80 443];
  };
}
