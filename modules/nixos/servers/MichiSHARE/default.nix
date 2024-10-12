{ options, config, lib, pkgs, inputs, ... }:

with lib;
with lib.schallernetz;
let
  cfg = config.schallernetz.servers.MichiSHARE;
in
{
  options.schallernetz.servers.MichiSHARE = with types; {
    enable = mkBoolOpt false "Enable server MichiSHARE.";
    name = mkOpt str "MichiSHARE" "The name of the server.";

    subnet = mkOpt str "server" "The name of the subnet which the container should be part of.";
    ip6HostAddress = mkOpt str ":c66" "The ipv6's host part.";
    ip6Address = mkOpt str "${config.schallernetz.networking.subnets.${cfg.subnet}.uniqueLocal.prefix}:${cfg.ip6HostAddress}" "Full IPv6 address of the container.";
  };

  config = mkMerge [
    (mkIf cfg.enable {
      #$ sudo nixos-container start MichiSHARE
      #$ sudo nixos-container root-login MichiSHARE
      containers.${cfg.name} = {
        autoStart = true;

        privateNetwork = true;
        hostBridge = cfg.subnet;
        localAddress6 = "${cfg.ip6Address}/64";

        specialArgs = { hostConfig = config; };
        config = { hostConfig, config, lib, pkgs, ... }: {
          users.users."michi" = {
            isNormalUser = true;
            hashedPassword = "***REMOVED_HASH***";
            useDefaultShell = false;
            shell = null;
          };

          #$ smbpasswd -a <user>

          services.samba = {
            enable = true;
            enableWinbindd = false;
            enableNmbd = false;
            openFirewall = true;

            securityType = "user";
            shares."${config.users.users.michi.name}" = {
              path = config.users.users.michi.home;
              browseable = "yes";
              writable = "true";
            };
            #$ smbclient --list localhost
          };

          system.stateVersion = hostConfig.system.stateVersion;
        };
      };
    })
    {
      schallernetz.servers.unbound.extraAuthZoneRecords = [
        "${cfg.name} IN AAAA ${cfg.ip6Address}"
      ];
    }
  ];
}
