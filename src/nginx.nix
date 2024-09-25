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
  disabledModules = [];
  imports = [];
  config = {
    # systemd.services."nginx-generate-selfsigned-key" = {
    #   description = "Generate a self-signed SSL key";
    #   path = with pkgs; [ openssl ];
    #   script = ''
    #
    #   '';
    # };
    services.nginx = {
      virtualHostDefaults = {
        blockAgents = {
          enable = lib.mkDefault true;
          agents = lib.mkOptionDefault [
            "SemrushBot" # fuuuuuuuuck you
            "facebookexternalhit"
            "facebookcatalog"
            "meta-externalagent"
            "meta-externalfetcher"
            "DotBot"
            "Inspici" # fuck you
            "paloaltonetworks.com" # fuck you
            "SummalyBot" # fuck you
            "CensysInspect"
            "AhrefsBot" # doesn't seem to respect robots.txt
            "aiHitBot" # fuck you
          ];
        };
        extraConfig = ''
          if ($good_host != 1) {
            return 444;
          }
        '';
      };
      commonHttpConfig = ''
        map $remote_addr $is_local {
          ~^192.168. 1;
          ~^10. 1;
          ~^172.24.86. 1;
          ~^127. 1;
          "::1" 1;
          default 0;
        }
        map $is_local$http_host $good_host {
          ~^1 1;
          "~^0.*ashwalker\.net" 1;
          default 0;
        }
      '';
      # virtualHosts."ip-addr" = lib.mkIf ((length config.networking.publicAddresses) > 0) {
      #   listenAddresses = ["0.0.0.0" "[::0]"];
      #   default = true;
      #   addSSL = true;
      #   sslCertificate = "/etc/ssl/certs/nginx-selfsigned.crt";
      #   sslCertificateKey = "/etc/ssl/private/nginx-selfsigned.key";
      #   serverName = "\"\"";
      #   serverAliases = config.networking.publicAddresses;
      #   blockAgents.enable = false;
      #   extraConfig = ''
      #     return 444;
      #   '';
      # };
      # appendHttpConfig = ''
      #   server {
      #     listen 0.0.0.0:80 default_server;
      #     listen 0.0.0.0:443 default_server;
      #     listen [::0]:80 default_server;
      #     listen [::0]:443 default_server;
      #     server_name "" ${std.concatStringsSep "\n" config.networking.publicAddresses};
      #     return 444;
      #   }
      # '';
      # virtualHosts."invalid-host" = {
      #   default = true;
      #   listen = [
      #     {
      #       addr = "0.0.0.0";
      #       port = 80;
      #       extraParameters = ["default_server"];
      #     }
      #     {
      #       addr = "0.0.0.0";
      #       port = 443;
      #       ssl = true;
      #       extraParameters = ["default_server"];
      #     }
      #     {
      #       addr = "[::0]";
      #       port = 80;
      #       extraParameters = ["default_server"];
      #     }
      #     {
      #       addr = "[::0]";
      #       port = 443;
      #       ssl = true;
      #       extraParameters = ["default_server"];
      #     }
      #   ];
      #   serverName = "\"\"";
      #   serverAliases = config.networking.publicAddresses;
      #   extraConfig = ''
      #     return 444;
      #   '';
      # };
    };
  };
  meta = {};
}
