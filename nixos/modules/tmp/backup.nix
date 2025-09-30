{
  services = {
    # Restic для резервного копирования
    restic.backups = {
      homeserver = {
        initialize = true;
        repository = "/backup/restic"; # Или удаленный репозиторий
        passwordFile = "/etc/nixos/secrets/restic-password";

        paths = [
          "/var/lib/immich"
          "/var/lib/jellyfin"
          "/home"
          "/etc/nixos"
        ];

        timerConfig = {
          OnCalendar = "daily";
          Persistent = true;
        };

        pruneOpts = [
          "--keep-daily 7"
          "--keep-weekly 4"
          "--keep-monthly 12"
          "--keep-yearly 2"
        ];
      };
    };

    # Syncthing для синхронизации файлов
    syncthing = {
      enable = true;
      user = "romank"; # Замените на ваше имя пользователя
      dataDir = "/home/romank/.syncthing";
      configDir = "/home/romank/.config/syncthing";
      overrideDevices = true;
      overrideFolders = true;
      settings = {
        gui = {
          address = "0.0.0.0:8384";
        };
      };
    };
  };

  # Создать директории для бэкапов
  systemd.tmpfiles.rules = [
    "d /backup 0755 root root -"
    "d /backup/restic 0755 root root -"
  ];

  networking.firewall.allowedTCPPorts = [ 8384 22000 ];
  networking.firewall.allowedUDPPorts = [ 22000 21027 ];
}