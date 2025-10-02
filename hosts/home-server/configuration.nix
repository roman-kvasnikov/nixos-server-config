{version, ...}: {
  imports = [
    ./hardware-configuration.nix
    ../../nixos
  ];

  i18n.defaultLocale = "en_US.UTF-8";

  time.timeZone = "Europe/Moscow";

  system.stateVersion = version;

  services.homepage-dashboard = {
    # These options were already present in my configuration.
    enable = true;
    listenPort = 8082;

    # The following options were what I planned to add.

    # https://gethomepage.dev/latest/configs/settings/
    settings = {
    };

    # https://gethomepage.dev/latest/configs/bookmarks/
    bookmarks = [
      {
        name = "Homepage";
        url = "https://home-server.local";
      }
    ];

    # https://gethomepage.dev/latest/configs/services/
    services = [
      {
        name = "Homepage";
        url = "https://home-server.local";
      }
    ];

    # https://gethomepage.dev/latest/configs/service-widgets/
    widgets = [];

    # https://gethomepage.dev/latest/configs/kubernetes/
    kubernetes = {};

    # https://gethomepage.dev/latest/configs/docker/
    docker = {};

    # https://gethomepage.dev/latest/configs/custom-css-js/
    customJS = "";
    customCSS = "";
  };

  networking.firewall.allowedTCPPorts = [8082];
}
