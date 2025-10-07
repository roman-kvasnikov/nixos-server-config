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

    settingsFile = lib.mkOption {
      type = lib.types.path;
      description = "Settings file for Xray";
      default = "/etc/xray/config.json";
    };

    proxyEnvFishFile = lib.mkOption {
      type = lib.types.path;
      description = "Proxy environment file for Fish Shell";
      default = "/etc/xray/proxy-env.fish";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      xray
    ];

    environment.etc."${cfg.settingsFile}".source = ../secrets/xray/config.json;

    services.xray = {
      enable = true;

      settingsFile = cfg.settingsFile;
    };

    environment.etc."${cfg.proxyEnvFishFile}".text = ''
      # Xray proxy environment variables (managed by xrayctl)
      set -x http_proxy http://127.0.0.1:10809
      set -x https_proxy http://127.0.0.1:10809
      set -x ftp_proxy http://127.0.0.1:10809
      set -x HTTP_PROXY http://127.0.0.1:10809
      set -x HTTPS_PROXY http://127.0.0.1:10809
      set -x FTP_PROXY http://127.0.0.1:10809
      set -x no_proxy localhost,127.0.0.1,192.168.0.0/16,10.0.0.0/8,172.16.0.0/12
      set -x NO_PROXY localhost,127.0.0.1,192.168.0.0/16,10.0.0.0/8,172.16.0.0/12
    '';

    programs.fish.shellInit = with pkgs; ''
      if systemctl is-active --quiet xray; and test -f ${cfg.proxyEnvFishFile}
          source ${cfg.proxyEnvFishFile}
      end
    '';
  };
}
