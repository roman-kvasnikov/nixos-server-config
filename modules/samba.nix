{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.sambactl;
in {
  options.services.sambactl = {
    enable = lib.mkEnableOption {
      description = "Enable Samba";
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [config.services.samba.package];

    services.samba = {
      enable = true;

      openFirewall = true;

      settings = {
        global = {
          "workgroup" = lib.mkDefault "WORKGROUP";
          "server string" = lib.mkDefault config.networking.hostName;
          "netbios name" = lib.mkDefault config.networking.hostName;
          "security" = lib.mkDefault "user";
          "invalid users" = ["root"];
          "hosts allow" = lib.mkDefault "192.168.1.0/24 127.0.0.1 localhost";
          "hosts deny" = lib.mkDefault "0.0.0.0/0";
          "guest account" = lib.mkDefault "nobody";
          "map to guest" = lib.mkDefault "bad user";
        };

        "public" = {
          "path" = "/mnt/Shares/Public";
          "browseable" = "yes";
          "read only" = "no";
          "guest ok" = "yes";
          "create mask" = "0644";
          "directory mask" = "0755";
          "force user" = "nobody";
          "force group" = "nogroup";
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

      extraServiceFiles = {
        smb = ''
          <?xml version="1.0" standalone='no'?><!--*-nxml-*-->
          <!DOCTYPE service-group SYSTEM "avahi-service.dtd">
          <service-group>
            <name replace-wildcards="yes">%h</name>
            <service>
              <type>_smb._tcp</type>
              <port>445</port>
            </service>
          </service-group>
        '';
      };
    };
  };
}
