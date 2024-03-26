{ options, config, lib, pkgs, inputs, ... }:

with lib;
{
  programs.git.enable = true;

  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
      warn-dirty = false;
      trusted-users = [ "root" ];
      allowed-users = [ "@wheel" ];
    };

    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 2w";
    };

    registry."nixpkgs".flake = inputs.nixpkgs; # Make `nix run nixpkgs#nixpkgs` use the same nixpkgs as the one used by this flake.

    # disable nix-channel, we use flakes instead.
    channel.enable = false;
  };

  # Make `nix repl '<nixpkgs>'` use the same nixpkgs as the one used by this flake.
  environment.etc."nix/inputs/nixpkgs".source = "${inputs.nixpkgs}";
  nix.nixPath = [ "/etc/nix/inputs" ];

  # Multitheaded building (make)
  environment.variables.MAKEFLAGS = "-j$(expr $(nproc) \+ 1)";
}
