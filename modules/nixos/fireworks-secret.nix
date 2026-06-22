# Fireworks API key via sops-nix. Imported INSIDE specialisation.work (see
# modes.nix) so that `config` here resolves to the work specialisation's config —
# needed because config.sops.placeholder.* only exists where the secret is
# declared, and an inline attrset in modes.nix would see the base config instead.
#
# Encrypted at rest in secrets/secrets.yaml (committed), decrypted at activation
# to a mode-restricted tmpfs under /run/secrets — never the world-readable store.
# Decryption identity is the host SSH key (sops.age.sshKeyPaths in base.nix);
# recipients are in .sops.yaml. To set/rotate the key:
#     cd /etc/nixos && sops secrets/secrets.yaml
{ config, ... }:
{
  sops.defaultSopsFile = ../../secrets/secrets.yaml;

  # The raw secret (file at /run/secrets/fireworks_api_key). Declaring it makes
  # config.sops.placeholder.fireworks_api_key available to the template below.
  sops.secrets.fireworks_api_key = { };

  # A raw secret file isn't a valid systemd EnvironmentFile, so render a KEY=value
  # file the Emacs user service can load (wired up in home-manager/work.nix).
  # Owned by jacob-work so that user's `systemd --user` service can read it.
  sops.templates."fireworks-env" = {
    content = "FIREWORKS_API_KEY=${config.sops.placeholder.fireworks_api_key}";
    owner = "jacob-work";
  };
}
