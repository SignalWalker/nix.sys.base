{
  config,
  lib,
  ...
}:
let
  zfs = config.zfs-root;
in
{
  config = lib.mkIf zfs.boot.enable {
    boot.supportedFilesystems = [
      "zfs"
    ];
    # nixpkgs.config.packageOverrides = pkgs: {
    #   zfs = config.boot.kernelPackages.zfs;
    #   zfsStable = config.boot.kernelPackages.zfsStable;
    #   zfsUnstable = config.boot.kernelPackages.zfsUnstable;
    # };
    boot.zfs = {
      forceImportRoot = false; # TODO :: why
      # package = if config.boot.zfs.enableUnstable then config.boot.kernelPackages.zfsUnstable else config.boot.kernelPackages.zfs;
      # enableUnstable = true;
    };
    services.zfs = {
      trim.enable = true;
      autoScrub.enable = true;
    };
  };
}
