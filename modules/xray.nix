{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.xrayctl;
in {
  options.services.xrayctl = {
    enable = lib.mkEnableOption {
      description = "Enable Xray";
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      xray
    ];

    services.xray = {
      enable = true;

      settingsFile = "/etc/xray/config.json";
    };
  };
}
