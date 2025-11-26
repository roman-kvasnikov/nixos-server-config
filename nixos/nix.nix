{
  nix = {
    # Автоматическая оптимизация store
    optimise = {
      automatic = true;
      dates = ["05:00"]; # Оптимизация рано утром
    };

    # Сборка мусора
    gc = {
      automatic = true;
      dates = "daily";
      options = "--delete-older-than 7d";
      randomizedDelaySec = "1h"; # Случайная задержка для SSD
    };

    settings = {
      auto-optimise-store = true;
      experimental-features = ["nix-command" "flakes"];
      download-buffer-size = 524288000; # 500 MiB
    };
  };
}
