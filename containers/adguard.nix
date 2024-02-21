{ config, lib, ... }:

let name = "adguard"; in
{

  services.haproxy = lib.mkIf config.services.haproxy.enable {
    frontends.www.extraConfig = [ "use_backend ${name} if { req.hdr(host) -i ${name}.${config.networking.domain} }" ];
    config = lib.mkAfter ''
      backend ${name}
        server _0 [***REMOVED_IPv6***]:3000 maxconn 32 check
    '';
  };

  #$ sudo nixos-container start adguard
  #$ sudo nixos-container root-login adguard
  containers."${name}" = {
    autoStart = true;

    privateNetwork = true;
    hostBridge = "br0";
    localAddress = "***REMOVED_IPv4***/23";
    localAddress6 = "***REMOVED_IPv6***/56";

    specialArgs = { hostconfig = config; };
    config = { hostconfig, ... }: {

      services.adguardhome = {
        enable = true;

        settings = {
          # https://github.com/AdguardTeam/AdGuardHome/wiki/Configuration#configuration-file
          safebrowsing_enabled = true;
          dns = {
            bind_hosts = [ "***REMOVED_IPv4***" "***REMOVED_IPv6***" ];
            enable_dnssec = true;
            upstream_dns = [ "***REMOVED_IPv6***" ];
          };
          users = [
            { name = "admin"; password = "***REMOVED_HASH***"; }
            { name = "schaller"; password = "***REMOVED_HASH***"; }
          ];
          querylog.interval = "2h";
          statistics.interval = "2160h"; # 90d
        };

        openFirewall = true;
      };

      networking.firewall.interfaces."eth0" = {
        allowedTCPPorts = [ 53 ];
        allowedUDPPorts = [ 53 ];
      };

      # Workaround for bug https://github.com/NixOS/nixpkgs/issues/162686
      networking.useHostResolvConf = lib.mkForce false;

      system.stateVersion = "23.11";
    };
  };
}
