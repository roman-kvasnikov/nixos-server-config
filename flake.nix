{
  description = "Roman-Kvasnikov's NixOS Homelab Configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
  };

  outputs = {
    self,
    nixpkgs,
    ...
  } @ inputs: let
    hostname = "homelab";
    system = "x86_64-linux";
    version = "25.05";
  in {
    nixosConfigurations.${hostname} = nixpkgs.lib.nixosSystem {
      inherit system;

      specialArgs = {
        inherit inputs hostname version;
      };

      modules = [
        ./hosts/${hostname}/configuration.nix
      ];
    };
  };
}
