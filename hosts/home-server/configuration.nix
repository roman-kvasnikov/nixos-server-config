{version, ...}: {
  imports = [
    ./hardware-configuration.nix
    ../../nixos
  ];

  boot = {
    loader = {
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot/efi";
      };

      systemd-boot = {
        enable = true;
      };
    };
  };

  services.openssh = {
    enable = true;
  };

  system.stateVersion = version;
}
