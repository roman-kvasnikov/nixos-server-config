{
  security = {
    sudo = {
      enable = true;

      wheelNeedsPassword = true; # true - требует пароль для выполнения sudo.
      execWheelOnly = true; # true - позволяет только пользователям из группы wheel выполнять sudo.
    };
  };

  networking.firewall = {
    enable = true;

    allowPing = false;
    logRefusedConnections = true;
  };

  services.fail2ban.enable = true;
}
