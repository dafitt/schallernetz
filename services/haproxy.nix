{ config, lib, pkgs, ... }:

let cfg = config.services.haproxy; in
{
  options.services.haproxy.frontends.www.extraConfig = lib.mkOption {
    type = with lib.types;
      listOf str;
    default = [ ];
    description = lib.mdDoc ''
      List of strings containing additional configuration for the frontend www.
      Intended for additional backends: "use_backend <backend> if { req.hdr(host) -i <domain> }"
    '';
  };

  config = {

    # Reverse Proxy before the application servers
    # [HAProxy config tutorials](https://www.haproxy.com/documentation/haproxy-configuration-tutorials/core-concepts/overview/)
    # TODO [Essential Configuration](https://www.haproxy.com/blog/the-four-essential-sections-of-an-haproxy-configuration)
    # TODO run in a container to reduce network attack surface
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

        frontend www
          bind [::]:80 v4v6
          bind [::]:443 v4v6 #TODO ssl crt /site.pem
          #http-request redirect scheme https unless { ssl_fc }

          ${builtins.concatStringsSep "\n  " cfg.frontends.www.extraConfig}
      '';
    };

    networking.firewall.allowedTCPPorts = [ 80 443 ];
  };
}
