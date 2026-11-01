;;; init-vc.el --- Git -*- lexical-binding: t; -*-

;;; Code:

(use-package magit
  :bind ("C-x g" . magit-status))

(defun dotfiles-git-graph ()
  "Show a colored commit graph for all local and remote refs.
RET inspects a commit, TAB expands a section and q returns to editing."
  (interactive)
  (require 'magit)
  (magit-log-all '("--graph" "--decorate" "--color" "-n256")))

;; Change markers in the fringe; hunk commands are on C-x v [ ] and C-x v *.
(use-package diff-hl
  :hook ((magit-pre-refresh . diff-hl-magit-pre-refresh)
         (magit-post-refresh . diff-hl-magit-post-refresh)
         (dired-mode . diff-hl-dired-mode))
  :init (global-diff-hl-mode)
  :config
  (unless (display-graphic-p) (diff-hl-margin-mode)))

(setopt vc-follow-symlinks t
        ediff-window-setup-function #'ediff-setup-windows-plain
        ediff-split-window-function #'split-window-horizontally)

(provide 'init-vc)
;;; init-vc.el ends here
