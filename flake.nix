{
  description = "Roman-Kvasnikov's NixOS Homelab Configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # proxmox-nixos.url = "github:SaumonNet/proxmox-nixos";

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    alejandra = {
      url = "github:kamadorueda/alejandra/4.0.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # wallpapers = {
    #   url = "github:roman-kvasnikov/wallpapers";
    #   flake = false;
    # };
  };

  outputs = {
    self,
    nixpkgs,
    ...
  } @ inputs: let
    system = "x86_64-linux";
    version = "25.05";

    getHostConfig = hostname:
      nixpkgs.lib.nixosSystem {
        inherit system;

        specialArgs = {inherit inputs hostname version;};

        modules = [
          ./hosts/${hostname}/configuration.nix
          inputs.agenix.nixosModules.default
          # inputs.proxmox-nixos.nixosModules.proxmox-ve
        ];
      };
  in {
    nixosConfigurations.homelab-xiaomi = getHostConfig "homelab-xiaomi";
    nixosConfigurations.homelab-pc = getHostConfig "homelab-pc";
    nixosConfigurations.homelab-backup = getHostConfig "homelab-backup";
    nixosConfigurations.homelab-test = getHostConfig "homelab-test";
  };
}
