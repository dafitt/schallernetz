{ options, config, lib, pkgs, ... }:

with lib;
with lib.schallernetz;
let
  cfg = config.schallernetz.containers.ntfy;
in
{
  options.schallernetz.containers.ntfy = with types; {
    enable = mkBoolOpt false "Enable container ntfy.";
    name = mkOpt str "ntfy" "The name of the container.";
    ipv6Address = mkOpt str "${config.schallernetz.networking.uniqueLocalPrefix}***REMOVED_IPv6***" "IPv6 address of the container.";
  };

  config = mkMerge [
    (mkIf cfg.enable {
      #$ sudo nixos-container start ntfy
      #$ sudo nixos-container root-login ntfy
      containers.${cfg.name} = {
        autoStart = true;

        privateNetwork = true;
        hostBridge = "br_lan";
        localAddress = "***REMOVED_IPv4***/23";
        localAddress6 = "${cfg.ipv6Address}/64";

        specialArgs = { hostConfig = config; };
        config = { hostConfig, config, lib, pkgs, ... }: {

          # https://docs.ntfy.sh/config/
          services.ntfy-sh = {
            enable = true;

            settings = {
              base-url = "https://${cfg.name}.${hostConfig.networking.domain}";
              listen-http = ":80";
              behind-proxy = true;
            };
          };

          networking.firewall.interfaces."eth0" = {
            allowedTCPPorts = [ 80 ];
          };

          system.stateVersion = hostConfig.system.stateVersion;
        };
      };
    })
    {
      # entry in main reverse proxy
      schallernetz.containers.haproxy = {
        frontends.www.extraConfig = [ "use_backend ${cfg.name} if { req.hdr(host) -i ${cfg.name}.${config.networking.domain} }" ];
        backends.extraConfig = [
          ''
            backend ${cfg.name}
              mode http
              server _0 [${cfg.ipv6Address}]:80 maxconn 32 check
          ''
        ];
      };
    }
  ];
}
