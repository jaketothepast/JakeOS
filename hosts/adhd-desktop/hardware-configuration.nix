###############################################################################
#  PLACEHOLDER hardware-configuration.nix
#
#  Disk layout + filesystems + LUKS are now declared in
#  ../../modules/nixos/disko.nix — NOT here. This file is ONLY the
#  machine-specific hardware scan. Regenerate the hardware bits with:
#
#    sudo nixos-generate-config --root /mnt --no-filesystems
#
#  ...then copy its `boot.initrd.availableKernelModules`, `boot.kernelModules`,
#  and any `hardware.cpu.*.updateMicrocode` lines into the block below.
#  (Keep `--no-filesystems` so it does NOT emit fileSystems — disko owns those.)
###############################################################################
{ config, lib, modulesPath, ... }:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  # --- REPLACE with the generated lists from nixos-generate-config ---
  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ]; # or "kvm-amd"
  boot.extraModulePackages = [ ];

  swapDevices = [ ];

  networking.useDHCP = lib.mkDefault true;
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
