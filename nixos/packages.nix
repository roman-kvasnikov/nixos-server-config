{pkgs, ...}: {
  nixpkgs.config = {
    allowUnfree = true;
  };

  environment = {
    systemPackages = with pkgs; [
      # CLI утилиты
      curl
      git
      wget
      eza
      bat
      jq
      ffmpeg
      tree

      # Terminal
      firefox

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
  };
}
