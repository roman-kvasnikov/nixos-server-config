{
  description = "Roman-Kvasnikov's NixOS Homelab Configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

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
        ];
      };
  in {
    nixosConfigurations.homelab = getHostConfig "homelab";
    nixosConfigurations.homelab-pc = getHostConfig "homelab-pc";
    nixosConfigurations.homelab-backup = getHostConfig "homelab-backup";
  };
}
