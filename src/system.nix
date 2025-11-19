{
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = lib.listFilePaths ./system;
  config = {
    environment.systemPackages = [
      # basic utilities
      pkgs.neovim
      pkgs.wget
      pkgs.git
      # filesystem
      pkgs.parted
      # hardware info
      pkgs.usbutils
      pkgs.pciutils
      pkgs.lshw
      pkgs.dmidecode
      # debugging
      pkgs.strace
      pkgs.lsof
    ];

    programs.zsh = {
      enable = true;
      # called from within ~/.config/zsh/.zshrc
      enableGlobalCompInit = false;
    };

    i18n.defaultLocale = lib.mkDefault "en_US.UTF-8";
    time.timeZone = lib.mkDefault "America/New_York";

    programs.mtr.enable = true;
    programs.gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };

    hardware.enableAllFirmware = lib.mkDefault config.nixpkgs.config.allowUnfree;
    hardware.enableRedistributableFirmware = lib.mkDefault true;

    system.stateVersion = "22.11";

    systemd.oomd = {
      enable = true;
      enableRootSlice = false;
      enableSystemSlice = true;
      enableUserSlices = true;
    };
  };
}
