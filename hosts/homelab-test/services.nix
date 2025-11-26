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

      backupctl.enable = false;
    };

    homelab = {
      services = {
        homepagectl.enable = true;

        # Clouds
        actualctl.enable = false;
        immichctl.enable = true;
        linkwardenctl.enable = true;
        nextcloudctl.enable = true;
        onlyofficectl.enable = true;
        paperlessctl.enable = true;
        vaultwardenctl.enable = true;

        # Media
        jellyfinctl.enable = true;
        jellyseerrctl.enable = true;
        prowlarrctl.enable = true;
        qbittorrentctl.enable = true;
        radarrctl.enable = true;
        sonarrctl.enable = true;

        # Monitoring
        glancesctl.enable = true;
        speedtest-tracker-ctl.enable = true;
        uptime-kuma-ctl.enable = true;

        # Services
        frigatectl.enable = false;
        it-tools-ctl.enable = true;
        # jitsi-meet-ctl.enable = true;
        librespeedtl.enable = true;
        microbinctl.enable = true;
        pgadminctl.enable = true;
        portainerctl.enable = true;

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
