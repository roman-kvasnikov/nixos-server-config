{
  systemd = {
    extraConfig = ''
      DefaultTimeoutStopSec=30s
      DefaultLimitNOFILE=1048576
    '';

    services = {
      NetworkManager-wait-online.enable = true;
      systemd-networkd-wait-online.enable = false;

      # Оптимизация journald
      systemd-journald.serviceConfig = {
        SystemMaxUse = "1G";
        MaxRetentionSec = "1month";
      };
    };
  };
}
