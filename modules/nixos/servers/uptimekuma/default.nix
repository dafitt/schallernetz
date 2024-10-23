{ options, config, lib, pkgs, ... }:

with lib;
with lib.schallernetz;
let
  cfg = config.schallernetz.servers.uptimekuma;
in
{
  options.schallernetz.servers.uptimekuma = with types; {
    enable = mkBoolOpt false "Enable server uptimekuma.";
    name = mkOpt str "uptimekuma" "The name of the server.";

    subnet = mkOpt str "server" "The name of the subnet which the server should be part of.";
    ip6HostAddress = mkOpt str ":711" "The ipv6's host part for the server.";
    ip6Address = mkOpt str "${config.schallernetz.networking.subnets.${cfg.subnet}.uniqueLocal.prefix}:${cfg.ip6HostAddress}" "Full IPv6 address of the server.";
  };

  config = mkMerge [
    (mkIf cfg.enable {
      #$ sudo nixos-container start uptimekuma
      #$ sudo nixos-container root-login uptimekuma
      containers.${cfg.name} = {
        autoStart = true;

        privateNetwork = true;
        hostBridge = cfg.subnet;
        localAddress6 = "${cfg.ip6Address}/64";

        specialArgs = { hostConfig = config; };
        config = { hostConfig, config, lib, pkgs, ... }: {

          # https://github.com/louislam/uptime-kuma/wiki
          services.uptime-kuma = {
            enable = true;
            # https://github.com/louislam/uptime-kuma/wiki/Environment-Variables
            settings = {
              HOST = cfg.ip6Address;
              PORT = "8080";
            };
          };

          systemd.network = {
            enable = true;
            wait-online.enable = false;

            networks."30-eth0" = {
              matchConfig.Name = "eth0";
              networkConfig.DNS = [ hostConfig.schallernetz.servers.unbound.ip6Address ];
              ipv6AcceptRAConfig.Token = ":${cfg.ip6HostAddress}";
            };
          };
          networking.useHostResolvConf = mkForce false; # https://github.com/NixOS/nixpkgs/issues/162686

          networking.firewall.interfaces."eth0" = {
            allowedTCPPorts = [ 8080 ];
          };

          system.stateVersion = hostConfig.system.stateVersion;
        };
      };

      schallernetz.backups.paths = [
        "/var/lib/nixos-containers/${cfg.name}/etc/group"
        "/var/lib/nixos-containers/${cfg.name}/etc/machine-id"
        "/var/lib/nixos-containers/${cfg.name}/etc/passwd"
        "/var/lib/nixos-containers/${cfg.name}/etc/subgid"
        "/var/lib/nixos-containers/${cfg.name}${config.containers.${cfg.name}.config.services.uptime-kuma.settings.DATA_DIR}"
      ];
    })
    # The following configuration will be applied at every build on every system.
    # This has the advantage that you can distribute your servers across several hosts.
    {
      schallernetz.servers.haproxy-server = {
        frontends.www.extraConfig = [
          "use_backend ${cfg.name} if { req.hdr(host) -i ${cfg.name}.lan.${config.networking.domain} }"
        ];
        backends.extraConfig = [
          ''
            backend ${cfg.name}
              mode http
              server _0 [${cfg.ip6Address}]:8080 maxconn 32 check
          ''
        ];
      };
      schallernetz.networking.subnets.${cfg.subnet}.nfrules_in = [
        "iifname lan ip6 daddr ${cfg.ip6Address} tcp dport 443 accept"
      ];
      schallernetz.servers.unbound.extraLanZoneRecords = [
        "${cfg.name} IN CNAME ${config.schallernetz.servers.haproxy-server.name}"
      ];
    }
  ];
}

# Don't forget to add `schallernetz.servers.uptimekuma.enable = true;` to the hosts configuration!
