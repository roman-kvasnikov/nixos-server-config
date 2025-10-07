{
  security = {
    sudo = {
      enable = true;

      wheelNeedsPassword = true; # true - требует пароль для выполнения sudo.
      execWheelOnly = true; # true - позволяет только пользователям из группы wheel выполнять sudo.
    };

    polkit.enable = true;
  };

  networking.firewall = {
    enable = true;

    allowPing = true;
    logRefusedConnections = true;

    allowedTCPPorts = [80 443];
  };

  services.fail2ban.enable = true;
}
