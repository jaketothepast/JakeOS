{ config, lib, pkgs, ... }:
{
  # Small system bits that used to live in impermanence.nix but are still needed
  # now that the root is a normal persistent btrfs subvolume.

  # SSH host key: persists naturally on the persistent root. sops-nix derives its
  # age decryption key from it to decrypt the AI-CLI API keys at activation.
  services.openssh = {
    enable = true;
    openFirewall = false; # not exposed; we just want the host key to exist
  };
  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

  # Immutable, fully-declarative users → each mode's /etc/passwd exactly matches
  # that mode (the work user does not even exist in personal mode). Passwords come
  # from hashed files under /var/lib/adhd-secrets created once at install (see
  # docs/MANUAL.md §10) — not from the world-readable Nix store.
  users.mutableUsers = false;
}
