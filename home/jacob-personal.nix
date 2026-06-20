{ ... }:
{
  imports = [
    ../modules/home-manager/common.nix
    ../modules/home-manager/personal.nix
  ];

  home.username = "jacob-personal";
  home.homeDirectory = "/home/jacob-personal";
  home.stateVersion = "25.11";

  adhd.mode = "personal";
  adhd.grayscaleAtLogin = false; # personal mode keeps color
}
