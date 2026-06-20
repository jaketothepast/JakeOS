{ config, lib, pkgs, inputs, ... }:
{
  # =============================================================================
  #  Impermanence: the root subvolume (@root -> "/") is rolled back to a pristine
  #  blank snapshot on every boot. Nothing survives unless it is explicitly listed
  #  below or under a per-mode /persist-<mode> in modes.nix. This makes imperative
  #  drift physically impossible — the machine always equals the Nix config.
  #
  #  ONE-TIME INSTALL STEP (see docs/MANUAL.md): after creating the @root subvolume
  #  but before first boot, snapshot it empty:
  #     btrfs subvolume snapshot -r /mnt/@root /mnt/@root-blank
  # =============================================================================

  # mutableUsers=false is MANDATORY under impermanence: /etc/shadow lives on the
  # wiped root, so passwords must come from files on a persisted volume.
  users.mutableUsers = false;

  # Use the systemd-based initrd so the rollback can be a real ordered unit.
  boot.initrd.systemd.enable = true;

  boot.initrd.systemd.services.rollback-root = {
    description = "Rollback btrfs @root to a blank snapshot";
    wantedBy = [ "initrd.target" ];
    after = [ "systemd-cryptsetup@cryptroot.service" ];
    before = [ "sysroot.mount" ];
    unitConfig.DefaultDependencies = "no";
    serviceConfig.Type = "oneshot";
    script = ''
      mkdir -p /mnt
      mount -o subvol=/ /dev/mapper/cryptroot /mnt

      # Delete the live @root and any nested subvolumes it accumulated.
      btrfs subvolume list -o /mnt/@root | cut -f9 -d' ' | while read -r sub; do
        btrfs subvolume delete "/mnt/$sub"
      done
      btrfs subvolume delete /mnt/@root

      # Restore a fresh, empty @root from the read-only blank snapshot.
      btrfs subvolume snapshot /mnt/@root-blank /mnt/@root

      umount /mnt
    '';
  };

  # SSH host keys must persist: they survive the wipe so (a) `known_hosts` doesn't
  # churn and (b) sops-nix can derive its age key from the host key to decrypt
  # secrets. openssh is enabled mainly to guarantee the keys exist.
  services.openssh = {
    enable = true;
    openFirewall = false; # not exposed; we just want host-key generation
  };

  # ---- System-level persistent state (available in BOTH modes) ----
  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      "/var/log"
      "/var/lib/nixos"
      "/var/lib/systemd/coredump"
      "/var/lib/bluetooth"
      "/var/lib/adguardhome"
      "/etc/NetworkManager/system-connections"
    ];
    files = [
      "/etc/machine-id"
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_ed25519_key.pub"
      "/etc/ssh/ssh_host_rsa_key"
      "/etc/ssh/ssh_host_rsa_key.pub"
    ];
  };

  # sops-nix derives its decryption key from the persisted SSH host key. Secrets
  # are decrypted at activation (after /persist mounts) — NOT boot-critical, so we
  # avoid the neededForUsers ordering trap. User passwords use hashedPasswordFile
  # (plain files on /persist), not sops. See modules/nixos/modes.nix.
  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
}
