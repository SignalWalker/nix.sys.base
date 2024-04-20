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
  config = lib.mkMerge [
    {
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
        };
        optimise = {
          automatic = true;
        };
        settings = {
          auto-optimise-store = true;
          allowed-users = ["@wheel"];
          trusted-users = ["root" "@wheel"] ++ (std.optional config.nix.sshServe.write "nix-ssh");
          experimental-features = ["nix-command" "flakes" "ca-derivations" "fetch-closure" "repl-flake" "auto-allocate-uids" "cgroups"];
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
          ];
          trusted-public-keys = [
            "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
            "cache.ngi0.nixos.org-1:KqH5CBLNSyX184S9BKZJo1LxrxJ9ltnY2uAs5c/f1MA="
            "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
            "nixpkgs-wayland.cachix.org-1:3lwxaILxMRkVhehr5StQprHdEo4IrE8sRho9R9HOLYA="
          ];
        };
        sshServe = {
          enable = true;
          keys = config.users.users.ash.openssh.authorizedKeys.keys;
          protocol = "ssh-ng";
        };
      };

      # systemd.timers."nix-wipe-history" = {
      #   wantedBy = ["timers.target"];
      #   timerConfig = {
      #     OnCalendar = "daily";
      #     Persistent = true;
      #     RandomizedDelaySec = "1h";
      #     Unit = "nix-wipe-history.service";
      #   };
      # };

      systemd.services."nix-wipe-history" = {
        script = ''
          set -eu
          ${config.nix.package}/bin/nix profile wipe-history --profile /nix/var/nix/profiles/system --older-than 7d
        '';
        wantedBy = ["nix-gc.service"];
        before = ["nix-gc.service"];
        serviceConfig = {
          Type = "oneshot";
          User = "root";
        };
      };
    }

    (lib.mkIf (config.networking.hostName != "terra") {
      nix.settings = {
        substituters = [
          "ssh://terra.ashwalker.net"
        ];
        trusted-public-keys = [
          "terra.ashwalker.net-1:36mAK7UNh8BAy5LkvMCtzbWpdfkvmPP6W/PhaidB6bY="
        ];
      };
    })
  ];
}
