{version, ...}: {
  imports = [
    ./hardware-configuration.nix
    ../../nixos
  ];

  i18n.defaultLocale = "en_US.UTF-8";

  time.timeZone = "Europe/Moscow";

  system.stateVersion = version;
}
