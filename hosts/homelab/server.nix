{
  config,
  lib,
  ...
}: let
  cfg = config.server;
in {
  imports = [
    ../../modules
    ../../modules/homelab
  ];

  options.server = {
    email = lib.mkOption {
      type = lib.types.str;
      description = "Email for ACME registration";
      default = "roman.kvasok@gmail.com";
    };

    domain = lib.mkOption {
      type = lib.types.str;
      description = "Domain name for the server";
      default = "kvasok.xyz";
    };

    ip = lib.mkOption {
      type = lib.types.str;
      description = "IP address for the server";
      default = "192.168.1.11";
    };

    subnet = lib.mkOption {
      type = lib.types.str;
      description = "Subnet for the server";
      default = "192.168.1.0/24";
    };

    systemUser = lib.mkOption {
      type = lib.types.str;
      description = "System user to run the server services as";
      default = "share";
    };

    systemGroup = lib.mkOption {
      type = lib.types.str;
      description = "System group to run the server services as";
      default = "share";
    };

    adminUser = lib.mkOption {
      type = lib.types.str;
      description = "Admin user for the server";
      default = "romank";
    };
  };

  config = {
    users = {
      users = {
        ${config.server.systemUser} = {
          isSystemUser = true;
          group = config.server.systemGroup;
        };
      };

      groups.${config.server.systemGroup} = {};
    };

    services = {
      acmectl.enable = true;
      nginxctl.enable = true;

      # delugectl.enable = false;
      # filebrowserctl.enable = true;
      # immichctl.enable = true;
      # jellyfinctl.enable = true;

      # sambactl = {
      #   enable = true;

      #   users = ["romank"];

      #   shares = {
      #     public = {
      #       "path" = "/home/public";
      #     };

      #     movies = {
      #       "path" = "/home/movies";
      #     };

      #     romank = {
      #       "path" = "/home/romank";
      #       "public" = "no";
      #       "guest ok" = "no";
      #       "create mask" = "0770";
      #       "directory mask" = "0770";
      #       "force user" = "romank";
      #       "force group" = "romank";
      #       "valid users" = ["romank"];
      #     };
      #   };
      # };

      # unifictl.enable = false;
      # uptime-kumactl.enable = true;
      # xrayctl.enable = true;

      # Additional services
      # dbus.enable = true; # Для работы с systemd
      # udisks2.enable = true; # Автоматическое монтирование USB
      # geoclue2.enable = true; # Геолокация для часовых поясов
    };

    homelab = {
      services = {
        homepagectl.enable = true;
        cockpitctl.enable = true;
        nextcloudctl.enable = true;
        qbittorrentctl.enable = true;
        immichctl.enable = true;
      };
    };
  };
}
