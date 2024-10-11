{ options, config, lib, pkgs, inputs, ... }:

with lib;
with lib.schallernetz;
let
  cfg = config.schallernetz.servers.adguardhome;
in
{
  options.schallernetz.servers.adguardhome = with types; {
    enable = mkBoolOpt false "Enable server adguardhome.";
    name = mkOpt str "adguardhome" "The name of the server.";

    subnet = mkOpt str "server" "The name of the subnet which the container should be part of.";
    ip6HostAddress = mkOpt str ":8" "The ipv6's host part.";
    ip6Address = mkOpt str "${config.schallernetz.networking.subnets.${cfg.subnet}.uniqueLocal.prefix}:${cfg.ip6HostAddress}" "Full IPv6 address of the container.";
  };

  config = mkMerge [
    (mkIf cfg.enable {
      #$ sudo nixos-container start adguardhome
      #$ sudo nixos-container root-login adguardhome
      containers.${cfg.name} = {
        autoStart = true;

        privateNetwork = true;
        hostBridge = cfg.subnet;
        localAddress6 = "${cfg.ip6Address}/64";

        specialArgs = { hostConfig = config; };
        config = { hostConfig, config, lib, pkgs, ... }: {
          imports = with inputs; [ self.nixosModules."ntfy-systemd" ];

          services.adguardhome = {
            enable = true;

            settings = {
              # https://github.com/AdguardTeam/AdGuardHome/wiki/Configuration#configuration-file
              safebrowsing_enabled = true;
              dns = {
                bind_hosts = [ "${cfg.ip6Address}" ];
                enable_dnssec = true;
                upstream_dns = [ hostConfig.schallernetz.servers.unbound.ip6Address ];
              };
              users = [
                { name = "admin"; password = "***REMOVED_HASH***"; }
                { name = "schaller"; password = "***REMOVED_HASH***"; }
              ];
              querylog.interval = "2h";
              statistics.interval = "504h"; # 21d
            };

            port = 3000;
            openFirewall = true;
          };
          systemd.services.adguardhome.unitConfig = {
            OnFailure = [ "ntfy-failure@%i.service" ];
            OnSuccess = [ "ntfy-success@%i.service" ];
          };

          networking.firewall.interfaces."eth0" = {
            allowedTCPPorts = [ 53 ];
            allowedUDPPorts = [ 53 ];
          };

          system.stateVersion = hostConfig.system.stateVersion;
        };
      };
    })
    {
      schallernetz.servers.haproxy = {
        frontends.www.extraConfig = [
          "use_backend ${cfg.name} if { req.hdr(host) -i ${cfg.name}.${config.networking.domain} }"
          "use_backend ${cfg.name} if { req.hdr(host) -i ${cfg.name}.lan.${config.networking.domain} }"
        ];
        backends.extraConfig = [
          ''
            backend ${cfg.name}
              mode http
              server _0 [${cfg.ip6Address}]:3000 maxconn 32 check
          ''
        ];
      };
      schallernetz.servers.unbound.extraAuthZoneRecords = [
        "adguard IN AAAA ${cfg.ip6Address}"
        "${cfg.name} IN CNAME ${config.schallernetz.servers.haproxy.name}"
      ];
      schallernetz.networking.subnets.${cfg.subnet}.nfrules_in = [
        # Allow access to dns from all other subnets.
        "ip6 daddr ${cfg.ip6Address} udp dport 53 limit rate 70/second accept"
      ];
    }
  ];
}
