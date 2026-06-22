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

  # ===========================================================================
  #  tmux — tuned for running long-lived coding agents (Claude Code etc.)
  # ===========================================================================
  # The point of tmux here is process isolation + session persistence: start an
  # agent, detach (or lose the SSH/session), reattach later with the whole run —
  # scrollback, running build, conversation — still alive. Anthropic ships Agent
  # Teams with tmux as the split-pane backend, and Claude Code auto-detects tmux,
  # so this config leans into "several agents, each in its own window/pane."
  programs.tmux = {
    enable = true;
    keyMode = "vi";
    mouse = true;              # scroll/select long agent output without keybinds
    baseIndex = 1;             # windows start at 1 (matches the keyboard row)
    escapeTime = 0;            # no Esc delay → snappy TUIs (vim, the agent prompt)
    historyLimit = 100000;     # agents are verbose; keep a deep scrollback
    focusEvents = true;        # editors/agents learn when their pane (de)focuses
    terminal = "tmux-256color";

    extraConfig = ''
      # --- True color so agent TUIs render correctly (we launch kitty) ----------
      set -ga terminal-overrides ",*256col*:Tc,xterm*:Tc,kitty*:Tc"

      # --- Let agent escape sequences reach the OUTER terminal ------------------
      # Coding agents emit progress/notification/clipboard escape sequences. Without
      # passthrough, tmux swallows them and you lose desktop notifications, OSC-52
      # clipboard copies, and progress indicators.
      set -g allow-passthrough on
      set -g set-clipboard on               # OSC-52: copy from inside the agent → system clipboard

      # --- Extended keys: the Claude TUI needs to tell Shift+Enter from Enter ---
      set -s extended-keys on
      set -as terminal-features ",kitty*:extkeys,xterm*:extkeys"

      # --- "Which agent needs me?" ----------------------------------------------
      # Claude Code rings the terminal bell on Stop / permission prompts. Surface
      # that bell as a window flag in the status bar (NOT monitor-activity, which
      # would fire constantly on a streaming agent and tell you nothing).
      set -g monitor-bell on
      set -g bell-action other              # flag bells in *other* windows too
      set -g visual-bell off
      set -g window-status-bell-style "fg=red,bold"

      # --- Juggling several agent windows ---------------------------------------
      set -g pane-base-index 1
      set -g renumber-windows on            # close window 2 of 4 → no gap
      setw -g aggressive-resize on
      set -g status-interval 5

      # Splits that keep the current dir (spawn a sibling agent next to this one).
      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"
    '';
  };

  # ===========================================================================
  #  GitHub CLI (work) — PRs, issues, gh api. Auth over SSH to match git remote.
  # ===========================================================================
  programs.gh = {
    enable = true;
    settings.git_protocol = "ssh";
  };

  # All work data (org, roam, repos) lives in /home/jacob-work (@home-work subvol).
}
