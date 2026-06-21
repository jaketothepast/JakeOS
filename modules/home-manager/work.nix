{ pkgs, ... }:
{
  # Work mode only. Personal mode never installs these, and the work-encrypted
  # home volume (cryptwork → /home/jacob-work) is never mounted in personal —
  # so there is no work data bleed.
  home.packages = with pkgs; [
    slack
  ];

  # A flag the Doom config can read to label the agenda / tweak behavior.
  home.sessionVariables.ADHD_MODE = "work";

  # All work data (org, roam, repos) lives in /home/jacob-work on the encrypted
  # cryptwork volume — a different physical volume from personal, so they never mix.
}
