{ ... }:
{
  imports = [
    ../modules/home-manager/common.nix
    ../modules/home-manager/work.nix
  ];

  home.username = "jacob-work";
  home.homeDirectory = "/home/jacob-work";
  home.stateVersion = "25.11";

  adhd.mode = "work";
}
