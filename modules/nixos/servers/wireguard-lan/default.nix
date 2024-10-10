{ options, config, lib, pkgs, inputs, ... }:

with lib;
with lib.schallernetz;
let
  cfg = config.schallernetz.servers."wireguard-lan";
in
{
  options.schallernetz.servers."wireguard-lan" = with types; {
    enable = mkBoolOpt false "Enable server wireguard-lan.";
    name = mkOpt str "wireguard-lan" "The name of the server.";

    subnet = mkOpt str "lan" "The name of the subnet which the container should be part of.";
    ip6HostAddress = mkOpt str ":ef5" "The ipv6's host part.";
  };

  config = mkMerge [
    (mkIf cfg.enable {
      #$ sudo nixos-container start wireguard-lan
      #$ sudo nixos-container root-login wireguard-lan
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

          environment.systemPackages = with pkgs; [
            wireguard-tools
            qrencode
          ];

          boot.kernel.sysctl."net.ipv6.conf.wg0.forwarding" = 1;
          boot.kernel.sysctl."net.ipv4.conf.wg0.forwarding" = 1;

          systemd.network.networks."30-eth0" = {
            matchConfig.Name = "eth0";
            ipv6AcceptRAConfig.Token = ":${cfg.ip6HostAddress}";
          };

          networking = {
            # Log in to the network like a normal client
            useNetworkd = true;
            interfaces."eth0".tempAddress = "default"; # IPv6 temporary address (aka privacy extensions)
            useHostResolvConf = mkForce false; # https://github.com/NixOS/nixpkgs/issues/162686

            firewall.interfaces."eth0".allowedUDPPorts = [ 123 ];

            nat = {
              enable = true;
              enableIPv6 = true;
              externalInterface = "eth0";
              internalInterfaces = [ "wg0" ];
            };

            wireguard.interfaces."wg0" = {
              ips = [ "***REMOVED_IPv6***/64" "***REMOVED_IPv4***/8" ];
              listenPort = 123;

              # This allows the wireguard server to route your traffic to the internet and hence be like a VPN
              # For this to work you have to set the dnsserver IP of your router (or dnsserver of choice) in your clients
              postSetup = ''
                ${pkgs.iptables}/bin/ip6tables -t nat -A POSTROUTING -s fc00::/64 -o eth0 -j MASQUERADE
                ${pkgs.iptables}/bin/iptables -t nat -A POSTROUTING -s ***REMOVED_IPv4***/8 -o eth0 -j MASQUERADE
              '';
              postShutdown = ''
                ${pkgs.iptables}/bin/ip6tables -t nat -D POSTROUTING -s fc00::/64 -o eth0 -j MASQUERADE
                ${pkgs.iptables}/bin/iptables -t nat -D POSTROUTING -s ***REMOVED_IPv4***/8 -o eth0 -j MASQUERADE
              '';

              privateKeyFile = config.age.secrets."private.key".path; #$ wg genkey > private.key
              # ***REMOVED_WIREGUARD-KEY*** #$ wg pubkey < private.key

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

          # DDNS
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
                hostname = "lan.wireguard.***REMOVED_DOMAIN***";
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
    })
    {
      schallernetz.networking.subnets.${cfg.subnet}.nfrules_in = [
        "iifname wan ip6 daddr & ***REMOVED_IPv6*** == :${cfg.ip6HostAddress} udp dport 123 accept"
      ];
    }
  ];
}