{
  config,
  pkgs,
  lib,
  ...
}:
with builtins; let
  std = pkgs.lib;
  wg = config.networking.wireguard;
  peers = config.signal.remoteMachines;
in {
  options = with lib; {};
  imports = [];
  config = {
    environment.systemPackages = with pkgs; [wireguard-tools];

    age.secrets = {
      gossipSecret.file = ./wireguard/gossipSecret.age;
    };

    services.wgautomesh = {
      enable = true;
      gossipSecretFile = config.age.secrets.gossipSecret.path;
      settings = {
        gossip_port = 1666;
        interface = "wg-signal";
        peers =
          map (peer: {
            address = (head peer.wireguard.addresses).address;
            endpoint = peer.wireguard.endpoint;
            pubkey = peer.wireguard.publicKey;
          })
          peers;
      };
    };
  };
}
