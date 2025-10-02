{
  imports = [
    ./boot.nix
    ./cockpit.nix
    ./fish.nix
    ./immich.nix
    ./jellyfin.nix
    ./minidlna.nix
    ./networking.nix
    ./nix.nix
    ./openssh.nix
    ./samba.nix
    ./security.nix
    ./services.nix
    ./user.nix
    ./zram.nix
  ];

  cockpit.enable = true;
}
