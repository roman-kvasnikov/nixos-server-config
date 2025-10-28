{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.homelab.services.vmctl;
  cfgHomelab = config.homelab;
  cfgAcme = config.services.acmectl;
  cfgNginx = config.services.nginxctl;
in {
  options.homelab.services.vmctl = {
    enable = lib.mkEnableOption "Enable virtual machine management (libvirt + cockpit)";

    host = lib.mkOption {
      type = lib.types.str;
      description = "Hostname for VM Web UI";
      default = "cockpit.${cfgHomelab.domain}";
    };

    homepage = {
      name = lib.mkOption {
        type = lib.types.str;
        default = "VM Manager";
      };
      description = lib.mkOption {
        type = lib.types.str;
        default = "Virtual machine manager with web UI";
      };
      icon = lib.mkOption {
        type = lib.types.str;
        default = "virtual-machine.svg";
      };
      category = lib.mkOption {
        type = lib.types.str;
        default = "Infrastructure";
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      # Основные пакеты
      environment.systemPackages = with pkgs; [
        virt-manager
        qemu_kvm
      ];

      # Включаем libvirt + KVM
      virtualisation.libvirtd = {
        enable = true;
        qemu = {
          package = pkgs.qemu_kvm;
          runAsRoot = false;
          swtpm.enable = true; # TPM для Windows VM
        };
      };

      users.users.${cfgHomelab.user}.extraGroups = ["libvirtd" "kvm"];

      # Cockpit — веб-интерфейс
      services.cockpit = {
        enable = true;
        # Включаем модуль управления виртуалками
        packages = with pkgs.cockpitPackages; [machines];
      };

      # Если nginx не включён, открываем порт cockpit
      networking.firewall.allowedTCPPorts = lib.mkIf (!cfgNginx.enable) [9090];
    })

    (lib.mkIf (cfg.enable && cfgAcme.enable) {
      security.acme.certs."${cfg.host}" = cfgAcme.commonCertOptions;
    })

    # Настройка nginx + acme для веб-доступа
    (lib.mkIf (cfg.enable && cfgNginx.enable) {
      services.nginx.virtualHosts."${cfg.host}" = {
        enableACME = cfgAcme.enable;
        forceSSL = cfgAcme.enable;
        locations."/" = {
          proxyPass = "http://127.0.0.1:9090";
          proxyWebsockets = true;
          recommendedProxySettings = true;
        };
      };
    })
  ];
}
