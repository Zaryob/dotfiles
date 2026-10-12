;;; init-ui.el --- Appearance -*- lexical-binding: t; -*-

;;; Code:

(setopt modus-themes-bold-constructs t
        modus-themes-italic-constructs t)
(load-theme 'modus-vivendi t)

;; Use the first installed font; fonts are installed by the package manager.
(when (display-graphic-p)
  (when-let* ((font (seq-find (lambda (f) (find-font (font-spec :family f)))
                              '("JetBrains Mono" "Iosevka" "Fira Code"
                                "Menlo" "DejaVu Sans Mono"))))
    (set-face-attribute 'default nil :family font
                        :height (if (eq system-type 'darwin) 140 110))))

(setopt frame-title-format '((:eval (if buffer-file-name
                                        (abbreviate-file-name buffer-file-name)
                                      "%b")))
        display-line-numbers-type t
        column-number-mode t
        size-indication-mode t
        show-paren-context-when-offscreen 'overlay
        which-key-idle-delay 0.5)

(which-key-mode)
(add-hook 'prog-mode-hook #'display-line-numbers-mode)
(add-hook 'prog-mode-hook #'hl-line-mode)
(add-hook 'text-mode-hook #'visual-line-mode)

(provide 'init-ui)
;;; init-ui.el ends here
