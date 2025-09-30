{
  services = {
    minidlna = {
      enable = true;

      openFirewall = true;

      settings = {
        friendly_name = "NixOS-DLNA";

        # https://mylinuxramblings.wordpress.com/2016/02/19/mini-how-to-installing-minidlna-in-ubuntu/
        # "A" for audio    (eg. media_dir=A,/var/lib/minidlna/music)
        # "P" for pictures (eg. media_dir=P,/var/lib/minidlna/pictures)
        # "V" for video    (eg. media_dir=V,/var/lib/minidlna/videos)
        # "PV" for pictures and video (eg. media_dir=PV,/var/lib/minidlna/digital_camera)

        media_dir = [
          "A,/home/DLNA/Music/"
          "P,/home/DLNA/Pictures/"
          "V,/home/DLNA/Videos/"
        ];

        inotify = "yes";
        log_level = "error";
        announceInterval = 60;
      };
    };
  };

  users.users.minidlna = {
    extraGroups = ["users" "samba" "wheel"];
  };

  networking.firewall.allowedTCPPorts = [8200];
  networking.firewall.allowedUDPPorts = [1900];
}
