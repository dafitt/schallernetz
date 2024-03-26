{ ... }: {
  #$ nix flake init -t .#<name>
  #$ flake init -t .#<name>

  lib = { path = ./lib; description = "Template for a new library"; };
  module = { path = ./module; description = "Template for a new module"; };
  module-container = { path = ./module/container; description = "Template for a new container module"; };
  overlay = { path = ./overlay; description = "Template for a new overlay"; };
  system = { path = ./system; description = "Template for a new system"; };
}
