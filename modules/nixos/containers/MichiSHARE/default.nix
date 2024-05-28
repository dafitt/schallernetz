{ options, config, lib, pkgs, inputs, ... }:

with lib;
with lib.schallernetz;
let
  cfg = config.schallernetz.containers.MichiSHARE;
in
{
  options.schallernetz.containers.MichiSHARE = with types; {
    enable = mkBoolOpt false "Enable container MichiSHARE.";
    name = mkOpt str "MichiSHARE" "The name of the container.";
  };

  config = mkIf cfg.enable {

    #$ sudo nixos-container start MichiSHARE
    #$ sudo nixos-container root-login MichiSHARE
    containers.${cfg.name} = {
      autoStart = true;

      privateNetwork = true;
      hostBridge = "br0";
      localAddress = "***REMOVED_IPv4***/23";
      localAddress6 = "***REMOVED_IPv6***/64";

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
          securityType = "user";
          extraConfig = ''
            workgroup = WORKGROUP
            server string = MichiSHARE
            netbios name = MichiSHARE
            security = user
            use sendfile = yes
            #max protocol = smb2
            # note: localhost is the ipv6 localhost ***REMOVED_IPv6***
            hosts allow = ***REMOVED_IPv4***/***REMOVED_IPv4*** ***REMOVED_IPv4*** localhost
            hosts deny = ***REMOVED_IPv4***/0
            guest account = nobody
            map to guest = bad user
          '';
          shares = {
            "${config.users.users.michi.name}" = {
              path = config.users.users.michi.home;
              browseable = "yes";
              "read only" = "no";
              "create mask" = "0644";
            };
          };
          openFirewall = true;

          # make shares visible for windows 10 clients
          #services.samba-wsdd.enable = true;
          #networking.firewall.allowedTCPPorts = [ 5357 ]; # wsdd
          #networking.firewall.allowedUDPPorts = [ 3702 ]; # wsdd

          #$ smbclient --list localhost
        };

        system.stateVersion = hostConfig.system.stateVersion;
      };
    };
  };
}
