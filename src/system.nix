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
    i18n.defaultLocale = "en_US.UTF-8";
    time.timeZone = lib.mkDefault "America/NewYork";
    programs.mtr.enable = true;
    programs.gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
    system.stateVersion = "22.11";
  };
}
