{ pkgs, ... }:
{
  # Personal mode only. No Slack, no work tooling.
  home.packages = with pkgs; [
    discord
    mpv
  ];

  home.sessionVariables.ADHD_MODE = "personal";
}
