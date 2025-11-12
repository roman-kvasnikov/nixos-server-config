{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = ["ahci" "xhci_pci" "usbhid" "usb_storage" "sd_mod"];
  boot.kernelModules = ["kvm-intel"];
  boot.extraModulePackages = [];

  boot.swraid = {
    enable = true;
    mdadmConf = ''
      ARRAY /dev/md0 level=raid0 num-devices=2 metadata=1.2 name=myraid0 UUID=14e379fc:2b19eb9d:f40ff21c:7205cb6f
    '';
  };

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/090e90cd-32c7-469d-b381-828783b994f6";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/D0C0-CAE0";
    fsType = "vfat";
    options = ["fmask=0022" "dmask=0022"];
  };

  # fileSystems."/raid" = {
  #   device = "/dev/disk/by-uuid/c60f6a98-d29b-4594-a8c0-ecfe6e387a16";
  #   fsType = "ext4";
  # };

  # fileSystems."/var" = {
  #   device = "/raid/var";
  #   fsType = "none";
  #   options = ["bind" "x-systemd.after=raid.mount"];
  #   depends = ["/raid"];
  # };

  # fileSystems."/data" = {
  #   device = "/raid/data";
  #   fsType = "none";
  #   options = ["bind" "x-systemd.after=raid.mount"];
  #   depends = ["/raid"];
  # };

  # fileSystems."/var" = {
  #   device = "/dev/md0";
  #   fsType = "ext4";
  #   options = ["defaults" "noatime"];
  #   neededForBoot = true;
  # };

  # fileSystems."/data" = {
  #   device = "/dev/md0";
  #   fsType = "ext4";
  #   options = ["defaults" "noatime"];
  #   # neededForBoot = false;
  # };

  swapDevices = [
    {device = "/dev/disk/by-uuid/eac00cda-2583-42fd-b517-d6cc89d96a85";}
  ];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp1s0.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp2s0.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
