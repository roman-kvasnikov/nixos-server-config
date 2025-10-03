{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.opensshctl;
in {
  options.services.opensshctl = {
    enable = lib.mkEnableOption {
      description = "Enable OpenSSH";
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      openssh
    ];

    services.openssh = {
      enable = true;

      openFirewall = true;

      settings = {
        AllowUsers = ["romank"]; # If specified, login is allowed only for the listed users
        PasswordAuthentication = true; # Specifies whether password authentication is allowed
        PermitRootLogin = "no"; # Whether the root user can login using ssh
        X11Forwarding = false; # Whether to allow X11 connections to be forwarded
      };
    };
  };
}
