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
      inputs.home-manager.follows = "home-manager";
    };
    homebase = {
      url = github:signalwalker/nix.home.base;
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.alejandra.follows = "alejandra";
      inputs.homelib.follows = "homelib";
      inputs.home-manager.follows = "home-manager";
    };
    home-manager = {
      url = github:nix-community/home-manager;
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix = {
      url = github:nixos/nix;
      inputs.nixpkgs.follows = "nixpkgs";
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
              overlays = ["default"];
              nixosModules = ["default"];
            };
            home-manager = {
              overlays = ["default"];
              nixosModules = ["default"];
            };
          };
        };
        outputs = dependencies: {
          nixosModules = {...}: {
            imports = [./nixos-module.nix];
          };
        };
      };
    };
}
