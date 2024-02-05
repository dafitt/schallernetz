# install flakes: <https://nix-community.github.io/home-manager/index.html#ch-nix-flakes>

{
  description = "Schallernetz Servers";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";

    agenix.url = "github:ryantm/agenix";
  };

  outputs = { nixpkgs, ... }@inputs: # pass @inputs for futher configuration
    {
      # NixOS configuration entrypoint
      # Available through `nixos-rebuild --flake .#your-hostname`
      nixosConfigurations = {

        "minisforumhm80" = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = inputs;
          modules = [ ./hosts/minisforumhm80 ];
        };
      };
    };
}
