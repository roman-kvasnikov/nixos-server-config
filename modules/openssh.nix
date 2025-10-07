{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.opensshctl;
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
        AllowUsers = [config.server.adminUser];
        PasswordAuthentication = true;
        PermitRootLogin = "no";
        X11Forwarding = false;
      };
    };
  };
}
