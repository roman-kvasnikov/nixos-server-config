{
  config,
  lib,
  ...
}: let
  cfgHomelab = config.homelab;
in {
  imports = [
    ../../modules/homelab
    ../../modules/programs
    ../../modules/services
  ];

  config = {
    services = {
      wireguardctl.enable = cfgHomelab.connectWireguard;

      resolved.enable = false;
      dbus.enable = true; # Для работы с systemd
      udisks2.enable = true; # Автоматическое монтирование USB
      geoclue2.enable = true; # Геолокация для часовых поясов

      # User services
      acmectl.enable = true;
      nginxctl.enable = true;
      smartdctl.enable = true;
      storagespacealertctl.enable = true;
      xrayctl.enable = true;

      backupctl.enable = true;
    };

    homelab = {
      services = {
        homepagectl.enable = true;

        # Clouds
        immichctl = {
          enable = true;
          allowExternal = true;
        };
        linkwardenctl = {
          enable = true;
          allowExternal = true;
        };
        nextcloudctl = {
          enable = true;
          allowExternal = true;
        };
        onlyofficectl.enable = false;
        paperlessctl.enable = true;
        vaultwardenctl.enable = true;

        # Media
        jellyfinctl = {
          enable = true;
          allowExternal = true;
        };
        jellyseerrctl = {
          enable = true;
          allowExternal = true;
        };
        prowlarrctl.enable = true;
        qbittorrentctl = {
          enable = true;
          allowExternal = true;
        };
        radarrctl.enable = true;
        sonarrctl.enable = true;

        # Monitoring
        glancesctl.enable = true;
        speedtest-tracker-ctl.enable = true;
        uptime-kuma-ctl.enable = true;

        # Services
        adguardhomectl.enable = true;
        frigatectl.enable = true;
        it-tools-ctl = {
          enable = true;
          allowExternal = true;
        };
        # jitsi-meet-ctl.enable = true;
        librespeedtl.enable = true;
        microbinctl = {
          enable = true;
          allowExternal = true;
        };
        pgadminctl.enable = true;
        # piholectl.enable = true;
        portainerctl.enable = true;

        sambactl = {
          enable = true;

          users = ["romank" "dssmargo"];

          environmentFile = config.age.secrets.samba-env.path;

          shares = {
            # Public shares
            Shared = {
              directory = "Shared";
              comment = "Shared files for everyone";
              public = true;
              browseable = true;
              writeable = true;
            };

            Software = {
              directory = "Software";
              comment = "Software for everyone";
              public = true;
              browseable = true;
              writeable = true;
            };

            Photos = {
              directory = "Photos";
              comment = "Photos for everyone";
              public = true;
              browseable = true;
              writeable = true;
            };

            # Private shares
            RomanK = {
              directory = "RomanK";
              comment = "RomanK's Private Share";
              public = false;
              browseable = true;
              writeable = true;
              validUsers = ["romank"];
              forceUser = "romank";
              forceGroup = "users";
            };

            DssMargo = {
              directory = "DssMargo";
              comment = "DssMargo's Private Share";
              public = false;
              browseable = true;
              writeable = true;
              validUsers = ["dssmargo"];
              forceUser = "dssmargo";
              forceGroup = "users";
            };
          };
        };
      };
    };

    age.secrets.samba-env = {
      file = ../../secrets/samba.env.age;
      owner = "root";
      group = "root";
      mode = "0400";
    };
  };
}
