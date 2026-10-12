;;; init-editing.el --- Editing commands and key bindings -*- lexical-binding: t; -*-

;;; Code:

(defun dotfiles-move-line-down ()
  "Move the current line down, keeping the column."
  (interactive)
  (let ((col (current-column)))
    (save-excursion
      (forward-line)
      (transpose-lines 1))
    (forward-line)
    (move-to-column col)))

(defun dotfiles-move-line-up ()
  "Move the current line up, keeping the column."
  (interactive)
  (let ((col (current-column)))
    (save-excursion
      (transpose-lines 1)
      (forward-line -1))
    (forward-line -2)
    (move-to-column col)))

(keymap-global-set "C-S-d" #'kill-whole-line)
(keymap-global-set "C-S-k" #'duplicate-dwim)
(keymap-global-set "C-S-j" #'dotfiles-move-line-down)
(keymap-global-set "C-S-l" #'dotfiles-move-line-up)

(use-package multiple-cursors
  :bind (("C-S-c C-S-c"   . mc/edit-lines)
         ("C->"           . mc/mark-next-like-this)
         ("C-<"           . mc/mark-previous-like-this)
         ("C-M->"         . mc/unmark-next-like-this)
         ("C-M-<"         . mc/unmark-previous-like-this)
         ("C-c C-<"       . mc/mark-all-like-this)
         ("C-S-<mouse-1>" . mc/add-cursor-on-click)))

(provide 'init-editing)
;;; init-editing.el ends here
