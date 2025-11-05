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

    configFile = lib.mkOption {
      type = lib.types.path;
      description = "Path to the Xray config file";
      default = "/etc/xray/config.json";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      environment.systemPackages = with pkgs; [
        xray
      ];

      environment.etc = {
        "${builtins.replaceStrings ["/etc/"] [""] cfg.configFile}".source = config.age.secrets.xray-config-json.path;
      };

      services.xray = {
        enable = true;

        settingsFile = cfg.configFile;
      };

      networking = {
        proxy = {
          default = "socks5://127.0.0.1:10808";
          noProxy = "localhost,127.0.0.1,192.168.0.0/16,10.0.0.0/8,172.16.0.0/12";
        };
      };
    })

    (lib.mkIf (cfg.enable && config.homelab.services.jellyfinctl.enable) {
      services.jellyfin = {
        environment = {
          HTTP_PROXY = "socks5://127.0.0.1:10808";
          HTTPS_PROXY = "socks5://127.0.0.1:10808";
          NO_PROXY = "localhost,127.0.0.1,192.168.0.0/16,10.0.0.0/8,172.16.0.0/12";
        };
      };

      # systemd.services = {
      #   jellyfin.environment = {
      #     http_proxy = "http://127.0.0.1:10809";
      #     https_proxy = "http://127.0.0.1:10809";
      #   };
      # };
    })
  ];
}
