{
  description = "NixOS configuration - base";
  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs/nixpkgs-unstable;
    alejandra = {
      url = github:kamadorueda/alejandra;
      inputs.nixpkgs.follows = "nixpkgs";
    };
    homelib = {
      url = github:signalwalker/nix.home.lib;
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.alejandra.follows = "alejandra";
    };
    homebase = {
      url = github:signalwalker/nix.home.base;
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.alejandra.follows = "alejandra";
      inputs.homelib.follows = "homelib";
    };
    # keyboard
    kmonad = {
      url = github:kmonad/kmonad?dir=nix;
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = inputs @ {
    self,
    nixpkgs,
    ...
  }:
    with builtins; let
      std = nixpkgs.lib;
      hlib = inputs.homelib.lib;
      home = hlib.home;
      signal = hlib.signal;
      sys = hlib.sys;
    in {
      formatter = std.mapAttrs (system: pkgs: pkgs.default) inputs.alejandra.packages;
      signalModules.default = {
        name = "sys.base.default";
        dependencies = signal.flake.set.toDependencies {
          flakes = inputs;
          filter = [];
          outputs = {
            kmonad = {
              overlays = [ "default" ];
              nixosModules = [ "default" ];
            };
          };
        };
        outputs = dependencies: {
          nixosModules = { ... }: {
            imports = [ ./nixos-module.nix ];
          };
        };
      };
    };
}
