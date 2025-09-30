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
  in {
    nixosConfigurations = {
      ${hostname} = nixpkgs.lib.nixosSystem {
        inherit system;

        specialArgs = {
          inherit inputs hostname;
        };

        modules = [
          ./hosts/${hostname}/configuration.nix
        ];
      };
    };
  };
}
