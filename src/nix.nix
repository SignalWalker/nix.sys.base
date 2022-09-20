{
  config,
  pkgs,
  lib,
  ...
}:
with builtins; let
  std = pkgs.lib;
in {
  options = with lib; {};
  imports = [];
  config = {
    nix = {
      enable = true;
      gc.automatic = true;
      gc.dates = "weekly";
      optimise.automatic = true;
      settings = {
        auto-optimise-store = true;
        allowed-users = ["@wheel"];
        trusted-users = ["root" "@wheel"];
        experimental-features = ["nix-command" "flakes" "ca-derivations" "fetch-closure" "repl-flakes"];
        builders-use-substitutes = true;
        commit-lockfile-summary = "chore: update flake.lock";
        max-jobs = "auto";
        cores = 0;
        substitute = true;
        download-attempts = 12;
        substituters = [
          "https://cache.nixos.org/"
          "https://hydra.nixos.org/"
          "https://cache.ngi0.nixos.org/"
          "https://nix-community.cachix.org/"
        ];
        trusted-public-keys = [
          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
          "cache.ngi0.nixos.org-1:KqH5CBLNSyX184S9BKZJo1LxrxJ9ltnY2uAs5c/f1MA="
          "hydra.nixos.org-1:CNHJZBh9K4tP3EKF6FkkgeVYsS3ohTl+oS0Qa8bezVs="
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        ];
      };
      sshServe = {
        enable = true;
        keys = config.users.users.ash.openssh.authorizedKeys.keys;
      };
    };
  };
}
