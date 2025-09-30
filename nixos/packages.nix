{pkgs, ...}: {
  nixpkgs.config = {
    allowUnfree = true;
  };

  environment = {
    systemPackages = with pkgs; [
      # Основные утилиты (должны быть в системе для скриптов)
      curl
      wget
      git

      # Архиваторы (системные зависимости)
      gzip
      p7zip
      zip
      unzip
      unrar

      # Мониторинг (для системных служб)
      htop
      btop
    ];
  };
}
