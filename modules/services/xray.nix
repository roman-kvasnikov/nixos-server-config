{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.xrayctl;
in {
  options.services.xrayctl = {
    enable = lib.mkEnableOption "Enable Xray";
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      environment.systemPackages = with pkgs; [
        xray
      ];

      services.xray = {
        enable = true;

        settingsFile = config.age.secrets.xray-config-json.path;
      };

      networking = {
        proxy = {
          default = "socks5://127.0.0.1:10808";
          noProxy = "localhost,127.0.0.1,192.168.0.0/16,10.0.0.0/8,172.16.0.0/12";
        };
      };
    })

    (lib.mkIf (cfg.enable && config.homelab.services.jellyfinctl.enable) {
      systemd.services = {
        jellyfin.environment = {
          HTTP_PROXY = "socks5://127.0.0.1:10808";
          HTTPS_PROXY = "socks5://127.0.0.1:10808";
          NO_PROXY = "localhost,127.0.0.1,192.168.0.0/16,10.0.0.0/8,172.16.0.0/12";
        };
      };
    })
  ];
}
