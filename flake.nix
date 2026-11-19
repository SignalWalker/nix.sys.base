{
  description = "NixOS configuration - base";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      # NOTE :: see `lib` section in https://flake.parts/module-arguments.html
      inputs.nixpkgs-lib.follows = "nixpkgs";
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
    # nix-mineral = {
    #   url = "github:cynicsketch/nix-mineral";
    #   flake = false;
    # };
  };
  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } (
      top@{
        self,
        ...
      }:
      {

        flake = {
      nixosModules = {
        zfsRoot = import ./mod/zfs.nix;
        kernel = import ./mod/kernel.nix;
        default =
        { ... }:
        {
          imports = [
            inputs.home-manager.nixosModules.default
            inputs.nginx-vhost-defaults.nixosModules.default
            inputs.wireguard-networks.nixosModules.default

            self.nixosModules.kernel

            ./nixos-module.nix
          ];
        };
      };
        };
        systems = [ "x86_64-linux" ];
        perSystem =
          { self', pkgs, ... }:
          {
            formatter = pkgs.nixfmt;
            devShells.default = pkgs.mkShell {
              packages = [ self'.formatter ];
            };
          };
      }
    );
}
