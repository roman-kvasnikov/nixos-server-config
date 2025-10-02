{
  config,
  pkgs,
  ...
}: let
  cfg = config.cockpit;
in {
  # ============================================================================
  # MODULE OPTIONS
  # ============================================================================

  options.cockpit = {
    enable = mkEnableOption "Cockpit service";

    port = mkOption {
      type = types.port;
      default = 9090;
      description = "Port for Cockpit web interface";
    };
  };

  # ============================================================================
  # MODULE IMPLEMENTATION
  # ============================================================================

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      cockpit
    ];

    services.cockpit = {
      enable = true;

      port = cfg.port;

      openFirewall = true;

      settings = {
        WebService = {
          AllowUnencrypted = true;
        };
      };
    };
  };
}
