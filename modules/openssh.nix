{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.opensshctl;
  cfgServer = config.server;
in {
  options.services.opensshctl = {
    enable = lib.mkEnableOption "Enable OpenSSH";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      openssh
    ];

    services.openssh = {
      enable = true;

      openFirewall = true;

      settings = {
        AllowUsers = [cfgServer.adminUser];
        PasswordAuthentication = true;
        PermitRootLogin = "no";
        X11Forwarding = false;
      };
    };
  };
}
