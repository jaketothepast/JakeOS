# Installing on a new machine

A full walkthrough. **This erases the target disk.** Read it once before starting.

The disk layout this config expects:

```
DISK
├─ p1  ESP (vfat)              -> /boot
├─ p2  LUKS "cryptroot"        -> btrfs: @root -> /, @nix -> /nix
├─ p3  LUKS "cryptwork"        -> /home/jacob-work     (mounted only in work mode)
└─ p4  LUKS "cryptpersonal"    -> /home/jacob-personal (mounted only in personal mode)
```

Use **one passphrase for all three** LUKS volumes (simplest; isolation comes from
each mode only *mounting* its own volume).

---

## 0. Get the config onto the machine

This repo currently lives only on your Mac (local git, no remote). Get it to the
new machine by either:

- **Push to a remote** (recommended): create a private repo (e.g. on GitHub) and
  `git push`, then clone it during install; **or**
- **USB/scp**: copy the whole `nixos-adhd-config/` folder onto a USB stick.

---

## 1. Boot the installer

1. Flash the **NixOS minimal ISO** to a USB stick, boot it (disable Secure Boot).
2. Get online: ethernet works out of the box; for wifi use `nmcli device wifi
   connect "SSID" password "PASS"`.
3. Become root: `sudo -i`.

---

## 2. Partition

```sh
# >>> CHECK THIS with `lsblk` and set it correctly. This ERASES the disk. <<<
DISK=/dev/nvme0n1

# helper: nvme/mmc disks name partitions p1,p2…; sata/usb name them 1,2…
part() { case "$DISK" in *nvme*|*mmcblk*) echo "${DISK}p$1";; *) echo "${DISK}$1";; esac; }

sgdisk --zap-all "$DISK"
sgdisk -n1:0:+1G    -t1:ef00 -c1:ESP            "$DISK"   # EFI system partition
sgdisk -n2:0:+120G  -t2:8309 -c2:cryptroot      "$DISK"   # system + /nix (tune size)
sgdisk -n3:0:+250G  -t3:8309 -c3:cryptwork      "$DISK"   # work home (tune size)
sgdisk -n4:0:0      -t4:8309 -c4:cryptpersonal  "$DISK"   # personal home (rest of disk)
partprobe "$DISK"
```

---

## 3. Encrypt + open the three LUKS volumes

```sh
# Type the SAME passphrase each time.
cryptsetup luksFormat "$(part 2)"
cryptsetup luksFormat "$(part 3)"
cryptsetup luksFormat "$(part 4)"

cryptsetup open "$(part 2)" cryptroot
cryptsetup open "$(part 3)" cryptwork
cryptsetup open "$(part 4)" cryptpersonal
```

---

## 4. Make filesystems

```sh
mkfs.fat -F32 -n BOOT "$(part 1)"

# root: one btrfs with two subvolumes
mkfs.btrfs -L nixos /dev/mapper/cryptroot
mount /dev/mapper/cryptroot /mnt
btrfs subvolume create /mnt/@root
btrfs subvolume create /mnt/@nix
umount /mnt

# the two encrypted home volumes (plain btrfs, no subvolume needed)
mkfs.btrfs -L work     /dev/mapper/cryptwork
mkfs.btrfs -L personal /dev/mapper/cryptpersonal
```

---

## 5. Mount everything under /mnt

```sh
mount -o subvol=@root,compress=zstd,noatime /dev/mapper/cryptroot /mnt
mkdir -p /mnt/nix /mnt/boot /mnt/home/jacob-work /mnt/home/jacob-personal
mount -o subvol=@nix,compress=zstd,noatime  /dev/mapper/cryptroot /mnt/nix
mount "$(part 1)" /mnt/boot
mount -o compress=zstd,noatime /dev/mapper/cryptwork     /mnt/home/jacob-work
mount -o compress=zstd,noatime /dev/mapper/cryptpersonal /mnt/home/jacob-personal

# Make each home writable by its user (UIDs are pinned in modules/nixos/modes.nix).
chown 1001:users /mnt/home/jacob-work
chown 1002:users /mnt/home/jacob-personal
```

---

## 6. Put the config in place + capture hardware details

```sh
# Generate hardware info (kernel modules etc.) — keep it to copy from in a moment.
nixos-generate-config --root /mnt --no-filesystems
cp /mnt/etc/nixos/hardware-configuration.nix /tmp/generated-hw.nix

# Replace /mnt/etc/nixos with THIS repo (clone your remote, or copy from USB):
rm -rf /mnt/etc/nixos
nix-shell -p git --run 'git clone <YOUR-REPO-URL> /mnt/etc/nixos'
#   …or: cp -r /run/media/…/nixos-adhd-config /mnt/etc/nixos
```

---

## 7. Fill in the machine-specific values

Get the UUIDs (these are the **LUKS partition / ESP** UUIDs):

```sh
blkid "$(part 2)"   # cryptroot container  -> UUID=...
blkid "$(part 3)"   # cryptwork container  -> UUID=...
blkid "$(part 4)"   # cryptpersonal        -> UUID=...
blkid "$(part 1)"   # ESP                  -> UUID=...
```

Edit two files (use `nano /mnt/etc/nixos/...`):

**`hosts/adhd-desktop/hardware-configuration.nix`**
- `cryptroot` device → the p2 UUID; `/boot` device → the ESP UUID.
- Replace the `boot.initrd.availableKernelModules`, `boot.kernelModules`, and any
  `hardware.cpu.*.updateMicrocode` lines with the ones from `/tmp/generated-hw.nix`.

**`modules/nixos/modes.nix`**
- `cryptwork` device → the p3 UUID; `cryptpersonal` device → the p4 UUID.

Optionally also now: set your timezone in `hosts/adhd-desktop/default.nix`, fill real
work domains in `modules/nixos/blocklist.nix`, and (for an older non-RTX GPU) flip
`hardware.nvidia.open` to `false` in `modules/nixos/boot.nix`.

---

## 8. Passwords + lock the flake

```sh
# Hashed password files for the (immutable) declarative users:
mkdir -p /mnt/var/lib/adhd-secrets
mkpasswd -m sha-512 | tee /mnt/var/lib/adhd-secrets/admin.pw
mkpasswd -m sha-512 | tee /mnt/var/lib/adhd-secrets/jacob-work.pw
mkpasswd -m sha-512 | tee /mnt/var/lib/adhd-secrets/jacob-personal.pw
chmod 600 /mnt/var/lib/adhd-secrets/*.pw

# Pin inputs so the build is reproducible:
cd /mnt/etc/nixos
nix --extra-experimental-features 'nix-command flakes' flake lock
```

---

## 9. Install

```sh
nixos-install --flake /mnt/etc/nixos#adhd-desktop --no-root-passwd
```

`--no-root-passwd` is correct here: root login is disabled by design; you log in as
`admin` (for rebuilds) or a daily user. First build pulls CUDA + niri — the binary
caches in `default.nix` keep it from being an overnight compile, but give it time.

```sh
reboot
```

---

## 10. First boot

1. The **systemd-boot menu** shows entries tagged **work** and **personal** (plus an
   untagged admin/recovery entry, and older generations once you have them). Pick a
   mode.
2. Enter the LUKS passphrase — **twice** (once for `cryptroot`, once for that mode's
   home volume). To collapse this to one prompt later, add a root-stored keyfile for
   the home volumes (advanced).
3. You autologin into niri. **First login runs `doom-sync`** (clones + builds Doom) —
   a few minutes; the agenda frame appears when it's done.
4. Set up org: `mkdir -p ~/org ~/org/roam`. Capture with `Mod+N`.

---

## Troubleshooting

- **Black screen after selecting a mode (NVIDIA):** this is the known niri+NVIDIA
  risk. Switch to a TTY (`Ctrl+Alt+F2`), log in as `admin`, and check
  `journalctl -b -u greetd`. Try `hardware.nvidia.open = false` (older GPUs) or, as a
  documented fallback, swap niri for Sway. Rebuild from `admin`.
- **No network for `doom-sync`:** connect with `nmcli`, then
  `systemctl --user restart doom-sync` (or just `~/.config/emacs/bin/doom sync`).
- **A site you need is blocked:** that's by design — see `docs/MANUAL.md §7`
  (log in as `admin`, edit `modules/nixos/blocklist.nix`, rebuild).
- **Rebuild as admin:** `sudo nixos-rebuild switch --flake /etc/nixos#adhd-desktop`.
