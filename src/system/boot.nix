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
    boot = {
      loader.systemd-boot = {
        editor = false;
        memtest86 = {
          enable = config.nixpkgs.config.allowUnfree;
        };
      };
      initrd.network = {
        ssh = {
          enable = true;
          authorizedKeys = config.users.users.root.openssh.authorizedKeys.keys;
          port = lib.mkDefault (head config.services.openssh.ports);
        };
      };
    };
  };
}
