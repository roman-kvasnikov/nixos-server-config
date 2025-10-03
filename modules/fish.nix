{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
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

    shellInit = with pkgs; ''set -g fish_greeting'';
  };

  users.defaultUserShell = pkgs.fish;
}
