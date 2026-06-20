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

  # NixOS release this config was written against. Do NOT bump casually.
  system.stateVersion = "25.11";
}
