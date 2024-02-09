# [agenix](https://github.com/ryantm/agenix)

# NOTE This file is only used for the agenix command.
let
  # public ssh keys of machines, that will have access to the secrets
  # the corresponding private keys will be able to decrypt them
  # grab them through #$ ssh-keyscan host

  # USERS
  david = "***REMOVED_SSH-PUBLICKEY***";

  # MACHINES
  minisforumhm80 = "***REMOVED_SSH-PUBLICKEY***"; # minisforumhm80
in
{
  # 1. New entry with allowed keys `"FILE.age".publicKeys = keys;`
  # 2. Create the secret file #$ nix run github:ryantm/agenix -- -e FILE.age
  # 3. Import to your NixOS configuration `age.secrets."FILE".file = ../secrets/FILE.age;`
  # 4. Use it with `config.age.secrets."FILE".path;`

  "haproxy-www-ssl.pem.age".publicKeys = [ david minisforumhm80 ];
  "searx.age".publicKeys = [ david minisforumhm80 ];

  # Edit #$ nix run github:ryantm/agenix -- -e FILE -i PRIVATE_KEY
  # Rekey #$ nix run github:ryantm/agenix -- -r -i PRIVATE_KEY
}
