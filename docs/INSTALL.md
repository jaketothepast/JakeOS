# Installing on a new machine

Partitioning is **declarative** — `disko` (in `modules/nixos/disko.nix`) does the
partition + LUKS + btrfs + mount for you. You don't run `fdisk`/`cryptsetup`/`mkfs`
or hunt for UUIDs. **This erases the target disk.**

Disk layout disko creates (one encrypted container, subvolumes inside):

```
DISK
├─ ESP (vfat)                 -> /boot
└─ LUKS "cryptroot" (btrfs)
   ├─ @root          -> /
   ├─ @nix           -> /nix
   ├─ @home-work     -> /home/jacob-work     (mounted only in work mode)
   └─ @home-personal -> /home/jacob-personal (mounted only in personal mode)
```

One passphrase, one boot prompt. (Isolation is mount-based: the daily non-root user
can't reach the other mode's home — see MANUAL §3.)

---

## 1. Boot the installer

1. Flash the **NixOS minimal ISO**, boot it (Secure Boot off).
2. Online: ethernet just works; wifi via `nmcli device wifi connect "SSID" password "PASS"`.
3. `sudo -i`.

---

## 2. Get the config + pick the disk

```sh
nix-shell -p git
git clone https://github.com/jaketothepast/JakeOS
cd JakeOS

lsblk                                  # find your disk (e.g. nvme0n1, sda)
nano modules/nixos/disko.nix           # set:  device = "/dev/nvme0n1";
```

(Optional, for correct hardware modules) capture them now to paste in step 5:

```sh
nixos-generate-config --no-filesystems --show-hardware-config > /tmp/hw.nix
```

---

## 3. Partition + format + mount — one command (disko)

```sh
# Your disk passphrase (disko reads it to set up LUKS):
echo -n 'your-disk-passphrase' > /tmp/secret.key

# DESTROYS the disk, then formats + mounts the system under /mnt:
sudo nix --experimental-features 'nix-command flakes' \
  run github:nix-community/disko -- \
  --mode destroy,format,mount --flake .#adhd-desktop
```

That's the whole "partitioning." disko creates all subvolumes and mounts `/`,
`/nix`, and `/boot` under `/mnt`. The `@home-work` / `@home-personal` subvolumes are
created but *not* mounted now — each is mounted later, per-mode, at boot.

---

## 4. Put the config on the target (for future rebuilds)

```sh
mkdir -p /mnt/etc
cp -r ../JakeOS /mnt/etc/nixos
```

---

## 5. Machine-specific bits

- Paste the hardware modules from `/tmp/hw.nix` (step 2) — the
  `boot.initrd.availableKernelModules` / `boot.kernelModules` / microcode lines —
  into `/mnt/etc/nixos/hosts/adhd-desktop/hardware-configuration.nix`. (Defaults
  often work, but this is the safe move.)
- Optional now: timezone in `hosts/adhd-desktop/default.nix`, real work domains in
  `modules/nixos/blocklist.nix`, and for an older non-RTX GPU set
  `hardware.nvidia.open = false` in `modules/nixos/boot.nix`.

---

## 6. Passwords + lock the flake

```sh
mkdir -p /mnt/var/lib/adhd-secrets
mkpasswd -m sha-512 | tee /mnt/var/lib/adhd-secrets/admin.pw
mkpasswd -m sha-512 | tee /mnt/var/lib/adhd-secrets/jacob-work.pw
mkpasswd -m sha-512 | tee /mnt/var/lib/adhd-secrets/jacob-personal.pw
chmod 600 /mnt/var/lib/adhd-secrets/*.pw

cd /mnt/etc/nixos
nix --experimental-features 'nix-command flakes' flake lock   # pin inputs
```

---

## 7. Install

```sh
nixos-install --flake /mnt/etc/nixos#adhd-desktop --no-root-passwd
reboot
```

Root login is disabled by design; you log in as `admin` (rebuilds) or a daily user.
First build pulls CUDA + niri — the binary caches keep it reasonable, but give it time.

---

## 8. First boot

1. The **systemd-boot menu** shows entries tagged **work** and **personal** (plus an
   untagged admin/recovery entry, and older generations as you accrue them). Pick a mode.
2. Enter the disk passphrase **once** (single LUKS now).
3. You autologin into niri. **First login runs `doom-sync`** (clones + builds Doom) —
   a few minutes; the agenda frame appears when it finishes.
4. `mkdir -p ~/org ~/org/roam`, then capture with `Mod+N`.

---

## Even more automated (optional)

- **One-shot:** `disko-install` does format + install together:
  `sudo nix run github:nix-community/disko#disko-install -- --flake .#adhd-desktop --disk main /dev/nvme0n1`
  (`--disk main <dev>` overrides the device so you don't edit `disko.nix`). You'd
  still place the `.pw` files — easiest via `nixos-anywhere --extra-files`.
- **Remote from your Mac:** boot the target into the installer (it has SSH), then
  `nix run github:nix-community/nixos-anywhere -- --flake .#adhd-desktop root@<target-ip>`.
  With an encrypted root you'll want a keyfile or initrd-SSH unlock; local install is
  simpler for the first run.

---

## Troubleshooting

- **Black screen after picking a mode (NVIDIA):** the known niri+NVIDIA risk. Switch
  to a TTY (`Ctrl+Alt+F2`), log in as `admin`, `journalctl -b -u greetd`. Try
  `hardware.nvidia.open = false` (older GPUs) or fall back to Sway. Rebuild as `admin`.
- **No network for `doom-sync`:** connect with `nmcli`, then
  `systemctl --user restart doom-sync` (or `~/.config/emacs/bin/doom sync`).
- **A site you need is blocked:** by design — MANUAL §7 (log in as `admin`, edit
  `modules/nixos/blocklist.nix`, rebuild).
- **Rebuild as admin:** `sudo nixos-rebuild switch --flake /etc/nixos#adhd-desktop`.
