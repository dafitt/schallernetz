{ options, config, lib, pkgs, inputs, ... }:

with lib;
with lib.schallernetz;
let
  cfg = config.schallernetz.servers.searx;
in
{
  options.schallernetz.servers.searx = with types; {
    enable = mkBoolOpt false "Enable server searx.";
    name = mkOpt str "searx" "The name of the server.";

    subnet = mkOpt str "dmz" "The name of the subnet which the server should be part of.";
    ip6HostAddress = mkOpt str ":89c" "The ipv6's host part for the server.";
    ip6Address = mkOpt str "${config.schallernetz.networking.subnets.${cfg.subnet}.uniqueLocal.prefix}:${cfg.ip6HostAddress}" "Full IPv6 address of the server.";
  };

  config = mkMerge [
    (mkIf cfg.enable {

      #$ sudo nixos-container start searx
      #$ sudo nixos-container root-login searx
      containers.${cfg.name} = {
        autoStart = true;

        privateNetwork = true;
        hostBridge = cfg.subnet;
        localAddress6 = "${cfg.ip6Address}/64";

        bindMounts."/etc/ssh/ssh_host_ed25519_key".isReadOnly = true; # for agenix

        specialArgs = { hostConfig = config; };
        config = { hostConfig, config, lib, pkgs, ... }: {
          imports = with inputs; [ agenix.nixosModules.default ];

          age = {
            identityPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
            secrets."searx" = { file = ./searx.age; };
          };

          # SearXNG is a free internet metasearch engine which aggregates results from various search services and databases. Users are neither tracked nor profiled.
          # https://github.com/searxng/searxng
          # https://wiki.nixos.org/wiki/SearXNG
          services.searx = {
            enable = true;

            # https://docs.searxng.org/admin/settings/index.html
            # https://github.com/searxng/searxng/blob/master/searx/settings.yml
            settings = {
              general = {
                debug = false;
                instance_name = "SchallerSEARX";
              };
              server = {
                port = 8888;
                base_url = "https://${cfg.name}.${hostConfig.networking.domain}";
                secret_key = config.age.secrets."searx".path; # SEARX_SECRET_KEY=...
                limiter = true;
                public_instance = true;
                image_proxy = false;
                method = "GET";
              };
              ui = {
                static_use_hash = true;
                default_theme = "simple";
                infinite_scroll = true;
                query_in_title = true;
              };
              search = {
                default_lang = "all"; # de-DE
              };
              engines = mapAttrsToList (name: value: { inherit name; } // value) {
                "1337x".disabled = false;
                "1x".disabled = false;
                "alexandria".disabled = false;
                "annas archive".disabled = false;
                "bing".disabled = false;
                "bitbucket".disabled = false;
                "codeberg".disabled = false;
                "crowdview".disabled = false;
                "ddg definitions".disabled = false;
                "deezer".disabled = false;
                "duckduckgo images".disabled = false;
                "duckduckgo".disabled = false;
                "duden".disabled = false;
                "emojipedia".disabled = false;
                "erowid".disabled = false;
                "free software directory".disabled = false;
                "gitlab".disabled = false;
                "habrahabr".disabled = false;
                "hackernews".disabled = false;
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
              };

              enabled_plugins = [
                "Basic Calculator"
                "Hash plugin"
                #"Tor check plugin"
                "Open Access DOI rewrite"
                "Hostnames plugin"
                "Unit converter plugin"
                "Tracker URL remover"
              ];
            };

            redisCreateLocally = true;
            limiterSettings = {
              real_ip = {
                x_for = 1;
                ipv6_prefix = 56;
              };
              botdetection = {
                ip_limit = {
                  filter_link_local = true;
                  link_token = true;
                };
              };
            };

            runInUwsgi = true;
            uwsgiConfig = {
              http = "[${cfg.ip6Address}]:${toString config.services.searx.settings.server.port}";
            };
          };

          systemd.network = {
            enable = true;
            wait-online.enable = false;

            networks."30-eth0" = {
              matchConfig.Name = "eth0";
              networkConfig.IPv6PrivacyExtensions = true;
              networkConfig.DNS = [ hostConfig.schallernetz.servers.unbound.ip6Address ];
            };
          };
          networking.useHostResolvConf = mkForce false; # https://github.com/NixOS/nixpkgs/issues/162686

          networking.firewall.interfaces."eth0" = {
            allowedTCPPorts = [ config.services.searx.settings.server.port ];
          };

          system.stateVersion = hostConfig.system.stateVersion;
        };
      };
    })
    {
      schallernetz.servers.haproxy-dmz = {
        frontends.www.extraConfig = [
          "use_backend ${cfg.name} if { req.hdr(host) -i ${cfg.name}.${config.networking.domain} }"
        ];
        backends.extraConfig = [
          ''
            backend ${cfg.name}
              mode http
              option http-server-close
              server _0 [${cfg.ip6Address}]:8888 maxconn 32 check
          ''
        ];
      };
      schallernetz.servers.unbound.extraAuthZoneRecords = [
        "${cfg.name} IN CNAME ${config.schallernetz.servers.haproxy-dmz.name}"
      ];
    }
  ];
}
