{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.fishctl;
in {
  options.services.fishctl = {
    enable = lib.mkEnableOption "Enable Fish Shell";
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
    };

    users.defaultUserShell = pkgs.fish;
  };
}
