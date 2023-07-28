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
    environment.systemPackages = with pkgs; [
      neovim
      wget
      git
      parted
      usbutils
      pciutils
      lshw
      dmidecode
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
  };
}
