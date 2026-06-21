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

  # ---- NVIDIA on a hybrid (Optimus) laptop: Intel UHD 630 + GTX 1050 Ti ----
  # The internal panel is wired to the Intel iGPU, so the Wayland compositor (niri)
  # renders on Intel — which also sidesteps the niri+NVIDIA black-screen issues.
  # NVIDIA stays available via PRIME *offload* for CUDA (Ollama) and on-demand apps.
  #
  # NOTE: GTX 1050 Ti is Pascal → the open kernel module is NOT supported here, so
  # `open = false` (proprietary). Open is only for Turing/RTX-20xx and newer.
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
  hardware.nvidia = {
    modesetting.enable = true;
    open = false; # Pascal — proprietary module required
    nvidiaSettings = true;
    powerManagement.enable = true; # restore GPU state across suspend/resume
    package = config.boot.kernelPackages.nvidiaPackages.stable;

    # Bus IDs from `lspci`: Intel 00:02.0 → PCI:0:2:0, NVIDIA 01:00.0 → PCI:1:0:0
    prime = {
      offload.enable = true;
      offload.enableOffloadCmd = true; # provides the `nvidia-offload` wrapper
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };
  boot.kernelParams = [ "nvidia_drm.modeset=1" ];

  # Firmware for wifi/bluetooth/etc.
  hardware.enableRedistributableFirmware = true;
}
