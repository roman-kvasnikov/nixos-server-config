{version, ...}: {
  imports = [
    ./hardware-configuration.nix
    ../../nixos
  ];

  system.stateVersion = version;
}
