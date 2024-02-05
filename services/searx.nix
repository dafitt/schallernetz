{ config, lib, ... }: {

  # Get secret file
  age.secrets."searx".file = ../secrets/searx.age;

  # Entry for the main reverse proxy
  services.haproxy = {
    frontends.www.extraConfig = [ "use_backend searx if { req.hdr(host) -i searx.${config.networking.domain} }" ];
    config = lib.mkAfter ''
      backend searx
        server _0 [***REMOVED_IPv6***]:80 maxconn 32 check
    '';
  };

  #$ sudo nixos-container start searx
  #$ sudo nixos-container root-login searx
  containers."searx" = {
    autoStart = true;

    privateNetwork = true;
    hostBridge = "br0";
    localAddress = "***REMOVED_IPv4***/23";
    localAddress6 = "***REMOVED_IPv6***/64";

    # Mount secret environmentFile `/run/agenix.d/3/searx`
    bindMounts."${config.age.secrets."searx".path}".isReadOnly = true;

    specialArgs = { hostconfig = config; };
    config = { hostconfig, lib, ... }: {

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
            secret_key = "@SEARX_SECRET_KEY@";
            method = "GET";
            infinite_scroll = true;
          };
        };
        environmentFile = hostconfig.age.secrets."searx".path; # SEARX_SECRET_KEY=...
      };

      # Local reverse proxy for IPv6
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
          allowedTCPPorts = [ 80 ];
        };
      };

      # Workaround for bug https://github.com/NixOS/nixpkgs/issues/162686
      networking.useHostResolvConf = lib.mkForce false;

      system.stateVersion = "23.11";
    };
  };
}
