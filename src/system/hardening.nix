{
  config,
  pkgs,
  lib,
  ...
}:
with builtins;
{
  options = with lib; { };
  disabledModules = [ ];
  imports = [ ];
  config = {
    # nix-mineral = {
    #   enable = false; # TODO :: enable
    #   # overrides = {
    #   #   compatibility = {
    #   #     io-uring.enable = true;
    #   #   };
    #   # };
    # };
  };
  meta = { };
}
