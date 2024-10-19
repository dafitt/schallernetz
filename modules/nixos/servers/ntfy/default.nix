{ options, config, lib, pkgs, ... }:

with lib;
with lib.schallernetz;
let
  cfg = config.schallernetz.servers.ntfy;
in
{
  options.schallernetz.servers.ntfy = with types; {
    enable = mkBoolOpt false "Enable server ntfy.";
    name = mkOpt str "ntfy" "The name of the server.";

    subnet = mkOpt str "server" "The name of the subnet which the container should be part of.";
    ip6HostAddress = mkOpt str ":e73" "The ipv6's host part.";
    ip6Address = mkOpt str "${config.schallernetz.networking.subnets.${cfg.subnet}.uniqueLocal.prefix}:${cfg.ip6HostAddress}" "Full IPv6 address of the container.";
  };

  config = mkMerge [
    (mkIf cfg.enable {
      #$ sudo nixos-container start ntfy
      #$ sudo nixos-container root-login ntfy
      containers.${cfg.name} = {
        autoStart = true;

        privateNetwork = true;
        hostBridge = cfg.subnet;
        localAddress6 = "${cfg.ip6Address}/64";

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
      schallernetz.servers.haproxy-server = {
        frontends.www.extraConfig = [
          "use_backend ${cfg.name} if { req.hdr(host) -i ${cfg.name}.lan.${config.networking.domain} }"
        ];
        backends.extraConfig = [
          ''
            backend ${cfg.name}
              mode http
              server _0 [${cfg.ip6Address}]:80 maxconn 32 check
          ''
        ];
      };
      schallernetz.servers.unbound.extraAuthZoneRecords = [
        "${cfg.name} IN CNAME ${config.schallernetz.servers.haproxy-server.name}"
      ];
    }
  ];
}
