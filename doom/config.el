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

  ;; Refile within the agenda files, up to 2 levels deep.
  (setq org-refile-targets '((org-agenda-files :maxlevel . 2))
        org-refile-use-outline-path 'file
        org-outline-path-complete-in-steps nil)

  ;; ---- Capture: the load-bearing offload ----------------------------------
  ;; Default "t" needs nothing but the text: hotkey → type → C-c C-c → back.
  (setq org-capture-templates
        '(("t" "Task (quick)" entry
           (file+headline "~/org/inbox.org" "Inbox")
           "* TODO %?\n%U\n" :empty-lines 1)
          ("n" "Note / brain-dump" entry
           (file+headline "~/org/inbox.org" "Inbox")
           "* %? :note:\n%U\n" :empty-lines 1)
          ("e" "Event" entry
           (file+headline "~/org/calendar.org" "Events")
           "* %?\n%^T\n" :empty-lines 1)
          ;; Optional energy-tagged task (low-battery days → "Quick wins").
          ("E" "Task (with energy)" entry
           (file+headline "~/org/inbox.org" "Inbox")
           "* TODO [#%^{Priority|A|B|C}] %^{Task}\n:PROPERTIES:\n:ENERGY: %^{Energy|Low|Medium|High}\n:END:\n%U\n"
           :empty-lines 1)))

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
  "Run org-capture; the WM created a frame named \"doom-capture\" for us."
  (interactive)
  (require 'org-capture)
  (org-capture))

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
  (setq org-agenda-custom-commands
        '(("d" "ADHD Daily Dashboard"
           ((agenda "" ((org-agenda-span 'day)
                        (org-super-agenda-groups
                         '((:name "Today" :time-grid t :date today :order 1)
                           (:name "Due today" :deadline today :order 2)
                           (:name "Overdue" :deadline past :order 3)))))
            (alltodo "" ((org-agenda-overriding-header "")
                         (org-super-agenda-groups
                          '((:name "Refile me (inbox)" :file-path "inbox" :order 0)
                            (:name "Quick wins (low energy, high impact)"
                                   :and (:property ("ENERGY" "Low") :priority "A") :order 1)
                            (:name "NEXT — do these" :todo "NEXT" :order 2)
                            (:name "Important" :priority "A" :order 3)
                            (:name "Waiting on others" :todo "WAITING" :order 8)
                            (:discard (:anything t)))))))))))

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
