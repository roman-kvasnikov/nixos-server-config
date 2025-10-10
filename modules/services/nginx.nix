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
    };

    users.users.nginx.extraGroups = ["acme"];

    networking.firewall.allowedTCPPorts = [80 443];
  };
}
