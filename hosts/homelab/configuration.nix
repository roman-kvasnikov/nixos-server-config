{
  version,
  config,
  ...
}: {
  imports = [
    inputs.agenix.nixosModules.default
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

  age.identityPaths = [
    "/etc/ssh/ssh_host_ed25519_key"
  ];
}
