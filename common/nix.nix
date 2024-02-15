{ lib, inputs, ... }: {

  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" "repl-flake" ];
      auto-optimise-store = lib.mkDefault true;
      warn-dirty = false;
    };

    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 2w";
    };

    # Make `nix run nixpkgs#nixpkgs` use the same nixpkgs as the one used by this flake.
    registry."nixpkgs".flake = inputs.nixpkgs;

    # disable nix-channel, we use flakes instead.
    channel.enable = false;

  };

  # Make `nix repl '<nixpkgs>'` use the same nixpkgs as the one used by this flake.
  environment.etc."nix/inputs/nixpkgs".source = "${inputs.nixpkgs}";
  nix.nixPath = [ "/etc/nix/inputs" ];

  # Limit the number of generations to keep
  boot.loader.systemd-boot.configurationLimit = lib.mkDefault 25;
}
