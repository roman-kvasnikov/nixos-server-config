{
  services.minidlna = {
    enable = true;

    openFirewall = true;

    settings = {
      media_dir = [
        "P,/home/DLNA/Pictures/"
        "V,/home/DLNA/Videos/"
      ];

      inotify = "yes";
    };
  };

  users.users = {
    minidlna = {
      isNormalUser = false;
    };
  };
}
