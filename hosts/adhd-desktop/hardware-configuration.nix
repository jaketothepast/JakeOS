###############################################################################
#  PLACEHOLDER hardware-configuration.nix
#
#  This is NOT a generated file. Replace it during install:
#
#    sudo nixos-generate-config --root /mnt --no-filesystems
#
#  ...then merge the generated `boot.initrd.availableKernelModules`,
#  `hardware.cpu.*.updateMicrocode`, and any extra `kernelModules` into the
#  block below. Keep the `fileSystems` / `swapDevices` / LUKS layout from THIS
#  file — it encodes the btrfs-subvolume + impermanence + shared-LUKS design.
#
#  Disk layout this config assumes (see docs/MANUAL.md "Install"):
#    - ESP            vfat            -> /boot
#    - cryptroot      LUKS (passA)    -> btrfs with subvolumes:
#                       @root    -> /        (WIPED to a blank snapshot each boot)
#                       @nix     -> /nix     (neededForBoot)
#                       @persist -> /persist (neededForBoot; system state)
#    - cryptwork      LUKS (passB)    -> /persist-work     (mounted only in `work`)
#    - cryptpersonal  LUKS (passC)    -> /persist-personal (mounted only in `personal`)
#
#  The per-mode volumes (cryptwork / cryptpersonal) are declared inside the
#  specialisations in ../../modules/nixos/modes.nix, NOT here, so each mode only
#  unlocks and mounts its own encrypted data.
###############################################################################
{ config, lib, modulesPath, ... }:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  # --- REPLACE with the generated list from nixos-generate-config ---
  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ]; # or "kvm-amd"
  boot.extraModulePackages = [ ];

  # --- Shared LUKS container (passphrase A); unlocked in initrd for every mode ---
  # REPLACE the UUID with: blkid /dev/<your-luks-partition>
  boot.initrd.luks.devices.cryptroot = {
    device = "/dev/disk/by-uuid/REPLACE-LUKS-CRYPTROOT-UUID";
    allowDiscards = true;
  };

  fileSystems."/" = {
    device = "/dev/mapper/cryptroot";
    fsType = "btrfs";
    options = [ "subvol=@root" "compress=zstd" "noatime" ];
  };

  fileSystems."/nix" = {
    device = "/dev/mapper/cryptroot";
    fsType = "btrfs";
    options = [ "subvol=@nix" "compress=zstd" "noatime" ];
    neededForBoot = true;
  };

  # System-level persistent state (ssh host key / sops age key, machine-id,
  # NetworkManager, AdGuard, Ollama). Available in BOTH modes.
  fileSystems."/persist" = {
    device = "/dev/mapper/cryptroot";
    fsType = "btrfs";
    options = [ "subvol=@persist" "compress=zstd" "noatime" ];
    neededForBoot = true;
  };

  # REPLACE the UUID with the ESP partition UUID (blkid).
  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/REPLACE-ESP-UUID";
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
  };

  swapDevices = [ ];

  networking.useDHCP = lib.mkDefault true;
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
