{ pkgs, ... }:
{
  # Work mode only. Personal mode never installs these, and the work home subvolume
  # (@home-work → /home/jacob-work) is never mounted in personal — and the daily
  # user isn't root, so it can't mount it either. No work data bleed.
  home.packages = with pkgs; [
    slack
  ];

  # A flag the Doom config can read to label the agenda / tweak behavior.
  home.sessionVariables.ADHD_MODE = "work";

  # All work data (org, roam, repos) lives in /home/jacob-work (@home-work subvol).
}
