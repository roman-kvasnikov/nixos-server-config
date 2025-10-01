{pkgs, ...}: {
  boot = {
    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 10;
      };

      efi = {
        canTouchEfiVariables = true;
      };
    };

    kernelPackages = pkgs.linuxPackages_latest;

    kernel.sysctl = {
      # Увеличить лимиты для файловых дескрипторов
      "fs.file-max" = 2097152;
      "fs.nr_open" = 1048576;

      # Оптимизация сети
      "net.core.rmem_max" = 134217728;
      "net.core.wmem_max" = 134217728;
      "net.ipv4.tcp_rmem" = "4096 65536 134217728";
      "net.ipv4.tcp_wmem" = "4096 65536 134217728";

      # Оптимизация памяти
      "vm.swappiness" = 10;
      "vm.dirty_ratio" = 15;
      "vm.dirty_background_ratio" = 5;
    };
  };
}
