# [agenix](https://github.com/ryantm/agenix)

# NOTE This file is only used for the agenix command.
let
  # public ssh keys of machines, that will have access to the secrets
  # the corresponding private keys will be able to decrypt them
  # grab them through #$ ssh-keyscan user@host
  keys = [
    "***REMOVED_SSH-PUBLICKEY***" # david@DavidDESKTOP
    "***REMOVED_SSH-PUBLICKEY***" # david@DavidLEGION
    "***REMOVED_SSH-PUBLICKEY***" # minisforumhm80
  ];
in
{
  # 1. New entry with allowed keys `"secret1.age".publicKeys = keys;`
  # 2. Create the secret file #$ nix run github:ryantm/agenix -- -e secret1.age
  # 3. Import to your NixOS configuration `age.secrets."secret1".file = ../secrets/secret1.age;`
  # 4. Use it with `config.age.secrets."secret1".path;`

  "searx.age".publicKeys = keys;
}
