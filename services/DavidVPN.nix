{
  #$ sudo nixos-container start DavidVPN
  #$ sudo nixos-container root-login DavidVPN

  containers."DavidVPN" = {
    autoStart = true;

    privateNetwork = true;
    hostBridge = "br0";
    localAddress = "***REMOVED_IPv4***/23";

    config = { lib, pkgs, ... }: {

      #boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

      environment.systemPackages = with pkgs; [ wireguard-tools ];

      networking = {

        # Enable NAT
        nat.enable = true;
        nat.externalInterface = "eth0";
        nat.internalInterfaces = [ "wg0" ];

        firewall.interfaces."eth0" = {
          allowedUDPPorts = [ 51820 ];
        };

        defaultGateway.address = "***REMOVED_IPv4***";

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

          # Generate with
          generatePrivateKeyFile = true;
          # or manually
          # ```shell
          # umask 077
          # mkdir /var/lib/wireguard/
          # wg genkey > /var/lib/wireguard/private.key
          # wg pubkey < /var/lib/wireguard/private.key > /var/lib/wireguard/public.key
          # ```
          privateKeyFile = "/var/lib/wireguard/private.key";
          # public.key ***REMOVED_WIREGUARD-KEY***

          peers = [
            #{
            #  publicKey = "{client public key}";
            #  # List of IPs assigned to this peer within the tunnel subnet. Used to configure routing.
            #  allowedIPs = [ "***REMOVED_IPv4***/32" ];
            #}
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
