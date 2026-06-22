;;; config.el -*- lexical-binding: t; -*-
;; Additive ADHD layer over stock Doom. Three jobs:
;;   1. Frictionless capture (offload a thought in ~2 seconds, from anywhere).
;;   2. ONE daily dashboard ("what do I do next?").
;;   3. org-roam dailies + notes as the second brain (separate from tasks).

(setq user-full-name "Jacob")

;; A calmer, low-contrast look lowers cognitive load.
(setq doom-theme 'doom-flatwhite)
(setq display-line-numbers-type 'relative)

;; =============================================================================
;;  Org core — single source of truth
;; =============================================================================
(setq org-directory "~/org/")

(after! org
  ;; Agenda scans the top level of ~/org/ only (roam/ dailies stay out of the
  ;; daily view → the dashboard stays about ACTION, not reference).
  (setq org-agenda-files (list org-directory))

  (setq org-todo-keywords
        '((sequence "TODO(t)" "NEXT(n)" "WAITING(w@/!)" "|" "DONE(d)" "CANCELLED(c@/!)")))

  ;; Logging so future-you can see what happened.
  (setq org-log-done 'time
        org-log-into-drawer t)

  ;; Refile: move an inbox item to a real home. Targets = any heading up to 3
  ;; deep in your agenda files (inbox.org, projects.org). Show the full path when
  ;; choosing, and let you type a NOT-yet-existing heading to create it on the fly.
  (setq org-refile-targets '((org-agenda-files :maxlevel . 3))
        org-refile-use-outline-path 'file
        org-outline-path-complete-in-steps nil
        org-refile-allow-creating-parent-nodes 'confirm)

  ;; ---- Capture: the load-bearing offload ----------------------------------
  ;; Two templates only. The global Mod+N hotkey jumps STRAIGHT to "t" (no menu,
  ;; no categorize-it-now decision); "n" is for a deliberate note via SPC X.
  (setq org-capture-templates
        '(("t" "Task (quick)" entry
           (file+headline "~/org/inbox.org" "Inbox")
           "* TODO %?\n%U\n" :empty-lines 1)
          ("n" "Note / brain-dump" entry
           (file+headline "~/org/inbox.org" "Inbox")
           "* %? :note:\n%U\n" :empty-lines 1)))

  ;; org-clock: make elapsed time visible (time-blindness aid) + resume on restart.
  (setq org-clock-persist 'history
        org-clock-into-drawer t
        org-clock-out-remove-zero-time-clocks t
        org-clock-mode-line-total 'today)
  (org-clock-persistence-insinuate))

;; =============================================================================
;;  Global capture frame (driven from the WM via `emacsclient`)
;; =============================================================================
(defun my/org-capture-frame ()
  "Jump STRAIGHT to the quick-task capture — no menu, no categorize decision.
The WM created a frame named \"doom-capture\" for us."
  (interactive)
  (require 'org-capture)
  (org-capture nil "t"))

(defun my/delete-capture-frame (&rest _)
  "Close the dedicated capture frame once capture is finalized/aborted."
  (when (equal "doom-capture" (frame-parameter nil 'name))
    (delete-frame)))
(advice-add 'org-capture-finalize :after #'my/delete-capture-frame)
(advice-add 'org-capture-kill     :after #'my/delete-capture-frame)

;; Let browsers/apps capture via org-protocol://capture into the same inbox.
(after! org (require 'org-protocol))

;; =============================================================================
;;  The ONE daily dashboard (org-super-agenda)
;; =============================================================================
(use-package! org-super-agenda
  :after org-agenda
  :config
  (setq org-agenda-skip-scheduled-if-done t
        org-agenda-skip-deadline-if-done t
        org-agenda-start-on-weekday nil)
  (org-super-agenda-mode)
  ;; THREE groups, one screen: what's scheduled today, what to do, what to sort.
  (setq org-agenda-custom-commands
        '(("d" "ADHD Daily Dashboard"
           ((agenda "" ((org-agenda-span 'day)
                        (org-super-agenda-groups
                         '((:name "Today" :time-grid t :date today
                                  :deadline today :scheduled today :order 1)
                           (:name "Overdue" :deadline past :scheduled past :order 2)))))
            (alltodo "" ((org-agenda-overriding-header "")
                         (org-super-agenda-groups
                          '((:name "Refile me (inbox)" :file-path "inbox" :order 0)
                            (:name "NEXT — do these" :todo "NEXT" :order 1)
                            (:discard (:anything t)))))))))))

;; =============================================================================
;;  Leader keys — make the daily loop one press each (no guessing)
;; =============================================================================
(map! :leader
      :desc "Daily dashboard"     "o d" (cmd! (org-agenda nil "d"))
      :desc "Open inbox (refile)" "o i" (cmd! (find-file (expand-file-name "inbox.org" org-directory))))

;; =============================================================================
;;  org-roam — dailies + notes (the second brain), separate from tasks
;; =============================================================================
(setq org-roam-directory "~/org/roam/")
(after! org-roam
  (setq org-roam-dailies-directory "daily/")
  (setq org-roam-dailies-capture-templates
        '(("d" "default" entry "* %?"
           :target (file+head "%<%Y-%m-%d>.org" "#+title: %<%Y-%m-%d>\n"))))
  (org-roam-db-autosync-mode))
;; Doom already binds SPC n r (roam) and SPC n j (dailies). Nothing to add.

;; =============================================================================
;;  Pomodoro — time-boxing. Length is YOURS to tune (don't dogmatically use 25).
;; =============================================================================
(after! org-pomodoro
  (setq org-pomodoro-length 25
        org-pomodoro-short-break-length 5
        org-pomodoro-long-break-length 20
        org-pomodoro-audio-player "paplay"
        org-pomodoro-finished-sound-p t))

;; =============================================================================
;;  CodeTutor — read-only "learn while you code" tutor, on the Fireworks backend
;; =============================================================================
;; Fireworks is the REMOTE backend: it sends gathered project context (files,
;; diffs, open buffers) to api.fireworks.ai, so it must be chosen explicitly —
;; `auto' never picks it. The agentic loop uses read-only, project-root-sandboxed
;; tools (curl + rg, both already installed).
;;
;; BACKEND — pick at load time: if a Fireworks key is in the environment use the
;; remote Fireworks backend, otherwise fall back to the local read-only `codex'
;; CLI. (Both `codex' and `pi' are installed; `codex' is the chosen fallback.)
;;
;; CAVEAT: this runs in the Emacs *daemon*, which is started by systemd --user.
;; It only sees FIREWORKS_API_KEY if that var is in the systemd user environment
;; at startup — NOT vars exported in an interactive shell rc. See notes below.
;;
;; API KEY — never set codetutor-fireworks-api-key here, and never put the key in
;; home.sessionVariables: this config is deployed to the WORLD-READABLE /nix/store.
;; Leave it nil; the package then reads $FIREWORKS_API_KEY, then auth-source. Put
;; the key in ~/.authinfo.gpg (encrypted, in your home, NOT Nix-tracked):
;;     machine api.fireworks.ai password fw_...
(use-package! codetutor
  :commands (codetutor-open
             codetutor-what-next
             codetutor-ask
             codetutor-follow-up
             codetutor-refresh-architecture-memory
             codetutor-new-spec
             codetutor-open-spec
             codetutor-scratch
             codetutor-inline-tips)
  :init
  (setq codetutor-backend (if (getenv "FIREWORKS_API_KEY") 'fireworks 'codex)
        codetutor-fireworks-api-key nil    ; nil → $FIREWORKS_API_KEY, then auth-source
        codetutor-open-on-enable nil
        codetutor-start-session-on-open t
        codetutor-review-on-save t)
  :config
  (codetutor-mode 1))
