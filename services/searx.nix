{ config, ... }: {
  #$ sudo nixos-container start searx
  #$ sudo nixos-container root-login searx

  containers."searx" = {
    autoStart = true;

    privateNetwork = true;
    hostBridge = "br0";
    localAddress = "***REMOVED_IPv4***/23";
    localAddress6 = "***REMOVED_IPv6***/64";

    specialArgs = { hostconfig = config; };
    config = { hostconfig, lib, ... }: {

      #* http://192.168.19.***REMOVED_IPv6***

      # SearXNG is a free internet metasearch engine which aggregates results from various search services and databases. Users are neither tracked nor profiled.
      # https://github.com/searxng/searxng
      services.searx = {
        enable = true;

        settings = {
          general = {
            debug = false;
            instance_name = "SearXNG";
          };
          ui = {
            default_theme = "simple";
            theme_args = {
              simple_style = "dark";
            };
          };
          server = {
            #base_url = "searx.***REMOVED_DOMAIN***";
            #port = 8888;
            bind_address = "***REMOVED_IPv4***";
            secret_key = "f3c0447c2640e7e75813118a3bc3634b"; # TODO sops
            method = "GET";
            infinite_scroll = true;
          };
        };
      };

      # Reverse proxy for IPv6 and ssl
      # TODO security: https & secret_key
      services.haproxy = {
        enable = true;
        config = ''
          global
            daemon

          defaults
            mode http
            timeout connect 5s
            timeout client 50s
            timeout server 50s

          frontend searx
            bind [::]:80 v4v6
            #bind :443 ssl crt /site.pem
            #http-request redirect scheme https unless { ssl_fc }
            default_backend searx

          backend searx
            server searx 127.0.0.***REMOVED_IPv6*** maxconn 32 check
        '';
      };

      networking = {

        # automatically get IP and default gateway
        useDHCP = lib.mkForce true;
        enableIPv6 = true;

        #defaultGateway = hostconfig.networking.defaultGateway.address;
        #defaultGateway6 = hostconfig.networking.defaultGateway6.address;

        firewall.interfaces."eth0" = {
          allowedTCPPorts = [ 80 8888 ];
        };
      };

      # Workaround for bug https://github.com/NixOS/nixpkgs/issues/162686
      networking.useHostResolvConf = lib.mkForce false;

      system.stateVersion = "23.11";
    };
  };
}
