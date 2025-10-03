{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.immichctl;
in {
  options.services.immichctl = {
    enable = lib.mkEnableOption {
      description = "Enable Immich";
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      immich
    ];

    services.immich = {
      enable = true;

      host = "0.0.0.0";
      port = 2283;

      openFirewall = true;
    };
  };
}
