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
    boot.supportedFilesystems = ["zfs"];
    boot.zfs = {
      # package = if config.boot.zfs.enableUnstable then config.boot.kernelPackages.zfsUnstable else config.boot.kernelPackages.zfs;
      enableUnstable = true;
    };
    services.zfs = {
      trim.enable = true;
      autoScrub.enable = true;
    };
  };
}
