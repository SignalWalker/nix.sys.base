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
    boot.supportedFilesystems = [ "zfs" ];
    boot.zfs = {
      devNodes = {};
      enableUnstable = true;
    };
    services.zfs = {
      trim.enable = true;
      autoScrub.enable = true;
    };
  };
}
