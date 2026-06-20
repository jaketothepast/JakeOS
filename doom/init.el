;;; init.el -*- lexical-binding: t; -*-
;; Close to stock Doom. The ADHD-specific behavior lives in config.el; this only
;; turns on modules. `org` carries +roam2 (org-roam), +journal, +pomodoro.

(doom! :input

       :completion
       (corfu +orderless)
       (vertico +icons)

       :ui
       doom
       doom-dashboard
       hl-todo
       (ligatures +extra)
       modeline
       ophints
       (popup +defaults)
       vc-gutter
       workspaces
       zen                ; distraction-free writing/coding (SPC t z)

       :editor
       (evil +everywhere)
       file-templates
       fold
       snippets

       :emacs
       (dired +icons)
       electric
       undo
       vc

       :term
       vterm

       :checkers
       syntax

       :tools
       (eval +overlay)
       lookup
       (lsp +peek)
       magit

       :lang
       emacs-lisp
       (org +roam2 +journal +pomodoro +pretty)
       (json)
       (javascript)
       markdown
       nix
       (python +lsp +pyright)
       (sh)

       :config
       (default +bindings +smartparens))
