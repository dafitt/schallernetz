{ options, config, lib, pkgs, ... }:

with lib;
with lib.schallernetz;
let
  cfg = config.schallernetz.services.haproxy;
in
{
  options.schallernetz.services.haproxy = with types; {
    enable = mkBoolOpt false "Enable haproxy.";
    frontends.www.extraConfig = mkOption {
      type = listOf str;
      default = [ ];
      description = mdDoc ''
        List of strings containing additional configuration for the frontend www.
        Intended for additional backends: "use_backend <backend> if { req.hdr(host) -i <domain> }"
      '';
    };
  };

  config = mkIf cfg.enable {
    #TODO rename to *.***REMOVED_DOMAIN***.crt.key
    age.secrets."haproxy.***REMOVED_DOMAIN***.crt.key" = {
      file = ./haproxy.***REMOVED_DOMAIN***.crt.key.age;
      owner = "haproxy";
      group = "haproxy";
    };

    # Reverse Proxy before the application servers
    # [HAProxy config tutorials](https://www.haproxy.com/documentation/haproxy-configuration-tutorials/core-concepts/overview/)
    # [Essential Configuration](https://www.haproxy.com/blog/the-four-essential-sections-of-an-haproxy-configuration)
    # TODO run in a container with own ip to reduce network attack surface
    services.haproxy = {
      enable = true;
      config = ''
        global
          daemon
          maxconn 5000
          ssl-default-bind-options ssl-min-ver TLSv1.2 no-tls-tickets

        defaults
          timeout connect 10s
          timeout client 30s
          timeout server 30s

        frontend www
          mode http
          bind [::]:80 v4v6
          bind [::]:443 v4v6 ssl crt ${config.age.secrets."haproxy.***REMOVED_DOMAIN***.crt.key".path}
          http-request redirect scheme https unless { ssl_fc }

          ${concatStringsSep "\n  " cfg.frontends.www.extraConfig}
      '';
    };

    networking.firewall.allowedTCPPorts = [ 80 443 ];
  };
}
