{ config, lib, pkgs, inputs, ... }:
let
  # AI coding agents, auto-updated upstream (numtide/llm-agents.nix).
  # If an attr name has changed upstream, adjust here (see `nix flake show`).
  aiAgents = inputs.llm-agents.packages.${pkgs.system};
  pi = pkgs.callPackage ../../pkgs/pi.nix { };

  # ---- Small ADHD/focus helper scripts -------------------------------------
  # Global org-capture: opens a tiny self-destructing Emacs frame, captures,
  # closes. This is the 2-second "offload a thought and get back to work" path.
  org-capture-frame = pkgs.writeShellScriptBin "org-capture-frame" ''
    exec ${pkgs.emacs-pgtk}/bin/emacsclient -a "" -n -c -F '((name . "doom-capture"))' \
      -e '(my/org-capture-frame)'
  '';

  # Focus toggle = Do-Not-Disturb on/off (dunst paused = notifications batched,
  # replayed later). One key for "I'm focusing now" and "I'm back".
  focus-toggle = pkgs.writeShellScriptBin "focus-toggle" ''
    ${pkgs.dunst}/bin/dunstctl set-paused toggle
    if [ "$(${pkgs.dunst}/bin/dunstctl is-paused)" = "true" ]; then
      ${pkgs.libnotify}/bin/notify-send "Focus on" "Notifications paused. One thing." 2>/dev/null || true
    else
      ${pkgs.libnotify}/bin/notify-send "Focus off" "Notifications back." 2>/dev/null || true
    fi
  '';
in
{
  options.adhd = {
    mode = lib.mkOption {
      type = lib.types.enum [ "work" "personal" ];
      description = "Which mode this home profile is for.";
    };
  };

  config = {
    programs.home-manager.enable = true;

    # =========================================================================
    #  Shell & terminal
    # =========================================================================
    programs.zsh = {
      enable = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
      shellAliases = {
        ll = "eza -la --git";
        cat = "bat -p";
        # On a daily (non-wheel) user, rebuilds fail by design — this reminds you.
        rebuild = "echo 'Rebuilds run as the admin user — see docs/MANUAL.md (Unblocking).'";
      };
    };
    programs.starship.enable = true;
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
    programs.fzf.enable = true;
    programs.bat.enable = true;
    programs.eza.enable = true;

    programs.kitty = {
      enable = true;
      settings = {
        enable_audio_bell = false;
        confirm_os_window_close = 0;
        background_opacity = "0.98";
        scrollback_lines = 10000;
      };
      font = {
        name = "JetBrainsMono Nerd Font";
        size = 13;
      };
    };

    programs.git = {
      enable = true;
      extraConfig = {
        init.defaultBranch = "main";
        pull.rebase = true;
      };
    };

    # Application launcher (curated, fuzzy — fewer choices = less wandering).
    programs.fuzzel.enable = true;

    # =========================================================================
    #  Packages: dev toolchain, AI agents, focus helpers
    # =========================================================================
    home.packages = with pkgs; [
      # Dev
      ripgrep fd git gnumake gcc nodejs python3 jq

      # AI coding agents (full network egress — never restricted)
      aiAgents.claude-code
      aiAgents.codex
      aiAgents.opencode
      pi

      # Focus / capture tooling (pomodoro is org-pomodoro inside Doom, not a separate app)
      org-capture-frame focus-toggle
      libnotify

      # Desktop bits used by the niri config
      fuzzel
      wl-clipboard
      brightnessctl
    ];

    # EDITOR/VISUAL are set by services.emacs.defaultEditor below — don't double-set.

    # =========================================================================
    #  Emacs daemon + Doom (kept close to stock)
    # =========================================================================
    programs.emacs = {
      enable = true;
      package = pkgs.emacs-pgtk; # Wayland-native
    };
    services.emacs = {
      enable = true;
      defaultEditor = true;
    };

    # Tracked Doom config → ~/.config/doom (read-only symlink; Doom reads it).
    xdg.configFile."doom".source = ../../doom;

    # Doom itself is cloned imperatively and synced by a systemd USER oneshot
    # (NOT a home-manager activation script — activation has an empty PATH and no
    # network ordering). The Emacs daemon waits for this to finish.
    systemd.user.services.doom-sync = {
      Unit = {
        Description = "Clone (if needed) and sync Doom Emacs";
        After = [ "network-online.target" ];
        Wants = [ "network-online.target" ];
        Before = [ "emacs.service" ];
      };
      Service = {
        Type = "oneshot";
        RemainAfterExit = true;
        Environment = [
          "PATH=${lib.makeBinPath [ pkgs.git pkgs.emacs-pgtk pkgs.ripgrep pkgs.fd pkgs.coreutils pkgs.gnutar pkgs.gzip pkgs.openssh ]}"
          "DOOMDIR=%h/.config/doom"
        ];
        ExecStart = pkgs.writeShellScript "doom-sync" ''
          set -eu
          EMACSDIR="$HOME/.config/emacs"
          if [ ! -d "$EMACSDIR/.git" ]; then
            git clone --depth=1 https://github.com/doomemacs/doomemacs "$EMACSDIR"
            "$EMACSDIR/bin/doom" install --no-config --no-env --force
          fi
          "$EMACSDIR/bin/doom" sync
        '';
      };
      Install.WantedBy = [ "default.target" ];
    };
    # Ensure the daemon starts after a sync.
    systemd.user.services.emacs.Unit.After = [ "doom-sync.service" ];

    # =========================================================================
    #  Notifications — default to DND/paused (batched, replayed on demand)
    # =========================================================================
    services.dunst = {
      enable = true;
      settings = {
        global = {
          monitor = 0;
          follow = "mouse";
          width = 380;
          offset = "16x16";
          frame_width = 1;
          font = "JetBrainsMono Nerd Font 10";
          # We start paused via niri startup (below); this just sets behavior.
        };
      };
    };

    # =========================================================================
    #  niri config — written as raw KDL for robustness across niri-flake versions.
    #  (If niri-flake also manages this file on your version, remove one source.)
    # =========================================================================
    xdg.configFile."niri/config.kdl".text = ''
      // ADHD niri config — minimal, keyboard-driven, one-thing-at-a-time.
      input {
          keyboard { xkb { layout "us" } }
          focus-follows-mouse max-scroll-amount="0%"
      }

      layout {
          gaps 12
          center-focused-column "never"
          default-column-width { proportion 1.0; }   // new windows take full column → monotasking
          focus-ring { width 2; }
      }

      // Startup: notifications paused, bar up, Xwayland bridge, agenda first.
      spawn-at-startup "sh" "-c" "${pkgs.dunst}/bin/dunstctl set-paused true"
      spawn-at-startup "waybar"
      // Lazy Xwayland (eager start has black-screened niri on NVIDIA — #2771).
      spawn-at-startup "sh" "-c" "xwayland-satellite || true"
      // Open the daily agenda first — the first thing you see is "what's next".
      spawn-at-startup "sh" "-c" "sleep 3; ${pkgs.emacs-pgtk}/bin/emacsclient -a emacs -c -e '(org-agenda nil \"d\")'"

      environment {
          DISPLAY ":0"   // for Xwayland-satellite clients
          NIXOS_OZONE_WL "1"
      }

      prefer-no-csd

      // ── The 5 you actually use all day ──────────────────────────────────
      binds {
          "Mod+N"           { spawn "org-capture-frame"; }   // 2-second capture
          "Mod+Return"      { spawn "kitty"; }               // terminal
          "Mod+D"           { spawn "fuzzel"; }              // launcher
          "Mod+Q"           { close-window; }                // close window
          "Mod+Shift+F"     { spawn "focus-toggle"; }        // focus on/off (DND)

          // ── Moving around (niri = windows sit side-by-side in a row) ──────
          "Mod+Left"        { focus-column-left; }           // previous window
          "Mod+Right"       { focus-column-right; }          // next window
          "Mod+O"           { toggle-overview; }             // zoom out, see everything
          "Mod+F"           { maximize-column; }             // (un)maximize current

          // ── Workspaces: fixed homes for tasks (e.g. 1=code, 2=comms) ─────
          "Mod+1"           { focus-workspace 1; }
          "Mod+2"           { focus-workspace 2; }
          "Mod+3"           { focus-workspace 3; }
          "Mod+Shift+1"     { move-column-to-workspace 1; }  // send window → ws 1
          "Mod+Shift+2"     { move-column-to-workspace 2; }
          "Mod+Shift+3"     { move-column-to-workspace 3; }

          "Mod+Shift+Slash" { show-hotkey-overlay; }         // "what are the keys?"
          "Mod+Shift+E"     { quit; }                        // log out of niri

          "XF86AudioRaiseVolume" { spawn "sh" "-c" "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"; }
          "XF86AudioLowerVolume" { spawn "sh" "-c" "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"; }
          "XF86AudioMute"        { spawn "sh" "-c" "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"; }
      }
    '';

    # =========================================================================
    #  waybar — TWO elements only: current org task + clock. No tray, no
    #  workspaces — nothing clickable that invites wandering.
    # =========================================================================
    programs.waybar = {
      enable = true;
      settings.mainBar = {
        layer = "top";
        position = "top";
        height = 28;
        modules-left = [ ];
        modules-center = [ "custom/orgclock" ];
        modules-right = [ "clock" ];
        "custom/orgclock" = {
          # Shows the currently-clocked org task (time-blindness + focus anchor).
          exec = "${pkgs.emacs-pgtk}/bin/emacsclient -e '(if (org-clocking-p) (org-clock-get-clock-string) \"--\")' 2>/dev/null | sed 's/^\"//; s/\"$//'";
          interval = 10;
          format = "🕓 {}";
        };
        clock = {
          format = "{:%a %d %b  %H:%M}"; # always-visible date+time (time-blindness)
          tooltip-format = "<tt>{calendar}</tt>";
        };
      };
      style = ''
        * { font-family: "JetBrainsMono Nerd Font"; font-size: 12px; }
        window#waybar { background: #1e1e2e; color: #cdd6f4; }
        #clock, #custom-orgclock { padding: 0 10px; }
      '';
    };
  };
}
