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
      vim
      wget
      neovim
      git
    ];

    i18n.defaultLocale = lib.mkDefault "en_US.UTF-8";
    time.timeZone = lib.mkDefault "America/NewYork";

    programs.mtr.enable = true;
    programs.gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };

    hardware.enableAllFirmware = lib.mkDefault true;

    system.stateVersion = "22.11";
  };
}
