{pkgs, ...}: {
  systemd = {
    services = {
      NetworkManager-wait-online.enable = true;
      systemd-networkd-wait-online.enable = false;
    };
  };
}
