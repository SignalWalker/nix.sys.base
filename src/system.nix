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
  imports = lib.signal.fs.path.listFilePaths ./system;
  config = {
    boot.kernelPackages = lib.mkDefault config.boot.zfs.package.latestCompatibleLinuxPackages;
    i18n.defaultLocale = "en_US.UTF-8";
    time.timeZone = lib.mkDefault "America/NewYork";
  };
}
