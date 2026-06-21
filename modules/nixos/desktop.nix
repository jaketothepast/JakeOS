{ config, lib, pkgs, ... }:
{
  # ---- niri compositor (scrollable tiling → linear, one-thing-at-a-time focus) ----
  # Provided by the niri-flake NixOS module (imported in flake.nix). This also
  # enables the niri.cachix.org binary cache so niri isn't compiled from source.
  programs.niri.enable = true;

  # X11 app support. niri is Wayland-only; xwayland-satellite bridges X11 clients.
  # NOTE (top build risk): on NVIDIA, eagerly autostarting xwayland-satellite has
  # caused black screens (niri #2771). We install it here but start it LAZILY from
  # the user's niri config (see modules/home-manager/common.nix), not system-wide.
  environment.systemPackages = with pkgs; [
    xwayland-satellite
    wl-clipboard
    brightnessctl
  ];

  # ---- Login: greetd + tuigreet (minimal) ----
  # Base provides a manual greeter as a fallback. Each MODE (modes.nix) overrides
  # with an autologin `initial_session` for that mode's single daily user.
  services.greetd = {
    enable = true;
    settings.default_session = {
      command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd niri-session";
      user = "greeter";
    };
  };

  # ---- Audio (PipeWire) ----
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };

  # ---- Portals (screenshare, file pickers) ----
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.niri = {
      default = [ "gnome" "gtk" ];
      "org.freedesktop.impl.portal.ScreenCast" = [ "gnome" ];
    };
  };
  # GNOME screencast portal is the one niri documents as working.
  services.dbus.implementation = "broker";

  # ---- Keyring / polkit (so apps can store secrets, prompt for auth) ----
  security.polkit.enable = true;
  services.gnome.gnome-keyring.enable = true;

  # ---- Fonts ----
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    nerd-fonts.symbols-only   # "Symbols Nerd Font" — Doom/nerd-icons glyphs
    noto-fonts
    noto-fonts-color-emoji
    noto-fonts-cjk-sans
  ];

  # ---- Bluetooth (optional but commonly wanted) ----
  hardware.bluetooth.enable = lib.mkDefault true;
}
