{
  lib,
  config,
  ...
}: {
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

    adminPasswordFile = lib.mkOption {
      type = lib.types.path;
      description = "Admin password file for the server";
      default = config.age.secrets.server-admin-password.path;
    };
  };
}
