{
  config,
  lib,
  ...
}: let
  cfg = config.services.smartdctl;
in {
  options.services.smartdctl = {
    enable = lib.mkEnableOption "Enable Smartd";
  };

  config = lib.mkIf cfg.enable {
    services.smartd = {
      enable = true;
    };
  };
}
