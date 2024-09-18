{ options, config, lib, pkgs, inputs, ... }:

with lib;
with lib.schallernetz;
let
  cfg = config.schallernetz.containers.DavidVPN;
in
{
  options.schallernetz.containers.DavidVPN = with types; {
    enable = mkBoolOpt false "Enable container DavidVPN.";
    name = mkOpt str "DavidVPN" "The name of the container.";
    #TODO define the mac address for a predictable ipv6 host-address
  };

  config = mkIf cfg.enable {
    #$ sudo nixos-container start DavidVPN
    #$ sudo nixos-container root-login DavidVPN
    containers.${cfg.name} = {
      autoStart = true;

      privateNetwork = true;
      hostBridge = "br_lan";

      bindMounts."/etc/ssh/ssh_host_ed25519_key".isReadOnly = true;

      specialArgs = { hostConfig = config; };
      config = { hostConfig, config, lib, pkgs, ... }: {
        boot.kernel.sysctl."net.ipv6.conf.wg0.forwarding" = 1;
        boot.kernel.sysctl."net.ipv4.conf.wg0.forwarding" = 1;

        environment.systemPackages = with pkgs; [
          wireguard-tools
          qrencode
        ];

        networking = {
          # Log in to the network like a normal client
          useDHCP = mkForce true; # automatically get IPv4 and default route
          enableIPv6 = true; # automatically get IPv6 and default route6
          useHostResolvConf = mkForce false; # https://github.com/NixOS/nixpkgs/issues/162686

          # use ramdom IPv6 addresses (privacy extensions)
          interfaces."eth0".tempAddress = "default";

          # Enable NAT
          nat = {
            enable = true;
            enableIPv6 = true;
            externalInterface = "eth0";
            internalInterfaces = [ "wg0" ];
          };

          firewall.interfaces."eth0" = {
            allowedUDPPorts = [ 123 ];
          };

          # Wireguard Network
          wireguard.interfaces."wg0" = {
            ips = [ "***REMOVED_IPv6***/64" "***REMOVED_IPv4***/24" ];
            listenPort = 123;

            # This allows the wireguard server to route your traffic to the internet and hence be like a VPN
            # For this to work you have to set the dnsserver IP of your router (or dnsserver of choice) in your clients
            postSetup = ''
              ${pkgs.iptables}/bin/ip6tables -t nat -A POSTROUTING -s fc07::/64 -o eth0 -j MASQUERADE
              ${pkgs.iptables}/bin/iptables -t nat -A POSTROUTING -s ***REMOVED_IPv4***/24 -o eth0 -j MASQUERADE
            '';
            postShutdown = ''
              ${pkgs.iptables}/bin/ip6tables -t nat -D POSTROUTING -s fc07::/64 -o eth0 -j MASQUERADE
              ${pkgs.iptables}/bin/iptables -t nat -D POSTROUTING -s ***REMOVED_IPv4***/24 -o eth0 -j MASQUERADE
            '';

            #$ (umask 0077; wg genkey > /var/lib/wireguard/private.key)
            privateKeyFile = "/var/lib/wireguard/private.key";
            #generatePrivateKeyFile = true;

            #$ wg pubkey < /var/lib/wireguard/private.key
            # ***REMOVED_WIREGUARD-KEY***

            peers = [
              {
                # DavidLEGION
                publicKey = "***REMOVED_WIREGUARD-KEY***";
                allowedIPs = [ "***REMOVED_IPv6***/128" "***REMOVED_IPv4***/32" ];
              }
              {
                # DavidPIXEL
                publicKey = "***REMOVED_WIREGUARD-KEY***";
                allowedIPs = [ "***REMOVED_IPv6***/128" "***REMOVED_IPv4***/32" ];
              }
            ];
          };
        };

        imports = [ inputs.agenix.nixosModules.default ];
        age.identityPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
        age.secrets."DDNS-K57174-49283" = {
          file = ./DDNS-K57174-49283.age;
          owner = config.services.inadyn.user;
          group = config.services.inadyn.group;
        };
        # tell my domain my dynamic ipv6
        services.inadyn = {
          enable = true;

          logLevel = "info";
          settings = {
            allow-ipv6 = true;
            custom."do.de" = {
              username = "DDNS-K57174-49283";
              include = config.age.secrets."DDNS-K57174-49283".path; #`password = `
              hostname = "davidvpn.***REMOVED_DOMAIN***";
              ddns-server = "ddns.do.de";
              ddns-path = "/?myip=%i";
              checkip-command = ''${pkgs.iproute2}/bin/ip -6 addr show dev eth0 scope global -temporary | ${pkgs.gnugrep}/bin/grep -G 'inet6 [2-3]' ''; # get the non-temporary global unicast address
            };
          };
        };

        system.stateVersion = hostConfig.system.stateVersion;
      };
    };
  };
}
