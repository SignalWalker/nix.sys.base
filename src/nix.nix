{
  config,
  pkgs,
  lib,
  ...
}:
with builtins;
let
  std = pkgs.lib;
  nix = config.nix;
in
{
  options = with lib; { };
  imports = [ ];
  config = {
    nixpkgs = {
      config = {
        allowUnfree = true;
        allowUnfreePredicate = pkg: true;
      };
    };
    nix = {
      enable = true;
      gc = {
        automatic = lib.mkDefault true;
        dates = "weekly";
        options = "--delete-older-than 7d";
      };
      optimise = {
        automatic = true;
      };
      settings = {
        auto-optimise-store = true;
        allowed-users = [ "@wheel" ];
        trusted-users = [
          "root"
          "@wheel"
        ] ++ (std.optional config.nix.sshServe.write "nix-ssh");
        experimental-features =
          [
            "nix-command"
            "flakes"
            # "ca-derivations"
            "fetch-closure"
            "auto-allocate-uids"
            "cgroups"
          ]
          ++ (std.optionals (nix.package.version < "2.19") [
            "repl-flake"
          ]);
        builders-use-substitutes = true;
        commit-lockfile-summary = "build(nix): update flake.lock";
        max-jobs = "auto";
        cores = 0;
        substitute = true;
        download-attempts = 12;
        auto-allocate-uids = true;
        use-cgroups = true;
        use-xdg-base-directories = true;
        substituters = [
          "https://cache.nixos.org"
          "https://cache.ngi0.nixos.org"
          "https://nix-community.cachix.org"
          "https://nixpkgs-wayland.cachix.org"
          "https://cache.lix.systems"
        ];
        trusted-public-keys = [
          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
          "cache.ngi0.nixos.org-1:KqH5CBLNSyX184S9BKZJo1LxrxJ9ltnY2uAs5c/f1MA="
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          "nixpkgs-wayland.cachix.org-1:3lwxaILxMRkVhehr5StQprHdEo4IrE8sRho9R9HOLYA="
          "cache.lix.systems:aBnZUw8zA7H35Cz2RyKFVs3H4PlGTLawyY5KRbvJR8o="
        ];
      };
    };
  };
}
