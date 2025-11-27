{
  imports = [
    ./hardware-configuration.nix
    ./harware.nix
    ./services.nix # Закомментировать при первой установке
    ./zfs.nix
    ../../nixos
  ];

  homelab = {
    domain = "kvasok.xyz";
    ip = "192.168.1.10";
    subnet = "192.168.1.0/24";
    vpnSubnet = "172.16.0.0/16";
    nameservers = ["192.168.1.1"];
    interface = "enp2s0";
    connectWireguard = true;
    email = "roman.kvasnikov@gmail.com";
    adminUser = "romank";
  };
}
