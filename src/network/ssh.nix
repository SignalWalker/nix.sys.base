{
  lib,
  ...
}:
{
  config = {
    services.openssh = {
      enable = lib.mkDefault true;
      openFirewall = lib.mkForce false; # forced to only work over wireguard
      ports = [ 22 ];
      settings = {
        PermitRootLogin = "prohibit-password";
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        # required for things like XDG_RUNTIME_DIR
        UsePAM = true;
      };
    };
  };
}
