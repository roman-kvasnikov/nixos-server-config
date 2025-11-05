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
      resolved.enable = false;
      dbus.enable = true; # Для работы с systemd
      udisks2.enable = true; # Автоматическое монтирование USB
      geoclue2.enable = true; # Геолокация для часовых поясов

      # User services
      acmectl.enable = true;
      nginxctl.enable = true;
      diskspacealertctl.enable = true;
      # dnsmasqctl.enable = false;
      # hddfancontrolctl.enable = true;
      smartdctl.enable = true;
      xrayctl.enable = true;
    };

    homelab = {
      services = {
        homepagectl.enable = true;

        # filebrowserctl.enable = true;

        frigatectl = {
          enable = true;

          cameras = {
            # outside = {
            #   enable = true;

            #   streamUrl = "rtsp://RomanK:Um9tYW4Um@192.168.1.31:554/stream1";

            #   roles = ["record"];

            #   record.enable = true;
            # };

            hall = {
              enable = true;

              streamUrl = "rtsp://RomanK:Um9tYW4Um@192.168.1.31:554/stream1";

              roles = ["detect" "record"];

              detect.enable = true;
              record.enable = true;
              snapshots.enable = true;

              onvif = {
                enable = true;

                host = "192.168.1.31";
                port = 2020;
                user = "RomanK";
                password = "Um9tYW4Um";
              };
            };
          };
        };

        immichctl.enable = true;
        jellyfinctl.enable = true;
        microbinctl.enable = true;
        nextcloudctl.enable = true;
        onlyofficectl.enable = true;
        paperlessctl.enable = true;
        qbittorrentctl.enable = true;

        sambactl = {
          enable = true;

          users = {
            romank = {
              passwordFile = config.age.secrets.samba-romank-password.path;
            };
            dssmargo = {
              passwordFile = config.age.secrets.samba-dssmargo-password.path;
            };
          };

          shares = {
            Shared = {
              directory = "Shared";
              comment = "Shared files for everyone";
              public = true;
              browseable = true;
              writeable = true;
            };

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

        uptime-kuma-ctl.enable = true;
        vaultwardenctl.enable = true;

        resticctl.enable = true;
      };
    };
  };
}
