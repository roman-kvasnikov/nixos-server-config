{
  services.samba = {
    enable = true;

    openFirewall = true;

    settings = {
      global = {
        "workgroup" = "WORKGROUP";
        "server string" = "j4";
        "netbios name" = "j4";
        "security" = "user";
        #"use sendfile" = "yes";
        #"max protocol" = "smb2";
        # note: localhost is the ipv6 localhost ::1
        "hosts allow" = "192.168.0. 127.0.0.1 localhost";
        "hosts deny" = "0.0.0.0/0";
        "guest account" = "nobody";
        "map to guest" = "bad user";
      };

      "public" = {
        "path" = "/home/Shares/Public";
        "browseable" = "yes";
        "read only" = "no";
        "guest ok" = "yes";
        "create mask" = "0644";
        "directory mask" = "0755";
      };
    };
  };

  services.samba-wsdd = {
    enable = true;

    openFirewall = true;
  };

  services.avahi = {
    enable = true;

    openFirewall = true;

    publish = {
      enable = true;

      userServices = true;
    };

    nssmdns4 = true;
  };
}
