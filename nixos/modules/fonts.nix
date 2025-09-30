{pkgs, ...}: {
  fonts = {
    fontDir.enable = true;

    fontconfig = {
      enable = true;

      antialias = true;

      hinting = {
        enable = true;
        style = "slight"; # Современный hinting
      };

      subpixel = {
        rgba = "rgb"; # Для LCD мониторов
        lcdfilter = "default";
      };
    };

    enableDefaultPackages = true;

    packages = with pkgs; [
      nerd-fonts.fira-code
      nerd-fonts.jetbrains-mono
      font-awesome
      noto-fonts-emoji
    ];
  };
}
