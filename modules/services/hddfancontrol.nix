{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.hddfancontrolctl;
in {
  options.services.hddfancontrolctl = {
    enable = lib.mkEnableOption "Enable HDD Fan Control";
  };

  config = lib.mkIf cfg.enable {
    services.hddfancontrol = {
      enable = true;

      settings = {
        harddrives = {
          disks = [
            "/dev/sda"
          ];
          pwmPaths = [
            "/sys/class/hwmon/hwmon1/pwm1:25:10"
          ];
          logVerbosity = "DEBUG";
        };
      };
    };
  };
}
