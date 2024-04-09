{ ... }: {
  #$ nix repl .#nixosConfigurations.<host>
  #$ nix build .#nixosConfigurations.<host>.config.system.build.toplevel
  #$ nixos-rebuild build --flake .#<host> --show-trace
  #$ sudo nixos-rebuild <test|switch|boot> --flake .#<host>

  imports = [ ./hardware-configuration.nix ];

  schallernetz = { };

  system.stateVersion = "23.11"; # move this line to hardware-configuration.nix
}
