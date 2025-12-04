{
  imports = [
    ./hardware-configuration.nix
    ./harware.nix
    ./services.nix
    ../../nixos
  ];

  homelab = {
    domain = "backup.kvasok.xyz";
    ip = "192.168.1.11";
    subnet = "192.168.1.0/24";
    vpnSubnet = "172.16.0.0/16";
    nameservers = ["192.168.1.10"];
    interface = "enp1s0";
    connectWireguard = false;
    email = "roman.kvasnikov@gmail.com";
    adminUser = "backup";
  };

  users = {
    users = {
      romank = {
        isNormalUser = true;
        extraGroups = ["wheel" "users" "docker" "podman" "nextcloud" "samba" "downloads" "media"];
        hashedPasswordFile = config.age.secrets.admin-password.path;
      };
    };
  };

  age.secrets.admin-password = {
    file = ../secrets/admin.password.age;
    owner = "root";
    group = "root";
    mode = "0400";
  };
}
