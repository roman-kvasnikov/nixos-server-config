{
  services.openssh = {
    enable = true;

    settings = {
      PasswordAuthentication = true;
      PermitRootLogin = "no";
      X11Forwarding = false;
      AllowUsers = ["romank"];
    };
  };
}
