# Our Snowfall🌨️🍂 NixOS❄️ servers

-   [Our Snowfall🌨️🍂 NixOS❄️ servers](#our-snowfall️-nixos️-servers)
    -   [Usage](#usage)
        -   [Upgrading](#upgrading)
        -   [Modules](#modules)

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
