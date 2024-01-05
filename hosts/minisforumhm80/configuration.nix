# HPE Microserver Gen10
{ config, pkgs, ... }: {


  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
    timeout = 0;
  };

  services.fstrim.enable = true; # SSD


  networking = {
    hostName = "minisforumhm80";

    # Gets in the way of static IP adressing
    networkmanager.enable = false;
    useDHCP = false;

    bridges."br0".interfaces = [ "enp4s0" ];
    interfaces."br0" = {
      ipv4.addresses = [{
        address = "***REMOVED_IPv4***";
        prefixLength = 23;
      }];
    };

    #interfaces."enp4s0" = {
    #  ipv4.addresses = [{
    #    address = "***REMOVED_IPv4***";
    #    prefixLength = 23;
    #  }];
    #};

    defaultGateway = {
      address = "***REMOVED_IPv4***";
      interface = "br0";
    };

    nameservers = [ "***REMOVED_IPv4***" ];
  };


  console.keyMap = "de-latin1-nodeadkeys";
  time.timeZone = "Europe/Berlin";
  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS = "de_DE.UTF-8";
      LC_IDENTIFICATION = "de_DE.UTF-8";
      LC_MEASUREMENT = "de_DE.UTF-8";
      LC_MONETARY = "de_DE.UTF-8";
      LC_NAME = "de_DE.UTF-8";
      LC_NUMERIC = "de_DE.UTF-8";
      LC_PAPER = "de_DE.UTF-8";
      LC_TELEPHONE = "de_DE.UTF-8";
      LC_TIME = "de_DE.UTF-8";
    };
  };


  nixpkgs.config.allowUnfree = true;
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
