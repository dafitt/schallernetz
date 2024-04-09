{ ... }: {
  #$ nix repl .#nixosConfigurations.minisforumhm80
  #$ nix build .#nixosConfigurations.minisforumhm80.config.system.build.toplevel
  #$ nixos-rebuild build --flake .#minisforumhm80 --show-trace
  #$ sudo nixos-rebuild <test|switch|boot> --flake .#minisforumhm80

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
}
