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

        filebrowserctl.enable = true;
        actualctl.enable = true;
        frigatectl.enable = false;
        glancesctl.enable = true;
        immichctl.enable = true;
        it-tools-ctl.enable = true;
        jellyfinctl.enable = true;
        jellyseerrctl.enable = true;
        librespeedtl.enable = true;
        linkwardenctl.enable = true;
        microbinctl.enable = true;
        nextcloudctl.enable = true;
        onlyofficectl.enable = true;
        paperlessctl.enable = true;
        pgadminctl.enable = true;
        portainerctl.enable = true;
        prowlarrctl.enable = true;
        qbittorrentctl.enable = true;
        radarrctl.enable = true;

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

        sonarrctl.enable = true;
        speedtest-tracker-ctl.enable = true;
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
