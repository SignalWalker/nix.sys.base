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
    services.openssh = {
      enable = lib.mkDefault true;
      permitRootLogin = lib.mkForce "no";
      passwordAuthentication = false;
      openFirewall = false;
      kbdInteractiveAuthentication = false;
    };
  };
}
