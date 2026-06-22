{ inputs, config, lib, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos
  ];

  networking.hostName = "adhd-desktop";

  # ---- Locale / time (time-blindness aids care that this is correct) ----
  time.timeZone = lib.mkDefault "America/New_York";
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "us";

  # ---- Nix / nixpkgs ----
  nixpkgs.config.allowUnfree = true; # NVIDIA driver, Slack, CUDA, etc.
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
    # Binary caches so the first CUDA + niri build is not an overnight compile.
    substituters = [
      "https://cache.nixos.org"
      "https://cuda-maintainers.cachix.org"
      "https://niri.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
      "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
    ];
  };
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  networking.networkmanager.enable = true;

  # ---- Wi-Fi stability (Intel Wi-Fi 6 AX200) ----
  # The card is fine; the driver's default power management is not. With the
  # balanced power scheme the radio sleeps aggressively and drops association
  # (dmesg: "Not associated and the session protection is over already...").
  # Disable power-saving at both layers — this box is always on mains, so the
  # tiny power saving isn't worth flaky connectivity.
  networking.networkmanager.wifi.powersave = false;
  boot.extraModprobeConfig = ''
    options iwlwifi power_save=0
    options iwlmvm power_scheme=1
  '';

  # NixOS release this config was written against. Do NOT bump casually.
  system.stateVersion = "25.11";
}
