{
  description = "Roman-Kvasnikov's NixOS Homelab Configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    nixpkgs-25_05.url = "github:NixOS/nixpkgs/nixos-25.05";

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
    nixpkgs-25_05,
    ...
  } @ inputs: let
    hostname = "homelab";
    system = "x86_64-linux";
    version = "25.05";

    pkgs = import nixpkgs {inherit system;};
    stablePkgs = import nixpkgs-25_05 {inherit system;};
  in {
    nixosConfigurations.${hostname} = nixpkgs.lib.nixosSystem {
      inherit system;

      specialArgs = {
        inherit inputs hostname version;
      };

      modules = [
        ./hosts/${hostname}/configuration.nix

        {
          environment.systemPackages = [
            stablePkgs.mdadm
          ];
        }
      ];
    };
  };
}
