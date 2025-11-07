{
  lib,
  config,
  hostname,
  ...
}: {
  options.homelab = {
    domain = lib.mkOption {
      type = lib.types.str;
      description = "Domain name for the homelab server";
      default = "kvasok.xyz";
    };

    ip = lib.mkOption {
      type = lib.types.str;
      description = "IP address for the homelab server";
      default = "192.168.1.11";
    };

    subnet = lib.mkOption {
      type = lib.types.str;
      description = "Subnet for the homelab server";
      default = "192.168.1.0/24";
    };

    vpnSubnet = lib.mkOption {
      type = lib.types.str;
      description = "VPN subnet for the homelab server";
      default = "172.16.0.0/16";
    };

    nameservers = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "Nameservers for the homelab server";
      default = ["192.168.1.1"];
    };

    interface = lib.mkOption {
      type = lib.types.str;
      description = "Lan interface for the homelab server";
      default = "enp0s20f0u9";
    };

    email = lib.mkOption {
      type = lib.types.str;
      description = "Email for ACME SSL certificate registration for the homelab server";
      default = "roman.kvasok@gmail.com";
    };

    systemUser = lib.mkOption {
      type = lib.types.str;
      description = "System user to run the homelab server services as";
      default = "share";
    };

    systemGroup = lib.mkOption {
      type = lib.types.str;
      description = "System group to run the homelab server services as";
      default = "share";
    };

    adminUser = lib.mkOption {
      type = lib.types.str;
      description = "Admin user for the homelab server";
      default = "romank";
    };

    adminPasswordFile = lib.mkOption {
      type = lib.types.path;
      description = "Admin password file for the homelab server";
      default = config.age.secrets.server-admin-password.path;
    };

    restic = {
      repository = lib.mkOption {
        type = lib.types.str;
        description = "Restic repository for the homelab server";
        default = "s3:https://s3.twcstorage.ru/1f382b96-c34b0ea3-eb1f-4476-b009-6e99275d7b19/backups/${hostname}";
      };

      environmentFile = lib.mkOption {
        type = lib.types.path;
        description = "Environment file for Restic";
        default = config.age.secrets.restic-env.path;
      };
    };
  };
}
