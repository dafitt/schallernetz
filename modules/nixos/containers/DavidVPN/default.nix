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
  };

  config = mkIf cfg.enable {

    #$ sudo nixos-container start DavidVPN
    #$ sudo nixos-container root-login DavidVPN
    containers.${cfg.name} = {
      autoStart = true;

      privateNetwork = true;
      hostBridge = "br_lan";

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
          useDHCP = mkForce true;
          enableIPv6 = true;

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

        ## Workaround for bug https://github.com/NixOS/nixpkgs/issues/162686
        networking.useHostResolvConf = mkForce false;

        system.stateVersion = hostConfig.system.stateVersion;
      };
    };
  };
}
