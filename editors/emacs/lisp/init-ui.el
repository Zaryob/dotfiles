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
        which-key-idle-delay 0.3)

(which-key-mode)

;; Open files as tabs above the editor, like an IDE.
(require 'tab-line)
(setopt tab-line-close-button-show 'selected
        tab-line-new-button-show nil
        tab-line-tabs-function #'tab-line-tabs-fixed-window-buffers
        tab-line-switch-cycling t)
;; Welcome participates in the same visible tab order as open files.
;; Remove an old exclusion too, so reloading this module repairs existing setups.
(setq tab-line-exclude-modes (delq 'dotfiles-welcome-mode tab-line-exclude-modes))
(dolist (mode '(treemacs-mode compilation-mode))
  (add-to-list 'tab-line-exclude-modes mode))
(global-tab-line-mode 1)
(when (display-graphic-p)
  (pixel-scroll-precision-mode))
;; In a terminal the mouse clicks, scrolls and opens the right-click menu.
;; Hold Option in iTerm2 to select text with the terminal itself instead.
(unless noninteractive
  (xterm-mouse-mode 1))
(add-hook 'prog-mode-hook #'display-line-numbers-mode)
(add-hook 'prog-mode-hook #'hl-line-mode)
(add-hook 'text-mode-hook #'visual-line-mode)

(provide 'init-ui)
;;; init-ui.el ends here
