{ pkgs, ... }:
{
  # The admin account exists to rebuild the system, not to live in. Keep it lean:
  # a shell, an editor, git, and the niri/terminal basics to run nixos-rebuild.
  home.username = "admin";
  home.homeDirectory = "/home/admin";
  home.stateVersion = "25.11";

  programs.home-manager.enable = true;
  programs.git.enable = true;
  programs.zsh.enable = true;
  programs.starship.enable = true;

  home.packages = with pkgs; [
    vim
    git
    kitty
  ];
}
