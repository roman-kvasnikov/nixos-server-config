{
  imports = [
    ./hardware-configuration.nix
    ./harware.nix
    ./services.nix
    ../../nixos
  ];

  homelab = {
    domain = "kvasok.xyz";
    ip = "192.168.1.11";
    subnet = "192.168.1.0/24";
    vpnSubnet = "172.16.0.0/16";
    nameservers = [
      "9.9.9.9"
      "1.1.1.1"
      "8.8.8.8"
      "192.168.1.1"
    ];
    interface = "enp0s20f0u9";
    connectWireguard = true;
    email = "roman.kvasok@gmail.com";
    systemUser = "share";
    systemGroup = "share";
    adminUser = "romank";
  };
}
