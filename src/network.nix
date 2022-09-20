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
  imports = lib.signal.fs.path.listFilePaths ./network;
  config = {
    services.openssh = {
      enable = lib.mkDefault true;
      ports = [ 22 ];
    };
    systemd.network = {
      enable = true;
    };
  };
}
