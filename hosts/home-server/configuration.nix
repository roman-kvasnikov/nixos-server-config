{version, ...}: {
  imports = [
    ./nix.nix
    ./hardware-configuration.nix
    ./boot.nix
    ./networking.nix
    ./security.nix
    ./user.nix
    ./zram.nix
    ./settings.nix
    ./services.nix
    ../../modules
    ./packages.nix
  ];

  i18n.defaultLocale = "en_US.UTF-8";

  time.timeZone = "Europe/Moscow";

  system.stateVersion = version;
}
