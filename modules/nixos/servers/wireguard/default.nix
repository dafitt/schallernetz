{ options, config, lib, pkgs, inputs, ... }:

with lib;
with lib.schallernetz;
let
  cfg = config.schallernetz.servers.wireguard;
in
{
  options.schallernetz.servers.wireguard = with types; {
    enable = mkBoolOpt false "Enable server wireguard.";
    name = mkOpt str "wireguard" "The name of the server.";

    subnet = mkOpt str "lan" "The name of the subnet which the container should be part of.";
  };

  config = mkIf cfg.enable {
    #$ sudo nixos-container start wireguard
    #$ sudo nixos-container root-login wireguard
    containers.${cfg.name} = {
      autoStart = true;
      ephemeral = true;

      privateNetwork = true;
      hostBridge = cfg.subnet;

      bindMounts."/etc/ssh/ssh_host_ed25519_key".isReadOnly = true;

      specialArgs = { hostConfig = config; };
      config = { hostConfig, config, lib, pkgs, ... }: {
        imports = with inputs; [
          agenix.nixosModules.default
          self.nixosModules."ntfy-systemd"
        ];

        age.identityPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

        age.secrets."private.key" = { file = ./private.key.age; };

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
            ips = [ "***REMOVED_IPv6***/64" "***REMOVED_IPv4***/8" ];
            listenPort = 123;

            # This allows the wireguard server to route your traffic to the internet and hence be like a VPN
            # For this to work you have to set the dnsserver IP of your router (or dnsserver of choice) in your clients
            postSetup = ''
              ${pkgs.iptables}/bin/ip6tables -t nat -A POSTROUTING -s fc01::/64 -o eth0 -j MASQUERADE
              ${pkgs.iptables}/bin/iptables -t nat -A POSTROUTING -s ***REMOVED_IPv4***/8 -o eth0 -j MASQUERADE
            '';
            postShutdown = ''
              ${pkgs.iptables}/bin/ip6tables -t nat -D POSTROUTING -s fc01::/64 -o eth0 -j MASQUERADE
              ${pkgs.iptables}/bin/iptables -t nat -D POSTROUTING -s ***REMOVED_IPv4***/8 -o eth0 -j MASQUERADE
            '';

            #$ (umask 0077; wg genkey > /var/lib/wireguard/private.key)
            privateKeyFile = config.age.secrets."private.key".path;
            #generatePrivateKeyFile = true;

            #$ wg pubkey < /var/lib/wireguard/private.key
            # ***REMOVED_WIREGUARD-KEY***

            peers = [
              {
                # DavidLEGION
                publicKey = "***REMOVED_WIREGUARD-KEY***";
                presharedKey = "***REMOVED_WIREGUARD-KEY***";
                allowedIPs = [ "***REMOVED_IPv6***/128" "***REMOVED_IPv4***/32" ];
              }
              {
                # DavidPIXEL3a
                publicKey = "***REMOVED_WIREGUARD-KEY***";
                presharedKey = "***REMOVED_WIREGUARD-KEY***";
                allowedIPs = [ "***REMOVED_IPv6***/128" "***REMOVED_IPv4***/32" ];
              }
              {
                # MichiPHONE
                publicKey = "***REMOVED_WIREGUARD-KEY***";
                presharedKey = "***REMOVED_WIREGUARD-KEY***";
                allowedIPs = [ "***REMOVED_IPv6***/128" "***REMOVED_IPv4***/32" ];
              }
              {
                # MichiWORK
                publicKey = "***REMOVED_WIREGUARD-KEY***";
                presharedKey = "***REMOVED_WIREGUARD-KEY***";
                allowedIPs = [ "***REMOVED_IPv6***/128" "***REMOVED_IPv4***/32" ];
              }
            ];
          };
        };
        systemd.services."wireguard-wg0".unitConfig = {
          OnFailure = [ "ntfy-failure@%i.service" ];
          OnSuccess = [ "ntfy-success@%i.service" ];
        };

        age.secrets."DDNS-K57174-49283" = {
          file = ./DDNS-K57174-49283.age;
          owner = config.services.inadyn.user;
          group = config.services.inadyn.group;
        };
        # tell my domain my dynamic ipv6
        services.inadyn = {
          enable = true;

          interval = "*-*-* *:0/***REMOVED_IPv6***";
          logLevel = "info";
          settings = {
            allow-ipv6 = true;
            custom."do.de" = {
              username = "DDNS-K57174-49283";
              include = config.age.secrets."DDNS-K57174-49283".path; #`password = `
              hostname = "wireguard.***REMOVED_DOMAIN***";
              ddns-server = "ddns.do.de";
              ddns-path = "/?myip=%i";
              checkip-command = ''${pkgs.iproute2}/bin/ip -6 addr show dev eth0 scope global -temporary | ${pkgs.gnugrep}/bin/grep -G 'inet6 [2-3]' ''; # get the non-temporary global unicast address
            };
          };
        };
        systemd.services.inadyn.unitConfig = {
          OnFailure = [ "ntfy-failure@%i.service" ];
        };

        system.stateVersion = hostConfig.system.stateVersion;
      };
    };
  };
}
