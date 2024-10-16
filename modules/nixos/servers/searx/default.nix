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

    subnet = mkOpt str "dmz" "The name of the subnet which the container should be part of.";
    ip6HostAddress = mkOpt str ":89c" "The ipv6's host part.";
    ip6Address = mkOpt str "${config.schallernetz.networking.subnets.${cfg.subnet}.uniqueLocal.prefix}:${cfg.ip6HostAddress}" "Full IPv6 address of the container.";
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
          imports = with inputs; [
            agenix.nixosModules.default
            self.nixosModules."ntfy-systemd"
          ];

          age = {
            identityPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
            secrets."searx" = { file = ./searx.age; };
          };

          # SearXNG is a free internet metasearch engine which aggregates results from various search services and databases. Users are neither tracked nor profiled.
          # https://github.com/searxng/searxng
          services.searx = {
            enable = true;
            environmentFile = config.age.secrets."searx".path; # SEARX_SECRET_KEY=...

            # https://docs.searxng.org/admin/settings/index.html
            # https://github.com/searxng/searxng/blob/master/searx/settings.yml
            settings = {
              general = {
                debug = false;
                instance_name = "SchallerSEARX";
              };
              server = {
                base_url = "https://${cfg.name}.${hostConfig.networking.domain}";
                secret_key = "@SEARX_SECRET_KEY@";
                method = "GET";
                image_proxy = false;
              };
              ui = {
                default_theme = "simple";
                infinite_scroll = true;
                query_in_title = true;
              };
              search = {
                default_lang = "all"; # de-DE
              };
              outgoing = {
                request_timeout = 5.0;
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
                "yep".disabled = false;
              };
            };
          };
          systemd.services.searx.unitConfig = {
            OnFailure = [ "ntfy-failure@%i.service" ];
            OnSuccess = [ "ntfy-success@%i.service" ];
          };

          # Local reverse proxy for IPv6
          # TODO security: https & secret_key
          services.haproxy = {
            enable = true;
            config = ''
              global
                daemon

              defaults
                timeout connect 5s
                timeout client 50s
                timeout server 50s

              frontend searx
                mode http
                bind [::]:80 v4v6
                default_backend searx

              backend searx
                mode http
                server searx 127.0.0.***REMOVED_IPv6*** maxconn 32 check
            '';
          };

          networking = {
            enableIPv6 = true;
            useHostResolvConf = mkForce false; # https://github.com/NixOS/nixpkgs/issues/162686
            nameservers = [ hostConfig.schallernetz.servers.unbound.ip6Address ];

            firewall.interfaces."eth0".allowedTCPPorts = [ 80 ];
          };

          system.stateVersion = hostConfig.system.stateVersion;
        };
      };
    })
    {
      schallernetz.servers.haproxy-dmz = {
        frontends.www.extraConfig = [
          "use_backend ${cfg.name} if { req.hdr(host) -i ${cfg.name}.${config.networking.domain} }"
          "use_backend ${cfg.name} if { req.hdr(host) -i ${cfg.name}.lan.${config.networking.domain} }"
        ];
        backends.extraConfig = [
          ''
            backend ${cfg.name}
              mode http
              server _0 [${cfg.ip6Address}]:80 maxconn 32 check
          ''
        ];
      };
      schallernetz.servers.unbound.extraAuthZoneRecords = [
        "${cfg.name} IN CNAME ${config.schallernetz.servers.haproxy-dmz.name}"
      ];
    }
  ];
}
