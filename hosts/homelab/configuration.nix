{
  version,
  config,
  ...
}: {
  imports = [
    ./agenix.nix
    ./boot.nix
    ./hardware-configuration.nix
    ./networking.nix
    ./nix.nix
    ./packages.nix
    ./security.nix
    ./server.nix
    ./services.nix
    ./users.nix
    ./zram.nix
  ];

  i18n.defaultLocale = "en_US.UTF-8";

  time.timeZone = "Europe/Moscow";

  system.stateVersion = version;
}
