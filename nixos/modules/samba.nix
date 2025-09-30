{
  services = {
    samba = {
      enable = true;

      enableNmbd = true;

      extraConfig = ''
        workgroup = WORKGROUP
        server string = Samba Server
        server role = standalone server
        log file = /var/log/samba/smbd.%m
        max log size = 50
        dns proxy = no
        map to guest = Bad User
      '';

      shares = {
        public = {
          path = "/home/public";
          browseable = "yes";
          "writable" = "yes";
          "guest ok" = "yes";
          "public" = "yes";
          "force user" = "share";
        };
      };
    };
  };

  networking.firewall.allowedTCPPorts = [135 139 445];
  networking.firewall.allowedUDPPorts = [137 138];
}
