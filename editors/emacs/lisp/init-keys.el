;;; init-keys.el --- Every key this configuration adds, in one place -*- lexical-binding: t; -*-

;;; Commentary:

;; One rule: Emacs's own keys stay as they are, and everything added here
;; lives under the leader, M-m.  Meta is the left Option key in iTerm2, Alt on
;; Linux and Cmd in the macOS app; Esc then m works everywhere.  After M-m, or
;; after a group key, Which Key lists what comes next.
;;
;; Every key here reaches Emacs through a terminal: no Ctrl+Shift chords and
;; no Shift or Ctrl with function keys.  The only keys outside the leader are
;; the function-key row and the three editing keys at the end of this file,
;; plus Consult's M-g / M-s replacements in init-completion.el.

;;; Code:

(require 'tab-line)
(require 'project)

(defvar dotfiles-leader-map (make-sparse-keymap "Leader")
  "Keymap behind the leader key, M-m.")

(defconst dotfiles-leader-groups
  '(("p" "project"
     ("p" . projectile-switch-project)
     ("a" . projectile-add-and-switch-project)
     ("f" . projectile-find-file)
     ("b" . projectile-switch-to-buffer)
     ("r" . projectile-recentf)
     ("s" . dotfiles-project-search)
     ("t" . dotfiles-project-tree)
     ("d" . projectile-dired)
     ("D" . projectile-discover-projects-in-search-path)
     ("x" . projectile-remove-known-project)
     ("k" . projectile-kill-buffers))
    ("g" "git"
     ("s" . magit-status)
     ("g" . dotfiles-git-graph)
     ("b" . magit-show-refs-head)
     ("f" . magit-log-buffer-file)
     ("d" . magit-diff-unstaged)
     ("B" . magit-blame-addition))
    ("c" "build"
     ("c" . dotfiles-configure)
     ("b" . dotfiles-build)
     ("B" . dotfiles-build-choose)
     ("t" . dotfiles-test)
     ("r" . dotfiles-run)
     ("q" . quickrun)
     ("x" . dotfiles-clean)
     ("k" . dotfiles-stop)
     ("s" . dotfiles-cmake-settings)
     ("e" . dotfiles-doctor)
     ("C" . compile)
     ("l" . recompile))
    ("d" "debug"
     ("d" . dotfiles-debug-or-continue)
     ("D" . dape)
     ("b" . dape-breakpoint-toggle)
     ("c" . dape-continue)
     ("n" . dape-next)
     ("i" . dape-step-in)
     ("o" . dape-step-out)
     ("r" . dape-restart)
     ("q" . dape-quit)
     ("w" . dape-watch-dwim)
     ("v" . dape-info))
    ("e" "edit"
     ("p" . dotfiles-move-line-up)
     ("n" . dotfiles-move-line-down)
     ("d" . duplicate-dwim)
     ("k" . kill-whole-line)
     ("m" . mc/mark-next-like-this)
     ("u" . mc/unmark-next-like-this)
     ("a" . mc/mark-all-like-this)
     ("l" . mc/edit-lines)
     ("r" . undo-redo))
    ("l" "code"
     ("r" . eglot-rename)
     ("a" . eglot-code-actions)
     ("f" . eglot-format)
     ("o" . eglot-code-action-organize-imports)
     ("d" . eldoc-doc-buffer)
     ("i" . eglot-inlay-hints-mode)
     ("h" . dotfiles-cpp-switch-source-header))
    ("f" "files"
     ("f" . find-file)
     ("s" . save-buffer)
     ("r" . consult-recent-file))
    ("b" "buffers"
     ("b" . consult-buffer)
     ("d" . kill-current-buffer)
     ("n" . tab-line-switch-to-next-tab)
     ("p" . tab-line-switch-to-prev-tab)))
  "Leader groups as (KEY NAME (KEY . COMMAND)...).")

(pcase-dolist (`(,key ,name . ,bindings) dotfiles-leader-groups)
  (let ((map (make-sparse-keymap name)))
    (keymap-set map "C-g" #'keyboard-quit)
    (pcase-dolist (`(,binding . ,command) bindings)
      (keymap-set map binding command))
    (keymap-set dotfiles-leader-map key (cons name map))))

(keymap-set dotfiles-leader-map "w" (cons "windows" window-prefix-map))
;; C-g must be a complete command even after a prefix such as C-x p.
(dolist (map (list dotfiles-leader-map ctl-x-map project-prefix-map window-prefix-map))
  (keymap-set map "C-g" #'keyboard-quit))
;; Hold Meta and tap m twice: the palette finds any command by name.
(keymap-set dotfiles-leader-map "M-m" #'dotfiles-command-palette)
(keymap-set dotfiles-leader-map "?" #'dotfiles-cheatsheet)
(keymap-global-set "M-m" dotfiles-leader-map)
;; Match the visible tab order instead of cycling through hidden buffer history.
(keymap-global-set "C-x <right>" #'tab-line-switch-to-next-tab)
(keymap-global-set "C-x <left>" #'tab-line-switch-to-prev-tab)

;; After M-m e p, plain p / n / d / m keep moving, duplicating and marking.
(defvar-keymap dotfiles-edit-repeat-map
  :repeat t
  "p" #'dotfiles-move-line-up
  "n" #'dotfiles-move-line-down
  "d" #'duplicate-dwim
  "m" #'mc/mark-next-like-this
  "u" #'mc/unmark-next-like-this)
(repeat-mode 1)

;; The function-key row: run and debug without the leader.
(pcase-dolist (`(,key . ,command)
               '(("<f5>"  . dotfiles-debug-or-continue)
                 ("<f6>"  . dotfiles-run)
                 ("<f7>"  . dotfiles-build)
                 ("<f8>"  . dotfiles-test)
                 ("<f9>"  . dape-breakpoint-toggle)
                 ("<f10>" . dape-next)
                 ("<f11>" . dape-step-in)
                 ("<f12>" . dape-step-out)
                 ("M-<up>"   . dotfiles-move-line-up)
                 ("M-<down>" . dotfiles-move-line-down)
                 ("M-z"      . undo-redo)))
  (keymap-global-set key command))

;; Copy, cut, paste and undo on C-c, C-x, C-v and C-z while text is selected;
;; without a selection C-c and C-x stay Emacs prefixes.  Put (cua-mode -1) in
;; local.el for the classic keys.
(cua-mode 1)
(setopt cua-keep-region-after-copy t)

(provide 'init-keys)
;;; init-keys.el ends here
