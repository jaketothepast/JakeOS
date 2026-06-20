{ ... }:
{
  imports = [
    ../modules/home-manager/common.nix
    ../modules/home-manager/work.nix
  ];

  home.username = "jacob-work";
  home.homeDirectory = "/home/jacob-work";
  home.stateVersion = "25.11";

  # Surface the ADHD/focus toggles for this mode.
  adhd.mode = "work";
  adhd.grayscaleAtLogin = true; # work mode starts desaturated
}
