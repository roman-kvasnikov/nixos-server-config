{pkgs, ...}: {
  services.dbus.packages = with pkgs; [pass-secret-service];

  environment.systemPackages = with pkgs; [
    gnupg
    pinentry-gtk2
  ];
}
