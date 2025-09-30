{pkgs, ...}: {
  # XDG портал для интеграции приложений с системой
  xdg.portal = {
    enable = true;

    wlr.enable = false; # Отключаем wlroots портал для GNOME

    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk # GTK портал для файловых диалогов, etc.
      xdg-desktop-portal-gnome # GNOME портал для файловых диалогов, etc.
    ];

    config = {
      common = {
        default = "gnome";
        "org.freedesktop.impl.portal.FileChooser" = "gnome";
        "org.freedesktop.impl.portal.AppChooser" = "gnome";
        "org.freedesktop.impl.portal.Screenshot" = "gnome";
        "org.freedesktop.impl.portal.Wallpaper" = "gnome";
      };
    };
  };
}
