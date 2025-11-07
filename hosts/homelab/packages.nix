{
  inputs,
  pkgs,
  ...
}: {
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    inputs.agenix.packages.${system}.default

    # CLI утилиты
    curl
    git
    wget
    jq
    ffmpeg
    tree
    lsof
    sysstat
    procps
    pciutils
    lshw
    libargon2

    yazi # File Manager
    filebot # Rename files based on metadata for movies and TV shows
    nodejs

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
    dig
  ];
}
