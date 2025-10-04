{lib, ...}: {
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
  };
}
