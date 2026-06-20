{ pkgs, ... }:
{
  # Work mode only. Personal mode never installs these, and the work-encrypted
  # /persist-work is never mounted in personal — so there is no work data bleed.
  home.packages = with pkgs; [
    slack
  ];

  # A flag the Doom config can read to label the agenda / tweak behavior.
  home.sessionVariables.ADHD_MODE = "work";

  # Work org + roam live in ~/org (persisted under /persist-work). Same path as
  # personal, but a different encrypted volume → contents never mix.
}
