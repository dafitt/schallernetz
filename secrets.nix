# [agenix](https://github.com/ryantm/agenix)

# NOTE This file is only used for the agenix command.
let
  # USERs
  #$ cat ~/.ssh/id_ed25519.pub
  david = [
    "***REMOVED_SSH-PUBLICKEY***" # manually
    "***REMOVED_SSH-PUBLICKEY*** david@DavidDESKTOP"
    "***REMOVED_SSH-PUBLICKEY*** david@DavidLEGION"
  ];

  # SYSTEMs root@<host>
  #$ ssh-keyscan <host>
  #$ cat /etc/ssh/ssh_host_ed25519_key.pub
  minisforumhm80 = "***REMOVED_SSH-PUBLICKEY***";
  barebonej3160 = "***REMOVED_SSH-PUBLICKEY***";
in
{
  # 1. New entry: `"FILE.age".publicKeys = allowedKeys;`
  # 2. #$ nix run github:ryantm/agenix -- -e FILE.age
  # 3. NixOS configuration import: `age.secrets."FILE" = { file = ./FILE.age; };`
  # 4. Use it with: `config.age.secrets."FILE".path;`

  "modules/nixos/backups/minisforumhm80.age".publicKeys = [ minisforumhm80 ] ++ david;
  "modules/nixos/servers/ACME_DODE.age".publicKeys = [ minisforumhm80 ] ++ david;
  "modules/nixos/servers/DavidCAL/DavidCAL-backup.age".publicKeys = [ minisforumhm80 ] ++ david;
  "modules/nixos/servers/DavidCAL/DavidCAL-users.age".publicKeys = [ minisforumhm80 ] ++ david;
  "modules/nixos/servers/wireguard-lan/DDNS-K57174-49283.age".publicKeys = [ barebonej3160 minisforumhm80 ] ++ david;
  "modules/nixos/servers/wireguard-lan/private.key.age".publicKeys = [ barebonej3160 minisforumhm80 ] ++ david;
  "modules/nixos/servers/searx/searx.age".publicKeys = [ minisforumhm80 ] ++ david;

  # Edit #$ nix run github:ryantm/agenix -- -e FILE -i PRIVATE_KEY
  # Rekey #$ nix run github:ryantm/agenix -- -r -i PRIVATE_KEY
}
