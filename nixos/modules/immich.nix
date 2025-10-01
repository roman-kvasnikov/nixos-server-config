{
  services.immich = {
    enable = true;

    host = "0.0.0.0";
    port = 2283;

    openFirewall = true;

    # Настройки Redis для совместимости
    redis = {
      enable = true;

      # Принудительно использовать совместимую версию RDB
      rdbcompression = true;
      rdbchecksum = true;
    };
  };

  # networking.firewall.allowedTCPPorts = [2283];
}
