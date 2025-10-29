{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.homelab.services.vmctl;
  cfgHomelab = config.homelab;
in {
  options.homelab.services.vmctl = {
    enable = lib.mkEnableOption "Enable virtual machine management";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      virt-manager
      qemu_kvm
      libvirt
      virt-top
    ];

    virtualisation.libvirtd = {
      enable = true;

      qemu = {
        package = pkgs.qemu_kvm;
        runAsRoot = false;
      };
    };

    networking = {
      # выключаем получение IP на физическом интерфейсе напрямую
      interfaces.wlp3s0.useDHCP = false;

      # создаём мост
      bridges.br0.interfaces = ["wlp3s0"];
      interfaces.br0.useDHCP = true; # получаем IP для самого хоста
    };

    virtualisation.libvirtd.networks.br0-net = {
      forwardMode = "bridge";
      bridgeName = "br0";
      autostart = true;
    };

    users.users.${cfgHomelab.adminUser}.extraGroups = ["libvirtd" "kvm"];
  };
}
