{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.storagespacealertctl;
in {
  options.services.storagespacealertctl = {
    enable = lib.mkEnableOption "Enable Storage Space Alert";

    mountpoint = lib.mkOption {
      type = lib.types.str;
      description = "Mountpoint to check";
      default = "/mnt/data";
    };

    threshold = lib.mkOption {
      description = "Threshold for disk space alert";
      type = lib.types.str;
      default = "80";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd = {
      services.storage-space-alert = {
        description = "Alert when storage is getting full";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = pkgs.writeShellScript "check-storage-space" ''
            USAGE=$(df -h ${cfg.mountpoint} | tail -1 | awk '{print $5}' | sed 's/%//')

            if [ $USAGE -gt ${cfg.threshold} ]; then
              echo "WARNING: Storage ${cfg.mountpoint} is $USAGE% full!" | systemd-cat -t storage-alert -p warning

              # ${pkgs.curl}/bin/curl -s -X POST \
              #   "https://api.telegram.org/bot<ВАШ_ТОКЕН>/sendMessage" \
              #   -d chat_id=<ВАШ_CHAT_ID> \
              #   -d text="⚠️ WARNING: Storage ${cfg.mountpoint} на ${config.networking.hostName} заполнен на $USAGE%!"
            fi
          '';
        };
      };

      timers.storage-space-alert = {
        wantedBy = ["timers.target"];
        timerConfig = {
          OnCalendar = "daily";
          Persistent = true;
        };
      };
    };
  };
}
