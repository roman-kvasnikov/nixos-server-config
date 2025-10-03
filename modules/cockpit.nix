{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.cockpitctl;
in {
  options.services.cockpitctl = {
    enable = lib.mkEnableOption {
      description = "Enable Cockpit";
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
  };
}
