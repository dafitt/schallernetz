{
  #$ nix flake update --commit-lock-file
  #$ nix flake lock --update-input [input]
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05"; # https://github.com/nixos/nixpkgs

    snowfall-lib = { url = "github:snowfallorg/lib/dev"; inputs.nixpkgs.follows = "nixpkgs"; }; # https://github.com/snowfallorg/lib

    agenix.url = "github:ryantm/agenix"; # https://github.com/ryantm/agenix
  };

  # [Snowfall framework](https://snowfall.org/guides/lib/quickstart/)
  #$ nix flake check --keep-going
  outputs = inputs: inputs.snowfall-lib.mkFlake {
    inherit inputs;
    src = ./.;

    snowfall = {
      namespace = "schallernetz";
      meta = {
        name = "schallernetz";
        title = "Schallernetz Servers";
      };
    };

    channels-config = {
      allowUnfree = true;
    };

    overlays = with inputs; [
    ];

    systems.modules.nixos = with inputs; [
      agenix.nixosModules.default
    ];

    templates = import ./templates { };
  };

  description = "The schallernetz servers.";
}
