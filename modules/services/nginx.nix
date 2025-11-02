# https://nohup.no/nixos-nixos/
{
  config,
  lib,
  ...
}: let
  cfg = config.services.nginxctl;
  cfgAcme = config.services.acmectl;
in {
  options.services.nginxctl = {
    enable = lib.mkEnableOption "Enable Nginx";
  };

  config = lib.mkIf cfg.enable {
    # security.acme.certs."default.kvasok.xyz" = lib.mkIf (cfg.enable && cfgAcme.enable) cfgAcme.commonCertOptions;

    services.nginx = {
      enable = true;

      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;

      # virtualHosts."default.kvasok.xyz" = {
      # default = true;

      # enableACME = cfgAcme.enable;

      # listen = [
      #   {
      #     addr = "0.0.0.0";
      #     port = 80;
      #     ssl = false;
      #   }
      #   {
      #     addr = "0.0.0.0";
      #     port = 443;
      #     ssl = true;
      #   }
      # ];

      # locations."/" = {
      #   return = "404";
      # };
      # };
    };

    users.users.nginx.extraGroups = ["acme"];

    networking.firewall.allowedTCPPorts = [80 443];
  };
}
