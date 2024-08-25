{ options, config, lib, pkgs, ... }:

with lib;
with lib.schallernetz;
let
  cfg = config.schallernetz.containers.adguardhome;
in
{
  options.schallernetz.containers.adguardhome = with types; {
    enable = mkBoolOpt false "Enable container adguardhome.";
    name = mkOpt str "adguardhome" "The name of the container."; # TODO: rename adguardhome
    ipv6address = mkOpt str "${config.schallernetz.networking.uniqueLocalPrefix}***REMOVED_IPv6***" "IPv6 address of the container.";
  };

  config = mkMerge [
    (mkIf cfg.enable {
      #$ sudo nixos-container start adguardhome
      #$ sudo nixos-container root-login adguardhome
      containers.${cfg.name} = {
        autoStart = true;

        privateNetwork = true;
        hostBridge = "br_lan";
        localAddress = "***REMOVED_IPv4***/23";
        localAddress6 = "${cfg.ipv6address}/64";

        specialArgs = { hostConfig = config; };
        config = { hostConfig, config, lib, pkgs, ... }: {

          services.adguardhome = {
            enable = true;

            settings = {
              # https://github.com/AdguardTeam/AdGuardHome/wiki/Configuration#configuration-file
              safebrowsing_enabled = true;
              dns = {
                bind_hosts = [ "***REMOVED_IPv4***" "${cfg.ipv6address}" ];
                enable_dnssec = true;
                upstream_dns = [ "${hostConfig.schallernetz.networking.uniqueLocalPrefix}***REMOVED_IPv6***" ];
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

          networking.firewall.interfaces."eth0" = {
            allowedUDPPorts = [ 53 ];
          };

          # Workaround for bug https://github.com/NixOS/nixpkgs/issues/162686
          networking.useHostResolvConf = mkForce false;

          system.stateVersion = hostConfig.system.stateVersion;
        };
      };
    })
    {
      # entry in main reverse proxy
      schallernetz.services.haproxy.frontends.www.extraConfig = [ "use_backend ${cfg.name} if { req.hdr(host) -i ${cfg.name}.${config.networking.domain} }" ];
      services.haproxy.config = mkAfter ''
        backend ${cfg.name}
          mode http
          server _0 [${cfg.ipv6address}]:3000 maxconn 32 check
      '';
    }
  ];
}
