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
    ipv6address = mkOpt str "***REMOVED_IPv6***" "IPv6 address of the container.";
  };

  config = mkIf cfg.enable {

    # Entry for the main reverse proxy
    schallernetz.services.haproxy.frontends.www.extraConfig = [ "use_backend ${cfg.name} if { req.hdr(host) -i ${cfg.name}.${config.networking.domain} }" ];
    services.haproxy.config = mkAfter ''
      backend ${cfg.name}
        server _0 [${cfg.ipv6address}]:80 maxconn 32 check
    '';

    #$ sudo nixos-container start ntfy
    #$ sudo nixos-container root-login ntfy
    containers.${cfg.name} = {
      autoStart = true;

      privateNetwork = true;
      hostBridge = "br0";
      localAddress = "***REMOVED_IPv4***/23";
      localAddress6 = "${cfg.ipv6address}/64";

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
  };
}
