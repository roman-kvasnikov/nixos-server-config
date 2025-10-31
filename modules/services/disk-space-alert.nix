{pkgs, ...}: {
  systemd = {
    services = {
      disk-space-alert = {
        description = "Alert when disk is getting full";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = pkgs.writeShellScript "check-disk-space" ''
            USAGE=$(df -h /data | tail -1 | awk '{print $5}' | sed 's/%//')
            if [ $USAGE -gt 80 ]; then
              echo "WARNING: RAID is $USAGE% full!" | systemd-cat -t disk-alert -p warning

              # ${pkgs.curl}/bin/curl -s -X POST \
              #   "https://api.telegram.org/bot<ВАШ_ТОКЕН>/sendMessage" \
              #   -d chat_id=<ВАШ_CHAT_ID> \
              #   -d text="⚠️ WARNING: RAID на ${config.networking.hostName} заполнен на $USAGE%!"
            fi
          '';
        };
      };
    };

    timers = {
      disk-space-alert = {
        wantedBy = ["timers.target"];
        timerConfig = {
          OnCalendar = "daily";
          Persistent = true;
        };
      };
    };
  };
}
