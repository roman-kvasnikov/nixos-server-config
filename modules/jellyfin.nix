{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.jellyfinctl;
in {
  options.services.jellyfinctl = {
    enable = lib.mkEnableOption {
      description = "Enable Jellyfin";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      jellyfin
      jellyfin-web
      jellyfin-ffmpeg
    ];

    services.jellyfin = {
      enable = true;

      openFirewall = true;
    };
  };
}
