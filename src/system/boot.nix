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
        };
      };
      loader = {
        efi.efiSysMountPoint = "/boot/efi";
        efi.canTouchEfiVariables = lib.mkDefault true;
        generationsDir.copyKernels = true;
        grub = {
          enable = lib.mkDefault (!config.boot.loader.systemd-boot.enable);
          useOSProber = true;
          zfsSupport = true;
          version = 2;
          copyKernels = true;
          efiSupport = true;
          default = "saved";
          efiInstallAsRemovable = !config.boot.loader.efi.canTouchEfiVariables;
          theme = pkgs.nixos-grub2-theme;
        };
      };
    };
  };
}
