{
  imports = [
    ./hardware-configuration.nix
    ./harware.nix
    ./services.nix
    ../../nixos
  ];

  homelab = {
    domain = "pc.kvasok.xyz";
    ip = "192.168.1.12";
    subnet = "192.168.1.0/24";
    vpnSubnet = "172.16.0.0/16";
    nameservers = ["192.168.1.1"];
    interface = "enp2s0";
    connectWireguard = false;
    email = "roman.kvasok@gmail.com";
    systemUser = "share";
    systemGroup = "share";
    adminUser = "romank";
  };
}
