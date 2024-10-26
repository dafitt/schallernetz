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

    subnet = mkOpt str "lan" "The name of the subnet which the server should be part of.";
    ip6HostAddress = mkOpt str ":ef5" "The ipv6's host part for the server.";
    ip6Address = mkOpt str "${config.schallernetz.networking.subnets.${cfg.subnet}.uniqueLocal.prefix}:${cfg.ip6HostAddress}" "Full IPv6 address of the server.";
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

        bindMounts."/etc/ssh/ssh_host_ed25519_key".isReadOnly = true; # for agenix

        specialArgs = { hostConfig = config; };
        config = { hostConfig, config, lib, pkgs, ... }: {
          imports = with inputs; [ agenix.nixosModules.default ];

          age = {
            identityPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
            secrets."private.key" = { file = ./private.key.age; };
            secrets."DDNS-K57174-49283" = {
              file = ./DDNS-K57174-49283.age;
              owner = config.services.inadyn.user;
              group = config.services.inadyn.group;
            };
          };

          environment.systemPackages = with pkgs; [
            wireguard-tools
            qrencode
          ];

          boot.kernel.sysctl = {
            #"net.ipv4.conf.wg0.forwarding" = true;
            "net.ipv6.conf.all.forwarding" = true;
          };

          systemd.network = {
            enable = true;
            wait-online.enable = false;

            networks."30-eth0" = {
              matchConfig.Name = "eth0";
              #networkConfig.IPv6PrivacyExtensions = true;
              ipv6AcceptRAConfig.Token = ":${cfg.ip6HostAddress}";
            };
          };
          networking.useHostResolvConf = mkForce false; # https://github.com/NixOS/nixpkgs/issues/162686

          networking.firewall.interfaces."eth0".allowedUDPPorts = [ 123 ];
          networking = {
            useNetworkd = true;

            #nat = {
            #  # required for internet (IPv6 GUA Address)
            #  enable = true;
            #  enableIPv6 = true;
            #  externalInterface = "eth0";
            #  internalInterfaces = [ "wg0" ];
            #};

            wireguard.interfaces."wg0" = {
              privateKeyFile = config.age.secrets."private.key".path; #$ wg genkey > private.key
              # ***REMOVED_WIREGUARD-KEY*** #$ wg pubkey < private.key

              ips = [ "***REMOVED_IPv6***/80" "***REMOVED_IPv4***/20" ];
              listenPort = 123;

              peers = (import ./clients.nix);
            };
          };

          # DDNS: tell my domain my dynamic ipv6
          services.inadyn = {
            enable = true;

            interval = "*-*-* *:0/***REMOVED_IPv6***";
            logLevel = "info";
            settings = {
              allow-ipv6 = true;
              custom."do.de" = {
                username = "DDNS-K57174-49283";
                include = config.age.secrets."DDNS-K57174-49283".path; #`password = `
                hostname = "lan.wireguard.${hostConfig.schallernetz.networking.domain}";
                ddns-server = "ddns.do.de";
                ddns-path = "/?myip=%i";
                checkip-command = "${pkgs.iproute2}/bin/ip -6 addr show dev eth0 scope global -temporary | ${pkgs.gnugrep}/bin/grep -G 'inet6 [2-3]' "; # get the non-temporary global unicast address
              };
            };
          };

          system.stateVersion = hostConfig.system.stateVersion;
        };
      };
    })
    {
      schallernetz.networking.subnets.${cfg.subnet}.nfrules_in = [
        # Allow to reach this endpoint from the internet.
        "iifname wan ip6 daddr & ***REMOVED_IPv6*** == :${cfg.ip6HostAddress} udp dport 123 accept"
      ];
      systemd.network.networks."60-${cfg.subnet}".routes = [
        { routeConfig = { Destination = "***REMOVED_IPv6***::/80"; Gateway = cfg.ip6Address; IPv6Preference = "low"; }; }
      ];
    }
  ];
}
