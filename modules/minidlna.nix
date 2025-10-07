{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.minidlnactl;
in {
  options.services.minidlnactl = {
    enable = lib.mkEnableOption "Enable Minidlna";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      minidlna
    ];

    services.minidlna = {
      enable = true;

      openFirewall = true;

      settings = {
        media_dir = [
          "P,/home/DLNA/Pictures/"
          "V,/home/DLNA/Videos/"
        ];

        inotify = "yes";
      };
    };
  };
}
