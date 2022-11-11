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
  imports = lib.signal.fs.path.listFilePaths ./network;
  config = {
    systemd.network = {
      enable = true;
    };
  };
}
