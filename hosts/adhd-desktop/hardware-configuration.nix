###############################################################################
#  PLACEHOLDER hardware-configuration.nix
#
#  This is NOT a generated file. Replace it during install:
#
#    sudo nixos-generate-config --root /mnt --no-filesystems
#
#  ...then merge the generated `boot.initrd.availableKernelModules`,
#  `hardware.cpu.*.updateMicrocode`, and any extra `kernelModules` into the
#  block below. Keep the `fileSystems` / LUKS layout from THIS file.
#
#  Disk layout this config assumes (see docs/MANUAL.md "Install"):
#    - ESP            vfat            -> /boot
#    - cryptroot      LUKS (one pass) -> btrfs with subvolumes:
#                       @root -> /     (PERSISTENT — normal root, no wipe)
#                       @nix  -> /nix
#    - cryptwork      LUKS (same pass) -> /home/jacob-work     (mounted only in `work`)
#    - cryptpersonal  LUKS (same pass) -> /home/jacob-personal (mounted only in `personal`)
#
#  The per-mode volumes (cryptwork / cryptpersonal) are declared inside the
#  specialisations in ../../modules/nixos/modes.nix, NOT here.
###############################################################################
{ config, lib, modulesPath, ... }:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  # --- REPLACE with the generated list from nixos-generate-config ---
  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ]; # or "kvm-amd"
  boot.extraModulePackages = [ ];

  # --- Root LUKS container; unlocked in initrd for every mode ---
  # REPLACE the UUID with: blkid /dev/<your-luks-partition>
  boot.initrd.luks.devices.cryptroot = {
    device = "/dev/disk/by-uuid/REPLACE-LUKS-CRYPTROOT-UUID";
    allowDiscards = true;
  };

  # Normal persistent root (no impermanence). Files survive reboots.
  fileSystems."/" = {
    device = "/dev/mapper/cryptroot";
    fsType = "btrfs";
    options = [ "subvol=@root" "compress=zstd" "noatime" ];
  };

  fileSystems."/nix" = {
    device = "/dev/mapper/cryptroot";
    fsType = "btrfs";
    options = [ "subvol=@nix" "compress=zstd" "noatime" ];
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
