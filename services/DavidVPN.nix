{
  #$ sudo nixos-container start DavidVPN
  #$ sudo nixos-container root-login DavidVPN

  containers."DavidVPN" = {
    autoStart = true;

    privateNetwork = true;
    hostBridge = "br0";
    localAddress = "***REMOVED_IPv4***/23";

    specialArgs = { hostconfig = config; };
    config = { hostconfig, lib, pkgs, ... }: {

      environment.systemPackages = with pkgs; [ wireguard-tools ];

      networking = {

        # Enable NAT
        nat.enable = true;
        nat.externalInterface = "eth0";
        nat.internalInterfaces = [ "wg0" ];

        firewall.interfaces."eth0" = {
          allowedUDPPorts = [ 51820 ];
        };

        defaultGateway.address = hostconfig.networking.defaultGateway.address;

        # Wireguard Network
        wireguard.interfaces."wg0" = {
          ips = [ "***REMOVED_IPv4***/24" ];
          listenPort = 51820;

          # This allows the wireguard server to route your traffic to the internet and hence be like a VPN
          # For this to work you have to set the dnsserver IP of your router (or dnsserver of choice) in your clients
          postSetup = ''
            ${pkgs.iptables}/bin/iptables -t nat -A POSTROUTING -s ***REMOVED_IPv4***/24 -o eth0 -j MASQUERADE
          '';
          postShutdown = ''
            ${pkgs.iptables}/bin/iptables -t nat -D POSTROUTING -s ***REMOVED_IPv4***/24 -o eth0 -j MASQUERADE
          '';

          generatePrivateKeyFile = true;
          privateKeyFile = "/var/lib/wireguard/private.key";
          #$ wg pubkey < /var/lib/wireguard/private.key > /var/lib/wireguard/public.key
          # public.key ***REMOVED_WIREGUARD-KEY***

          peers = [
            {
              # DavidLEGION
              publicKey = "***REMOVED_WIREGUARD-KEY***";
              allowedIPs = [ "***REMOVED_IPv4***/32" ];
            }
            {
              # DavidPIXEL
              publicKey = "***REMOVED_WIREGUARD-KEY***";
              allowedIPs = [ "***REMOVED_IPv4***/32" ];
            }
          ];
        };
      };

      system.stateVersion = "23.11";
    };
  };
}
