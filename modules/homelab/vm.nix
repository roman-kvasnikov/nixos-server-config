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

    users.users.${cfgHomelab.adminUser}.extraGroups = ["libvirtd" "kvm"];
  };
}
