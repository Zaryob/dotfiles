;;; init-editing.el --- Editing commands and key bindings -*- lexical-binding: t; -*-

;;; Code:

(defun dotfiles-move-line (direction)
  "Move the current line in DIRECTION (-1 or 1), keeping the column.
Do nothing at buffer boundaries.  Preserve the final newline as written."
  (let ((column (current-column))
        (start (line-beginning-position))
        (end (line-end-position)))
    ;; Respect narrowing, including a partial first or last line.
    (when (and (< start (point-max))
               (if (< direction 0)
                   (> start (point-min))
                 (save-excursion
                   (forward-line 1)
                   (not (eobp)))))
      (let* ((other-start (save-excursion
                            (forward-line direction)
                            (line-beginning-position)))
             (other-end (save-excursion
                          (goto-char other-start)
                          (line-end-position))))
        (atomic-change-group
          (if (< direction 0)
              (progn
                (transpose-regions other-start other-end start end)
                (goto-char other-start))
            (transpose-regions start end other-start other-end)
            (goto-char (+ start (- other-end other-start) 1)))
          (move-to-column column))))))

(defun dotfiles-move-line-down ()
  "Move the current line down, keeping the column."
  (interactive)
  (dotfiles-move-line 1))

(defun dotfiles-move-line-up ()
  "Move the current line up, keeping the column."
  (interactive)
  (dotfiles-move-line -1))

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
