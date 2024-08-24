{ options, config, lib, pkgs, inputs, ... }:

with lib;
with lib.schallernetz;
let
  cfg = config.schallernetz.containers.searx;
in
{
  options.schallernetz.containers.searx = with types; {
    enable = mkBoolOpt false "Enable container searx.";
    name = mkOpt str "searx" "The name of the container.";
    ipv6address = mkOpt str "***REMOVED_IPv6***" "IPv6 address of the container.";
  };

  config = mkMerge [
    (mkIf cfg.enable {
      # Get secret file
      age.secrets."searx".file = ./searx.age;

      #$ sudo nixos-container start searx
      #$ sudo nixos-container root-login searx
      containers.${cfg.name} = {
        autoStart = true;

        privateNetwork = true;
        hostBridge = "br_lan";
        localAddress = "***REMOVED_IPv4***/23";
        localAddress6 = "${cfg.ipv6address}/64";

        # Mount secret environmentFile `/run/agenix.d/3/searx`
        bindMounts.${config.age.secrets."searx".path}.isReadOnly = true;

        specialArgs = { hostConfig = config; };
        config = { hostConfig, config, lib, pkgs, ... }: {

          # SearXNG is a free internet metasearch engine which aggregates results from various search services and databases. Users are neither tracked nor profiled.
          # https://github.com/searxng/searxng
          services.searx = {
            enable = true;
            environmentFile = hostConfig.age.secrets."searx".path; # SEARX_SECRET_KEY=...

            settings = {
              # https://docs.searxng.org/admin/settings/index.html
              general = {
                debug = false;
                instance_name = "searx";
              };
              server = {
                base_url = "https://${cfg.name}.${hostConfig.networking.domain}";
                secret_key = "@SEARX_SECRET_KEY@";
                method = "GET";
                image_proxy = false;
              };
              ui.default_theme = "simple";
              ui.infinite_scroll = true;
              ui.query_in_title = true;
              search.autocomplete = "qwant";
              search.default_lang = "all"; # de-DE
              engines = mapAttrsToList (name: value: { inherit name; } // value) {
                "1337x".disabled = false;
                "1x".disabled = false;
                "alexandria".disabled = false;
                "annas archive".disabled = false;
                "bing".disabled = false;
                "bitbucket".disabled = false;
                "ccc-tv".disabled = false;
                "codeberg".disabled = false;
                "crowdview".disabled = false;
                "ddg definitions".disabled = false;
                "deezer".disabled = false;
                "duckduckgo images".disabled = false;
                "duckduckgo".disabled = false;
                "duden".disabled = false;
                "emojipedia".disabled = false;
                "erowid".disabled = false;
                "framalibre".disabled = false;
                "free software directory".disabled = false;
                "gitlab".disabled = false;
                "habrahabr".disabled = false;
                "hackernews".disabled = false;
                "hoodle".disabled = true;
                "imigur".disabled = false;
                "lib.rs".disabled = false;
                "library genesis".disabled = false;
                "lobste.rs".disabled = false;
                "material icons".disabled = false;
                "mediathekviewweb".disabled = false;
                "metacpan".disabled = false;
                "mixcloud".disabled = true;
                "mwmbl".disabled = false;
                "npm".disabled = false;
                "nyaa".disabled = false;
                "openrepos".disabled = false;
                "packagist".disabled = false;
                "peertube".disabled = false;
                "pkg.go.dev".disabled = false;
                "pypi".disabled = false;
                "reddit".disabled = false;
                "searchcode code".disabled = false;
                "sepiasearch".disabled = false;
                "sourcehut".disabled = false;
                "tagesschau".disabled = false;
                "vimeo".disabled = false;
                "wiby".disabled = false;
                "wikibooks".disabled = false;
                "wikimini".disabled = false;
                "wikinews".disabled = false;
                "wikiquote".disabled = false;
                "wikisource".disabled = false;
                "wikispecies".disabled = false;
                "wikiversity".disabled = false;
                "wikivoyage".disabled = false;
                "wiktionary".disabled = false;
                "yahoo".disabled = false;
                "yep".disabled = false;
              };
            };
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
            useDHCP = mkForce true;
            enableIPv6 = true;

            #defaultGateway = hostConfig.networking.defaultGateway.address;
            #defaultGateway6 = hostConfig.networking.defaultGateway6.address;

            firewall.interfaces."eth0" = {
              allowedTCPPorts = [ 80 ];
            };
          };

          # Workaround for bug https://github.com/NixOS/nixpkgs/issues/162686
          networking.useHostResolvConf = mkForce false;

          system.stateVersion = hostConfig.system.stateVersion;
        };
      };
    })
    {
      # entry in main reverse proxy
      schallernetz.services.haproxy.frontends.www.extraConfig = [ "use_backend ${cfg.name} if { req.hdr(host) -i ${cfg.name}.${config.networking.domain} }" ];
      services.haproxy.config = mkAfter ''
        backend ${cfg.name}
          mode http
          server _0 [${cfg.ipv6address}]:80 maxconn 32 check
      '';
    }
  ];
}
