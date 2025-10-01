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

  services.fail2ban = {
    enable = true;

    maxretry = 3;
    bantime = "1h";
    ignoreIP = [
      "10.0.0.0/8"
      "172.16.0.0/12"
      "192.168.0.0/16"
    ];

    # jails = {
    #   sshd.settings = {
    #     enabled = true;

    #     filter = "sshd";
    #     maxretry = 3;
    #     findtime = 600;
    #     bantime = 3600;
    #     ignoreip = [
    #       "10.0.0.0/8"
    #       "172.16.0.0/12"
    #       "192.168.0.0/16"
    #     ];
    #   };
    # };
  };
}
