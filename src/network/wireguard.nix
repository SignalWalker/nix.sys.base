{
  config,
  pkgs,
  ...
}:
let
  inherit (builtins) head map;
  peers = config.signal.remoteMachines;
in
{
  config = {
    environment.systemPackages = [ pkgs.wireguard-tools ];

    age.secrets = {
      gossipSecret.file = ./wireguard/gossipSecret.age;
    };

    services.wgautomesh = {
      enable = true;
      gossipSecretFile = config.age.secrets.gossipSecret.path;
      logLevel = "debug";
      settings = {
        gossip_port = 1666;
        interface = "wg-signal";
        peers = map (peer: {
          address = (head peer.wireguard.addresses).address;
          endpoint = peer.wireguard.endpoint;
          pubkey = peer.wireguard.publicKey;
        }) peers;
      };
    };
  };
}
