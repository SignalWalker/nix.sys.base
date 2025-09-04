{
  description = "NixOS configuration - base";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
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
    # nix-mineral = {
    #   url = "github:cynicsketch/nix-mineral";
    #   flake = false;
    # };
  };
  outputs =
    inputs@{
      self,
      nixpkgs,
      ...
    }:
    with builtins;
    let
      std = nixpkgs.lib;
      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-darwin"
        "x86_64-linux"
      ];
      nixpkgsFor = std.genAttrs systems (
        system:
        import nixpkgs {
          localSystem = builtins.currentSystem or system;
          crossSystem = system;
          overlays = [ ];
        }
      );
    in
    {
      formatter = std.mapAttrs (system: pkgs: pkgs.nixfmt-rfc-style) nixpkgsFor;
      nixosModules.default =
        { ... }:
        {
          imports = [
            inputs.home-manager.nixosModules.default
            inputs.nginx-vhost-defaults.nixosModules.default
            inputs.wireguard-networks.nixosModules.default
            # inputs.kmonad.nixosModules.default
            # "${inputs.nix-mineral}/nix-mineral.nix"
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
