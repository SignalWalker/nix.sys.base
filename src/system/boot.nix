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
      initrd.network = {
        enable = false;
        ssh = {
          enable = true;
          authorizedKeys = config.users.users.root.openssh.authorizedKeys.keys;
          port = lib.mkDefault (head config.services.openssh.ports);
        };
      };
    };
  };
}
