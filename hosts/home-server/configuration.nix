{
  imports = [
    ./hardware-configuration.nix
    ../../nixos
  ];

  boot = {
    loader = {
      systemd-boot = {
        enable = true;
      };

      efi = {
        canTouchEfiVariables = true;
      };
    };
  };

  services.openssh = {
    enable = true;
  };

  system.stateVersion = "25.05";
}
