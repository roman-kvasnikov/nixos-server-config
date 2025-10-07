{
  version,
  config,
  ...
}: {
  imports = [
    ./boot.nix
    ./hardware-configuration.nix
    ./networking.nix
    ./nix.nix
    ./packages.nix
    ./secrets.nix
    ./security.nix
    ./server.nix
    ./users.nix
    ./zram.nix
  ];

  # config.services.server.enable = true;

  # i18n.defaultLocale = "en_US.UTF-8";

  # time.timeZone = "Europe/Moscow";

  # system.stateVersion = version;
}
