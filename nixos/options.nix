{lib, ...}: {
  options.homelab = {
    domain = lib.mkOption {
      type = lib.types.str;
      description = "Domain name for the Homelab PC";
    };

    ip = lib.mkOption {
      type = lib.types.str;
      description = "IP address for the homelab server";
    };

    subnet = lib.mkOption {
      type = lib.types.str;
      description = "Subnet for the homelab server";
    };

    vpnSubnet = lib.mkOption {
      type = lib.types.str;
      description = "VPN subnet for the homelab server";
    };

    nameservers = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "Nameservers for the homelab server";
    };

    interface = lib.mkOption {
      type = lib.types.str;
      description = "Lan interface for the homelab server";
    };

    connectWireguard = lib.mkOption {
      type = lib.types.bool;
      description = "Connect to WireGuard VPN by default";
    };

    email = lib.mkOption {
      type = lib.types.str;
      description = "Email for ACME SSL certificate registration for the homelab server";
    };

    systemUser = lib.mkOption {
      type = lib.types.str;
      description = "System user to run the homelab server services as";
    };

    systemGroup = lib.mkOption {
      type = lib.types.str;
      description = "System group to run the homelab server services as";
    };

    adminUser = lib.mkOption {
      type = lib.types.str;
      description = "Admin user for the homelab server";
    };
  };
}
