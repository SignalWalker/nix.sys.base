{
  config,
  lib,
  ...
}:
{
  config = {
    boot = {
      supportedFilesystems = {
        "f2fs" = true;
        "btrfs" = true;
      };
      tmp = {
        cleanOnBoot = true;
        useTmpfs = true;
      };
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
          port = lib.mkDefault (builtins.head config.services.openssh.ports);
        };
      };
    };
  };
}
