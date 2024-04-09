{ config, pkgs, ... }: {

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
    timeout = 0;
  };

  services.fstrim.enable = true; # SSD

  networking = {
    hostName = "minisforumhm80";
    domain = "***REMOVED_DOMAIN***";

    # Gets in the way of static IP adressing
    networkmanager.enable = false;
    useDHCP = false;

    bridges."br0".interfaces = [ "enp4s0" ];
    interfaces."br0" = {
      ipv4.addresses = [{
        address = "***REMOVED_IPv4***";
        prefixLength = 23;
      }];
      ipv6.addresses = [{
        address = "***REMOVED_IPv6***";
        prefixLength = 64;
      }];
    };

    defaultGateway = {
      address = "***REMOVED_IPv4***";
      interface = "br0";
    };
    defaultGateway6 = {
      address = "***REMOVED_IPv6***";
      interface = "br0";
    };

    # for local updates
    nameservers = [
      config.networking.defaultGateway.address
      config.networking.defaultGateway6.address
    ];
  };

  environment.systemPackages = with pkgs; [
    micro
  ];

  services.openssh = {
    enable = true;
    settings = {
      # require public key authentication for better security
      #PasswordAuthentication = false;
      #KbdInteractiveAuthentication = false;
      PermitRootLogin = "yes";
    };
  };

  users.users.root.openssh.authorizedKeys.keys = [
    "***REMOVED_SSH-PUBLICKEY*** david@DavidDESKTOP"
  ];

  system.stateVersion = "23.11";
}
