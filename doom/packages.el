;; -*- no-byte-compile: t; -*-
;;; packages.el

;; The ONLY non-stock package: a single grouped daily dashboard. Everything else
;; (org-roam, org-journal, org-pomodoro) ships with Doom's :lang org flags.
(package! org-super-agenda)

;; codetutor — my own package, consumed at a pinned commit (reproducible).
;; To bump: change :pin to a new SHA, rebuild, then `doom sync` (runs on the next
;; boot into work mode, or `systemctl --user start doom-sync` now).
(package! codetutor
  :recipe (:host github :repo "jaketothepast/codetutor")
  :pin "9d21ab4c6e0d19be22bd19eeb267a58448cec63b")
