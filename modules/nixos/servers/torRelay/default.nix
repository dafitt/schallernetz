{ options, config, lib, pkgs, ... }:

with lib;
with lib.schallernetz;
let
  cfg = config.schallernetz.servers.torRelay;
in
{
  options.schallernetz.servers.torRelay = with types; {
    enable = mkBoolOpt false "Enable server torRelay.";
    name = mkOpt str "torRelay" "The name of the server.";

    subnet = mkOpt str "dmz" "The name of the subnet which the container should be part of.";
    ip6HostAddress = mkOpt str ":58b" "The ipv6's host part.";
  };

  config = mkMerge [
    (mkIf cfg.enable {
      #$ sudo nixos-container start torRelay
      #$ sudo nixos-container root-login torRelay
      containers.${cfg.name} = {
        autoStart = true;

        privateNetwork = true;
        hostBridge = cfg.subnet;

        specialArgs = { hostConfig = config; };
        config = { hostConfig, config, lib, pkgs, ... }: {

          # https://wiki.nixos.org/wiki/Tor#Configuration
          services.tor = {
            enable = true;

            openFirewall = true;

            relay = {
              enable = true;
              role = "relay";
              # https://metrics.torproject.org/rs.html
            };

            settings = {
              # https://2019.www.torproject.org/docs/tor-manual.html.en
              Nickname = "schallernetz";
              ContactInfo = "contact@***REMOVED_DOMAIN***";

              # Bandwidth settings
              # https://beta.speedtest.net
              MaxAdvertisedBandwidth = "16 MBits";
              BandWidthRate = "10 MBits";
              RelayBandwidthRate = "10 MBits";
              RelayBandwidthBurst = "16 MBits";

              # Performance and security settings
              CookieAuthentication = true;
              AvoidDiskWrites = 1;
              HardwareAccel = 1;
              SafeLogging = 1;
              NumCPUs = 3;

              # Network settings
              ORPort = [{
                port = 443;
                flags = [ "IPv6Only" ];
                # https://www.reddit.com/r/TOR/comments/zssees/can_i_do_something_useful_with_ipv6_only/
                # https://gitlab.torproject.org/tpo/core/tor/-/issues/5788
                # https://gitlab.torproject.org/legacy/trac/-/wikis/org/roadmaps/Tor/IPv6
              }];
            };
          };

          services.snowflake-proxy = {
            enable = true;
            capacity = 100;
          };

          networking = {
            useNetworkd = true;
            useHostResolvConf = mkForce false; # https://github.com/NixOS/nixpkgs/issues/162686
          };
          systemd.network.networks."30-eth0" = {
            matchConfig.Name = "eth0";
            ipv6AcceptRAConfig.Token = ":${cfg.ip6HostAddress}";
          };

          system.stateVersion = hostConfig.system.stateVersion;
        };
      };
    })
    {
      schallernetz.networking.subnets.${cfg.subnet}.nfrules_in = [
        "ip6 daddr & ***REMOVED_IPv6*** == :${cfg.ip6HostAddress} tcp dport 443 accept"
      ];
    }
  ];
}
