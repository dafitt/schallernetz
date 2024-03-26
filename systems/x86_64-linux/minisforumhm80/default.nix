{ ... }: {
  #$ nix flake check --keep-going
  #$ nixos-rebuild build --flake .#minisforumhm80

  imports = [
    ./hardware-configuration.nix
    ./configuration.nix
  ];

  schallernetz = {
    containers = {
      adguard.enable = true;
      DavidCAL.enable = true;
      DavidSYNC.enable = true;
      DavidVPN.enable = true;
      MichiSHARE.enable = true;
      searx.enable = true;
      unbound.enable = true;
    };
    services.haproxy.enable = true;
  };

  system.stateVersion = "23.11";
}
