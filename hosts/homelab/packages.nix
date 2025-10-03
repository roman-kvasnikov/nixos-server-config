{pkgs, ...}: {
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    # CLI утилиты
    curl
    git
    wget
    jq
    ffmpeg
    tree

    # Terminal
    kitty

    # Архиваторы
    gzip
    p7zip
    zip
    unzip
    unrar

    # Мониторинг
    htop
    btop
    lm_sensors
  ];
}
