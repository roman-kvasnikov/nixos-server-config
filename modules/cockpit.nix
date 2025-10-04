{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.cockpitctl;
  cfgNginx = config.services.nginxctl;
in {
  options.services.cockpitctl = {
    enable = lib.mkEnableOption {
      description = "Enable Cockpit";
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      cockpit
    ];

    services.cockpit = {
      enable = true;

      port = 9090;

      openFirewall = true;

      settings = {
        WebService = {
          AllowUnencrypted = true;
          ProtocolHeader = "X-Forwarded-Proto";
        };
      };
    };

    # services.nginx.virtualHosts = lib.mkIf cfgNginx.enable {
    #   "${config.server.domain}" = {
    #     proxyPass = "http://127.0.0.1:9090";
    #   };
    # };
  };
}
