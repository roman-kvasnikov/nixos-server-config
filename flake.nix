{
  description = "Roman-Kvasnikov's NixOS Homelab Configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # nixpkgs-25_05.url = "github:NixOS/nixpkgs/nixos-25.05";

    agenix = {
      url = "github:ryantm/agenix";
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
    hostname = "homelab";
    version = "25.05";
  in {
    nixosConfigurations.${hostname} = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";

      specialArgs = {
        inherit inputs hostname version;
      };

      modules = [
        ./hosts/${hostname}/configuration.nix
      ];
    };
  };
}
