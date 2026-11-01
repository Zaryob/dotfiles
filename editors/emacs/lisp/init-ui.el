;;; init-ui.el --- Appearance -*- lexical-binding: t; -*-

;;; Code:

(setopt modus-themes-bold-constructs t
        modus-themes-italic-constructs t)
(load-theme 'modus-vivendi t)

(require 'seq)

(defun dotfiles-configure-frame (frame)
  "Apply the preferred font to graphical FRAME, including emacsclient frames."
  (when (display-graphic-p frame)
    (with-selected-frame frame
      (when-let* ((font (seq-find
                         (lambda (family) (find-font (font-spec :family family) frame))
                         '("JetBrains Mono" "Iosevka" "Fira Code"
                           "Menlo" "DejaVu Sans Mono"))))
        (set-face-attribute 'default frame :family font
                            :height (if (eq system-type 'darwin) 140 110))))))

;; Daemons have no graphical frame while init.el runs.
(add-hook 'after-make-frame-functions #'dotfiles-configure-frame)
(dolist (frame (frame-list))
  (dotfiles-configure-frame frame))

(setopt frame-title-format '((:eval (if buffer-file-name
                                        (abbreviate-file-name buffer-file-name)
                                      "%b")))
        display-line-numbers-type t
        column-number-mode t
        size-indication-mode t
        show-paren-context-when-offscreen 'overlay
        which-key-idle-delay 0.5)

(which-key-mode)

;; Open files as tabs above the editor, like an IDE.
(setopt tab-line-close-button-show 'selected
        tab-line-new-button-show nil)
(global-tab-line-mode)
(with-eval-after-load 'tab-line
  (dolist (mode '(treemacs-mode dotfiles-welcome-mode compilation-mode))
    (add-to-list 'tab-line-exclude-modes mode)))
(when (display-graphic-p)
  (pixel-scroll-precision-mode))
(add-hook 'prog-mode-hook #'display-line-numbers-mode)
(add-hook 'prog-mode-hook #'hl-line-mode)
(add-hook 'text-mode-hook #'visual-line-mode)

(provide 'init-ui)
;;; init-ui.el ends here
