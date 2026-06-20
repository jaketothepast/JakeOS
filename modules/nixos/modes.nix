{ config, lib, pkgs, inputs, ... }:
let
  # Build an /etc/hosts blob that null-routes a list of domains (and their www.).
  blockHosts = domains:
    lib.concatMapStringsSep "\n"
      (d: "0.0.0.0 ${d}\n0.0.0.0 www.${d}")
      domains;

  # ---- Per-mode block lists -------------------------------------------------
  # WORK: kill the named time-sinks. Discord is personal; Reddit + LinkedIn are
  # "work-adjacent but a time sink" per the user.
  workBlocked = [
    "reddit.com" "old.reddit.com" "new.reddit.com" "i.redd.it" "v.redd.it"
    "linkedin.com"
    "discord.com" "discordapp.com" "discord.gg"
    "youtube.com" "news.ycombinator.com" "x.com" "twitter.com"
  ];

  # PERSONAL: no work tooling. Slack is work-only; add your employer domains here.
  personalBlocked = [
    "slack.com" "app.slack.com"
    # "yourcompany.example.com"   # <- add real work domains
    # "jira.yourcompany.com" "github.com/yourcompany"
  ];

  # ---- WORK browser allow-list (Firefox WebsiteFilter is default-DENY) -------
  # Everything not listed is blocked IN THE BROWSER. CLIs/agents are unaffected.
  workAllowExceptions = [
    "*://*.github.com/*" "*://github.com/*"
    "*://*.githubusercontent.com/*"
    "*://*.anthropic.com/*" "*://*.claude.ai/*"
    "*://*.openai.com/*"
    "*://*.stackoverflow.com/*" "*://stackoverflow.com/*"
    "*://*.google.com/*" "*://google.com/*"
    "*://*.gitlab.com/*"
    "*://*.npmjs.com/*" "*://*.pypi.org/*" "*://*.crates.io/*"
    "*://*.nixos.org/*" "*://*.mozilla.org/*"
    "*://*.focusmate.com/*"        # body-doubling (allow-listed on purpose)
    # "*://*.yourcompany.example.com/*"   # <- add your real work domains
  ];

  # Common groups for a non-privileged daily user (NOT wheel → cannot rebuild).
  dailyGroups = [ "networkmanager" "audio" "video" "input" ];
in
{
  # ===========================================================================
  #  Shared admin account — the ONLY account that can rebuild the system.
  #  This is the deliberate, high-friction (not impossible) "unblock" valve:
  #  to change a block you must switch to admin, edit Nix, and rebuild.
  # ===========================================================================
  users.users.admin = {
    isNormalUser = true;
    description = "Administrator (rebuilds only — do not daily-drive)";
    extraGroups = [ "wheel" "networkmanager" ];
    hashedPasswordFile = "/persist/passwords/admin";
  };
  nix.settings.trusted-users = [ "root" "admin" ];
  home-manager.users.admin = import ../../home/admin.nix;

  # sudo (and therefore nixos-rebuild) is restricted to wheel; daily users aren't
  # in wheel, so they cannot rebuild. This is intentional.
  security.sudo.execWheelOnly = true;

  # ===========================================================================
  #  WORK MODE  (boot entry: "work")
  # ===========================================================================
  specialisation.work.configuration = {
    system.nixos.tags = [ "work" ];

    users.users.jacob-work = {
      isNormalUser = true;
      description = "Jacob — work";
      extraGroups = dailyGroups;
      hashedPasswordFile = "/persist-work/passwords/jacob-work";
    };
    home-manager.users.jacob-work = import ../../home/jacob-work.nix;

    # Autologin straight into niri as the work user.
    services.greetd.settings.initial_session = {
      command = "niri-session";
      user = "jacob-work";
    };

    # Encrypted work data — unlocked ONLY in this mode (passphrase B).
    boot.initrd.luks.devices.cryptwork = {
      device = "/dev/disk/by-uuid/REPLACE-LUKS-CRYPTWORK-UUID";
      allowDiscards = true;
    };
    fileSystems."/persist-work" = {
      device = "/dev/mapper/cryptwork";
      fsType = "btrfs";
      options = [ "subvol=@persist" "compress=zstd" "noatime" ];
      neededForBoot = true;
    };
    environment.persistence."/persist-work" = {
      hideMounts = true;
      users.jacob-work = {
        directories = [
          "org"
          ".ssh"
          ".gnupg"
          ".mozilla"                    # browser profile: 2FA/session cookies
          ".local/share/keyrings"
          ".config/doom"
          ".config/gh"
          ".local/share/doom"           # Doom built packages
          ".local/share/emacs"
          ".local/state/home-manager"
          ".cargo" ".rustup" ".npm" ".cache/pip"
          { directory = ".local/share/org-roam"; mode = "0700"; }
          { directory = "code"; }        # work repos
        ];
      };
    };

    # Block the time-sinks at the hosts layer (CLIs honor this too via resolver).
    networking.extraHosts = blockHosts workBlocked;

    # Browser is default-deny in work mode; only the allow-list gets through.
    programs.firefox.policies.WebsiteFilter = {
      Block = [ "<all_urls>" ];
      Exceptions = workAllowExceptions;
    };
  };

  # ===========================================================================
  #  PERSONAL MODE  (boot entry: "personal")
  # ===========================================================================
  specialisation.personal.configuration = {
    system.nixos.tags = [ "personal" ];

    users.users.jacob-personal = {
      isNormalUser = true;
      description = "Jacob — personal";
      extraGroups = dailyGroups;
      hashedPasswordFile = "/persist-personal/passwords/jacob-personal";
    };
    home-manager.users.jacob-personal = import ../../home/jacob-personal.nix;

    services.greetd.settings.initial_session = {
      command = "niri-session";
      user = "jacob-personal";
    };

    boot.initrd.luks.devices.cryptpersonal = {
      device = "/dev/disk/by-uuid/REPLACE-LUKS-CRYPTPERSONAL-UUID";
      allowDiscards = true;
    };
    fileSystems."/persist-personal" = {
      device = "/dev/mapper/cryptpersonal";
      fsType = "btrfs";
      options = [ "subvol=@persist" "compress=zstd" "noatime" ];
      neededForBoot = true;
    };
    environment.persistence."/persist-personal" = {
      hideMounts = true;
      users.jacob-personal = {
        directories = [
          "org"
          ".ssh"
          ".gnupg"
          ".mozilla"
          ".local/share/keyrings"
          ".config/doom"
          ".local/share/doom"
          ".local/share/emacs"
          ".local/state/home-manager"
          ".cache/pip"
          { directory = ".local/share/org-roam"; mode = "0700"; }
        ];
      };
    };

    # Personal mode blocks work tooling/domains. No default-deny browser filter
    # here (relaxed personal browsing, minus the blocked hosts + uBlock).
    networking.extraHosts = blockHosts personalBlocked;
  };
}
