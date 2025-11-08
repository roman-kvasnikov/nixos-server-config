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
      diskspacealertctl.enable = true;
      smartdctl.enable = true;
      xrayctl.enable = true;

      backupctl = {
        enable = true;

        # jobs.data = {
        #   paths = ["/data"];
        # };
      };
    };

    homelab = {
      services = {
        homepagectl.enable = true;

        # frigatectl = {
        #   enable = true;

        #   cameras = {
        #     Outside = {
        #       enable = true;

        #       streamUrl = "rtsp://RomanK:Um9tYW4Um@192.168.1.30:554/stream1";
        #       roles = ["record"];

        #       record.enable = true;
        #     };

        #     Hall = {
        #       enable = true;

        #       streamUrl = "rtsp://RomanK:Um9tYW4Um@192.168.1.31:554/stream1";
        #       roles = ["detect" "record" "audio"];

        #       detect.enable = true;
        #       record = {
        #         enable = true;

        #         retain = {
        #           mode = "motion";
        #         };
        #       };
        #       audio.enable = true;
        #       snapshots.enable = true;
        #       motion.enable = true;

        #       onvif = {
        #         enable = true;

        #         host = "192.168.1.31";
        #         port = 2020;
        #         user = "RomanK";
        #         password = "Um9tYW4Um";
        #       };
        #     };
        #   };
        # };

        glancesctl.enable = true;
        immichctl.enable = true;
        jellyfinctl.enable = true;
        linkwardenctl.enable = true;
        microbinctl.enable = true;
        nextcloudctl.enable = true;
        onlyofficectl.enable = true;
        paperlessctl.enable = true;
        qbittorrentctl.enable = true;

        sambactl = {
          enable = true;

          users = ["romank" "dssmargo"];

          environmentFile = config.age.secrets.samba-env.path;

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
