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
    # nix = {
    #   url = github:nixos/nix?;
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
    # sysCfg = {
    #   url = path:/etc/nixos;
    #   flake = false;
    # };
    nixos-generators = {
      url = github:nix-community/nixos-generators;
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = inputs @ {
    self,
    nixpkgs,
    nixos-generators,
    ...
  }:
    with builtins; let
      std = nixpkgs.lib;
      hlib = inputs.homelib.lib;
      home = hlib.home;
      signal = hlib.signal;
      sys = hlib.sys;
      self' = signal.flake.resolve {
        flake = self;
        name = "sys.base";
      };
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
          nixosModules = {modulesPath, ...}: {
            imports = [./nixos-module.nix];
          };
        };
      };
      nixosConfigurations = sys.configuration.fromFlake {
        flake = self';
        flakeName = "sys.base";
        hostNameMap = {__default = "ash-base";};
        # extraModules =
        #   [
        #     ({modulesPath, ...}: {
        #       imports = [(modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix")];
        #       config = {
        #         networking.hostId = "30c6ccf0";
        #       };
        #     })
        #   ];
        # ++ hlib.fs.path.listFilePaths inputs.sysCfg;
      };
      packages = std.genAttrs ["x86_64-linux"] (system:
        foldl' (res: name: let
          cfg = self.nixosConfigurations.${name};
        in
          res
          // {
            ${name} = cfg.config.system.build.toplevel;
            "${name}-manual" = cfg.config.system.build.manual.manualHTML;
            "${name}-initrd" = cfg.config.system.build.initialRamdisk;
            "${name}-kernel" = cfg.config.system.build.kernel;
            "${name}-iso" = nixos-generators.nixosGenerate {
              format = "iso";
              pkgs = cfg.pkgs;
              modules = self'.nixosModules.default;
            };
            "${name}-vm" = cfg.config.system.build.vm;
          }) {} (attrNames self.nixosConfigurations));
      apps = mapAttrs (system: packages: let
        pkgs = import nixpkgs {
          localSystem = builtins.currentSystem or system;
          crossSystem = system;
          overlays = [];
        };
      in
        foldl' (res: name: {
          "${name}-qemu" = {
            type = "app";
            program = let
              script = pkgs.writeScript "${name}-qemu" ''
                #! /usr/bin/env sh
                ${pkgs.qemu}/bin/qemu-system-x86_64 -kernel ${packages."${name}-kernel"}/bzImage -initrd ${packages."${name}-initrd"}/initrd -hda /dev/null
              '';
            in "${script}";
          };
        }) {} (attrNames self.nixosConfigurations))
      self.packages;
    };
}
