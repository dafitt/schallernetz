{ options, config, lib, pkgs, inputs, ... }:

with lib;
with lib.schallernetz;
let
  cfg = config.schallernetz.servers.unbound;
in
{
  options.schallernetz.servers.unbound = with types; {
    enable = mkBoolOpt false "Enable server unbound.";
    name = mkOpt str "unbound" "The name of the server.";

    subnet = mkOpt str "server" "The name of the subnet which the container should be part of.";
    ip6Host = mkOpt str ":9" "The ipv6's host part.";
    ip6Address = mkOpt str "${config.schallernetz.networking.subnets.${cfg.subnet}.uniqueLocalPrefix}:${cfg.ip6Host}" "Full IPv6 address of the container.";
  };

  config = mkIf cfg.enable {
    #$ sudo nixos-container start unbound
    #$ sudo nixos-container root-login unbound
    containers.${cfg.name} = {
      autoStart = true;

      privateNetwork = true;
      hostBridge = cfg.subnet;
      localAddress6 = "${cfg.ip6Address}/64";

      specialArgs = { hostConfig = config; };
      config = { hostConfig, config, lib, pkgs, ... }: {
        imports = with inputs;[ self.nixosModules."ntfy-systemd" ];

        environment.systemPackages = with pkgs; [ dig ];

        # Unbound is a validating, recursive, caching DNS resolver (like ***REMOVED_IPv4***).
        services.unbound = {
          enable = true;

          # https://unbound.docs.nlnetlabs.nl/en/latest/manpages/unbound.conf.html
          settings.server = {
            # the interface ip's that is used to connect to the network
            interface = [ "${cfg.ip6Address}" ];

            qname-minimisation = true;
          };

          settings.auth-zone = [
            {
              name = "lan.***REMOVED_DOMAIN***";
              zonefile = "${./de.***REMOVED_DOMAIN***.zone}";
            }
          ];
        };
        systemd.services.unbound.unitConfig = {
          OnFailure = [ "ntfy-failure@%i.service" ];
          OnSuccess = [ "ntfy-success@%i.service" ];
        };

        networking = {
          enableIPv6 = true; # automatically get IP6 and default route6
          useHostResolvConf = mkForce false; # https://github.com/NixOS/nixpkgs/issues/162686

          firewall.interfaces."eth0" = {
            allowedUDPPorts = [ 53 ];
          };
        };

        system.stateVersion = hostConfig.system.stateVersion;
      };
    };
  };
}
