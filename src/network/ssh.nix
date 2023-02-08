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
      openFirewall = true;
      ports = [22];
      settings = {
        PermitRootLogin = lib.mkForce "no";
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
      };
    };
  };
}
