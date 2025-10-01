{
  services.openssh = {
    enable = true;

    settings = {
      LoginGraceTime = "1m";
      PermitRootLogin = "no";
      MaxSessions = 1;
      PubkeyAuthentication = true;
      PasswordAuthentication = true; # Нужно изменить на false в production.
      PermitEmptyPasswords = false;
      X11Forwarding = false;
      AllowUsers = ["romank"];
    };
  };
}
