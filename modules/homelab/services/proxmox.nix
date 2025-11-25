{
  inputs,
  config,
  lib,
  cfgHomelab,
  ...
}: let
  cfg = config.homelab.services.proxmox-ctl;
in {
  options.homelab.services.proxmox-ctl = {
    enable = lib.mkEnableOption "Enable Proxmox VE";

    homepage = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = cfg.enable;
      };
      name = lib.mkOption {
        type = lib.types.str;
        default = "Proxmox VE";
      };
      description = lib.mkOption {
        type = lib.types.str;
        default = "Proxmox VE is a virtual machine manager";
      };
      icon = lib.mkOption {
        type = lib.types.str;
        default = "proxmox.png";
      };
      category = lib.mkOption {
        type = lib.types.str;
        default = "Services";
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      services.proxmox-ve = {
        enable = true;

        ipAddress = "192.168.1.15";

        bridges = ["vmbr0"];
      };

      nixpkgs.overlays = [
        # inputs.proxmox-nixos.overlays.${system}
        inputs.proxmox-nixos.overlays.x86_64-linux
      ];

      networking.bridges.vmbr0.interfaces = [cfgHomelab.interface];
      networking.interfaces.vmbr0.useDHCP = lib.mkDefault true;
    })
  ];
}
