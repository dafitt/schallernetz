{ options, config, lib, pkgs, inputs, ... }:

with lib;
with lib.schallernetz;
let
  cfg = config.schallernetz.servers.satisfactory;
in
{
  options.schallernetz.servers.satisfactory = with types; {
    enable = mkBoolOpt false "Enable server satisfactory.";
    name = mkOpt str "satisfactory" "The name of the server.";

    subnet = mkOpt str "dmz" "The name of the subnet which the container should be part of.";
    ip6HostAddress = mkOpt str ":4a5" "The ipv6's host part.";
    ip6Address = mkOpt str "${config.schallernetz.networking.subnets.${cfg.subnet}.uniqueLocal.prefix}:${cfg.ip6HostAddress}" "Full IPv6 address of the container.";
  };

  config = mkMerge [
    (mkIf cfg.enable {
      #$ sudo nixos-container start satisfactory
      #$ sudo nixos-container root-login satisfactory
      containers.${cfg.name} = {

        privateNetwork = true;
        hostBridge = cfg.subnet;
        localAddress6 = "${cfg.ip6Address}/64";

        bindMounts."/etc/ssh/ssh_host_ed25519_key".isReadOnly = true; # mount host's ssh key for agenix secrets in the container

        specialArgs = { hostConfig = config; };
        config = { hostConfig, config, lib, pkgs, ... }: {
          imports = with inputs; [
            agenix.nixosModules.default
            satisfactory-server.nixosModules.satisfactory
          ];

          age = {
            identityPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
            secrets."DDNS-K57174-51715" = {
              file = ../DDNS-K57174-51715.age;
              owner = config.services.inadyn.user;
              group = config.services.inadyn.group;
            };
          };

          nixpkgs.config.allowUnfreePredicate = pkg: elem (getName pkg) [
            "satisfactory-server"
            "steamworks-sdk-redist"
          ];

          services.satisfactory = {
            enable = true;
            openFirewall = true;
            port = 7777;
          };

          # DDNS: tell my domain my dynamic ipv6
          services.inadyn = {
            enable = true;

            interval = "*-*-* *:0/***REMOVED_IPv6***";
            logLevel = "info";
            settings = {
              allow-ipv6 = true;
              custom."do.de" = {
                username = "DDNS-K57174-51715";
                include = config.age.secrets."DDNS-K57174-51715".path; #`password = `
                hostname = "satisfactory.${hostConfig.schallernetz.networking.domain}";
                ddns-server = "ddns.do.de";
                ddns-path = "/?myip=%i";
                checkip-command = "${pkgs.iproute2}/bin/ip -6 addr show dev eth0 scope global -temporary | ${pkgs.gnugrep}/bin/grep -G 'inet6 [2-3]' "; # get the non-temporary global unicast address
              };
            };
          };

          systemd.network = {
            enable = true;
            wait-online.enable = false;

            networks."30-eth0" = {
              matchConfig.Name = "eth0";
              ipv6AcceptRAConfig.Token = ":${cfg.ip6HostAddress}";
            };
          };
          networking.useHostResolvConf = mkForce false; # https://github.com/NixOS/nixpkgs/issues/162686

          system.stateVersion = hostConfig.system.stateVersion;
        };
      };

      schallernetz.backups = {
        pauseServices = [ "container@${cfg.name}.service" ];
        paths = [
          "/var/lib/nixos-containers/${cfg.name}${config.containers.${cfg.name}.config.services.satisfactory.stateDir}"
        ];
      };
    })
    {
      schallernetz.networking.subnets.${cfg.subnet}.nfrules_in = [
        "ip6 daddr & ***REMOVED_IPv6*** == :${cfg.ip6HostAddress} tcp dport 7777 accept"
        "ip6 daddr & ***REMOVED_IPv6*** == :${cfg.ip6HostAddress} udp dport 7777 accept"
      ];
      schallernetz.servers.unbound.extraLanZoneRecords = [
        "${cfg.name} IN AAAA ${cfg.ip6Address}"
      ];
    }
  ];
}
