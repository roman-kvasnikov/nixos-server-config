{
  description = "Roman-Kvasnikov's NixOS Home Server Configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
  };

  outputs = {
    self,
    nixpkgs,
    ...
  } @ inputs: let
    hostname = "home-server";
    system = "x86_64-linux";
    version = "25.05";
  in {
    nixosConfigurations = nixpkgs.lib.nixosSystem {
      inherit system version;

      specialArgs = {
        inherit inputs hostname version;
      };

      modules = [
        ./hosts/${hostname}/configuration.nix
      ];
    };
  };
}
