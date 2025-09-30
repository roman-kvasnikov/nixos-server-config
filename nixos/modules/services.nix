{
  services = {
    # fail2ban = {
    #   enable = true;

    #   bantime-increment.enable = true;

    #   jails = {
    #     sshd = ''
    #       enabled = true
    #       filter = sshd
    #       action = iptables[name=ssh, port=ssh, protocol=tcp]
    #       maxretry = 3
    #       bantime = 3600
    #       findtime = 600
    #     '';
    #   };
    # };

    # Автоматические обновления безопасности
    # automatic-timers = true;

    # Автоматическое монтирование USB (для Files/Nautilus)
    udisks2.enable = true;

    # Геолокация для часовых поясов
    geoclue2.enable = true;
  };
}
