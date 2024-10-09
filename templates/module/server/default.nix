{ options, config, lib, pkgs, ... }:

with lib;
with lib.schallernetz;
let
  cfg = config.schallernetz.servers.MYSERVER;
in
{
  options.schallernetz.servers.MYSERVER = with types; {
    enable = mkBoolOpt false "Enable server MYSERVER.";
    name = mkOpt str "MYSERVER" "The name of the server.";

    subnet = mkOpt str "" "The name of the subnet which the container should be part of.";
    ip6Host = mkOpt str "" "The ipv6's host part.";
    ip6Address = mkOpt str "${config.schallernetz.networking.subnets.${cfg.subnet}.uniqueLocal.prefix}:${cfg.ip6Host}" "Full IPv6 address of the container.";
  };

  config = mkMerge [
    (mkIf cfg.enable {
      # Server as a container. Advanages:
      # - Every server has its own IP
      # - Processes are sealed off from the host system
      # - Can always be started and stopped

      #$ sudo nixos-container start MYSERVER
      #$ sudo nixos-container root-login MYSERVER
      containers.${cfg.name} = {
        autoStart = true;

        privateNetwork = true;
        hostBridge = cfg.subnet;
        localAddress6 = "${cfg.ip6Address}/64";

        specialArgs = { hostConfig = config; };
        config = { hostConfig, config, lib, pkgs, ... }: {
          # here comes the server's configuration

          system.stateVersion = hostConfig.system.stateVersion;
        };
      };
    })
    # The following configuration will be applied at every build on every system.
    # This has the advantage that you can distribute your servers across several hosts.
    {
      # An entry in the main reverse proxy?
      schallernetz.servers.haproxy = {
        frontends.www.extraConfig = [
          "use_backend ${cfg.name} if { req.hdr(host) -i ${cfg.name}.${config.networking.domain} }"
          "use_backend ${cfg.name} if { req.hdr(host) -i ${cfg.name}.lan.${config.networking.domain} }"
        ];
        backends.extraConfig = [
          ''
            backend ${cfg.name}
              mode http
              server _0 [${cfg.ip6Address}]:8000 maxconn 32 check
          ''
        ];
      };
      # Mabe also dns entries?
      schallernetz.servers.unbound.extraAuthZoneRecords = [
        "${cfg.name} IN AAAA ${cfg.ip6Address}"
        "${cfg.name} IN CNAME ${config.schallernetz.servers.haproxy.name}"
      ];
      # Open port(s) in the main network firewall for this server?
      schallernetz.networking.subnets.${cfg.subnet}.nfrules_in = [
        "iifname lan ip6 daddr ${cfg.ip6Address} tcp dport 443 limit rate 70/second accept"
        "ip6 daddr & ***REMOVED_IPv6*** == :${cfg.ip6Host} tcp dport 443 limit rate 70/second accept"
      ];
    }
  ];
}

# Don't forget to add `schallernetz.servers.MYSERVER.enable = true;` to the hosts configuration!
