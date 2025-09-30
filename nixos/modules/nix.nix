{pkgs, ...}: {
  nix = {
    # Автоматическая оптимизация store
    optimise = {
      automatic = true;
      dates = ["03:45"]; # Оптимизация рано утром
    };

    # Сборка мусора
    gc = {
      automatic = true;
      dates = "daily";
      options = "--delete-older-than 7d";
      randomizedDelaySec = "1h"; # Случайная задержка для SSD
    };
  };
}
