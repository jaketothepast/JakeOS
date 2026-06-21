{ ... }:
{
  # admin is the rebuild/recovery account — but it still needs a usable desktop
  # (niri keybinds, terminal, launcher), so it shares the common config.
  imports = [
    ../modules/home-manager/common.nix
  ];

  home.username = "admin";
  home.homeDirectory = "/home/admin";
  home.stateVersion = "25.11";

  adhd.mode = "admin";
}
