{
  inputs,
  pkgs,
  ...
}: {
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    inputs.agenix.packages.${system}.default
    inputs.alejandra.defaultPackage.${system}

    # CLI утилиты
    curl
    wget
    git
    gh # GitHub CLI
    lazygit # GitHub CLI
    jq
    ffmpeg
    tree
    lsof
    sysstat
    procps
    pciutils
    lshw
    libargon2
    glibc
    libgcc
    zlib
    ssh-copy-id
    openssh
    openssl
    rsync

    # HDD Controls
    smartmontools
    mdadm

    yazi # File Manager
    filebot # Rename files based on metadata for movies and TV shows
    nodejs

    # Архиваторы
    gnutar
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
