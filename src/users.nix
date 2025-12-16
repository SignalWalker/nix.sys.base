{
  config,
  pkgs,
  lib,
  ...
}:
{
  config = {

    # systemd.sysusers = {
    #   enable = true;
    # };

    users = {
      mutableUsers = true;
      users.root.openssh.authorizedKeys.keys = config.users.users.ash.openssh.authorizedKeys.keys;
      users.ash = {
        description = "Ash Walker";
        isNormalUser = true;
        extraGroups = [
          "wheel"
          "input"
          "uinput"
          "video"
          "audio"
          "libvirtd"
          "wireshark"
          "networkmanager"
          "gamemode"
        ];
        shell = pkgs.zsh;
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJFqg4NlJu7u1pcCel3EZshVwUxIfwpsh2fxhaQlLAar ash@ashwalker.net"
        ];
      };
    };
    home-manager = {
      useUserPackages = true;
      useGlobalPkgs = lib.mkDefault true;
    };
  };
}
