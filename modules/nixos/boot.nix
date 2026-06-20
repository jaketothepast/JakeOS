{ config, lib, pkgs, ... }:
{
  # ---- Bootloader: systemd-boot lists generations AND specialisations ----
  # The boot menu is the recovery net (pick a previous generation) and the mode
  # selector (work / personal entries). Keep enough entries to actually recover.
  boot.loader.systemd-boot = {
    enable = true;
    configurationLimit = 10;
    editor = false; # don't let the boot editor bypass kernel cmdline
  };
  boot.loader.efi.canTouchEfiVariables = true;

  boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;

  # ---- NVIDIA on Wayland (niri) ----
  # `open = true` is the better-supported Wayland path on Turing+ (RTX 20xx and
  # newer). If you have an older GTX card, set open = false in a host override.
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
  hardware.nvidia = {
    modesetting.enable = true;
    open = lib.mkDefault true;
    nvidiaSettings = true;
    powerManagement.enable = true; # restore GPU state across suspend/resume
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };
  boot.kernelParams = [ "nvidia_drm.modeset=1" ];

  # Firmware for wifi/bluetooth/etc.
  hardware.enableRedistributableFirmware = true;
}
