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
    users = {
      mutableUsers = true;
      users.root.openssh.authorizedKeys.keys = config.users.users.ash.openssh.authorizedKeys.keys;
      users.ash = {
        description = "Ash Walker";
        isNormalUser = true;
        extraGroups = ["wheel" "input" "uinput" "video" "audio"];
        initialHashedPassword = "$6$UFCYdGnEK.SuHT/1$1vKaVIOkFctztOqSSM8horoFeuIY0vgveTGetLQlX9a1/LpITcqhQWPvkhGS19aAe/O/O1872hN7E5ILIxctt.";
        shell = pkgs.zsh;
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJFqg4NlJu7u1pcCel3EZshVwUxIfwpsh2fxhaQlLAar ash@ashwalker.net"
        ];
      };
    };
    home-manager.users.ash = {...}: {
      # dependency modules added by nix.home.lib; no need for configuration here
    };
  };
}
