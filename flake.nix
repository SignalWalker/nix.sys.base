{
  description = "NixOS configuration - base";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    alejandra = {
      url = "github:kamadorueda/alejandra";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nginx-vhost-defaults = {
      url = "github:SignalWalker/nix.nginx.vhost-defaults";
    };
    wireguard-networks = {
      url = "github:SignalWalker/nix.net.wireguard";
    };
  };
  outputs = inputs @ {
    self,
    nixpkgs,
    ...
  }:
    with builtins; let
      std = nixpkgs.lib;
    in {
      formatter = std.mapAttrs (system: pkgs: pkgs.default) inputs.alejandra.packages;
      nixosModules.default = {...}: {
        imports = [
          inputs.home-manager.nixosModules.default
          inputs.nginx-vhost-defaults.nixosModules.default
          inputs.wireguard-networks.nixosModules.default
          # inputs.kmonad.nixosModules.default
          ./nixos-module.nix
        ];
        config = {
          nixpkgs.overlays = [
            # inputs.kmonad.overlays.default
            # inputs.home-manager.overlays.default
          ];
        };
      };
    };
}
