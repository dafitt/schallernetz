> !Github: This repository is just a representation of my server configuration, intended for viewing only. It will not work because secrets have been filtered out.

# Our Snowfall🌨️🍂 NixOS❄️ servers

-   [Our Snowfall🌨️🍂 NixOS❄️ servers](#our-snowfall️-nixos️-servers)
    -   [Usage](#usage)
        -   [Upgrading](#upgrading)
        -   [Modules](#modules)
    -   [Structure](#structure)

## Usage

### Upgrading

1. At a new NixOS release manually update inputs in [flake.nix](https://github.com/dafitt/schallernetz/blob/main/flake.nix). e.g. `24.05` -> `24.11`.

2. `nix flake update --commit-lock-file`

3. (optional) `nix flake check`, `nix build .#`

4. After that `rebuild test` first and then `switch` for every host.

### Modules

These modules are tested to be imported elsewhere:

```nix
inputs.schallernetz.url = "git+file:../schallernetz?shallow=1";

inputs.schallernetz.nixosModules."systemd/ntfy"
```

## Structure

The flakes structure is similar to my [dotfiles](https://github.com/dafitt/dotfiles?tab=readme-ov-file#structure), but without home-manager.
