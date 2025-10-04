{
  config,
  lib,
  ...
}: let
  cfg = config.services.nginxctl;
in {
  options.services.nginxctl = {
    enable = lib.mkEnableOption {
      description = "Enable Nginx";
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    services.nginx = {
      enable = true;

      recommendedProxySettings = true;
      recommendedTlsSettings = true;

      virtualHosts."${config.server.domain}" = {
        enableACME = config.services.acmectl.enable;
        forceSSL = config.services.acmectl.enable;
      };
    };
  };
}
# https://nohup.no/nixos-nixos/

