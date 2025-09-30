{
  lib,
  pkgs,
  ...
}: {
  programs.fish = lib.mkForce {
    enable = true;

    shellAliases = {
      ls = "eza -al --color=always --group-directories-first --icons";
      la = "eza -a --color=always --group-directories-first --icons";
      ll = "eza -l --color=always --group-directories-first --icons";
      lt = "eza -aT --color=always --group-directories-first --icons";
      cat = "bat --paging=never";
    };

    shellInit = with pkgs; ''set -g fish_greeting'';

    # interactiveShellInit = with pkgs; ''fastfetch'';
  };

  xdg.configFile = {
    "fish/functions/fish_prompt.fish".source = ./functions/fish_prompt.fish;
  };
}
