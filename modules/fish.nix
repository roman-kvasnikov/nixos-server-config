{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.fishctl;
in {
  options.services.fishctl = {
    enable = lib.mkEnableOption {
      description = "Enable Fish Shell";
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      fish
      eza
      bat
    ];

    programs.fish = {
      enable = true;

      shellAliases = {
        ls = "eza -al --color=always --group-directories-first --icons";
        la = "eza -a --color=always --group-directories-first --icons";
        ll = "eza -l --color=always --group-directories-first --icons";
        lt = "eza -aT --color=always --group-directories-first --icons";
        cat = "bat --paging=never";
      };

      shellInit = with pkgs; ''
        set -g fish_greeting

        if systemctl is-active --quiet xray; and test -f /etc/fish/proxy-env.fish
            source /etc/fish/proxy-env.fish
        end
      '';
    };

    users.defaultUserShell = pkgs.fish;
  };
}
