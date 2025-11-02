{
  lib,
  config,
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
  };
}
