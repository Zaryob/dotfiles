;;; init-core.el --- Built-in defaults -*- lexical-binding: t; -*-

;;; Code:

(setq user-full-name "Suleyman Poyraz"
      user-mail-address "zaryob.dev@gmail.com")

(set-language-environment "UTF-8")
(prefer-coding-system 'utf-8)

;; Keep backups, auto-saves and other state out of edited directories.
(let ((var (locate-user-emacs-file "var/")))
  (make-directory (expand-file-name "auto-save/" var) t)
  (setq backup-directory-alist `(("." . ,(expand-file-name "backup/" var)))
        auto-save-file-name-transforms `((".*" ,(expand-file-name "auto-save/" var) t))
        auto-save-list-file-prefix (expand-file-name "auto-save/sessions-" var)
        backup-by-copying t
        delete-old-versions t
        version-control t
        create-lockfiles nil))

(setopt use-short-answers t
        ring-bell-function #'ignore
        large-file-warning-threshold (* 100 1024 1024)
        require-final-newline t
        sentence-end-double-space nil
        indent-tabs-mode nil
        tab-width 4
        fill-column 80
        scroll-margin 0
        scroll-conservatively 101
        scroll-preserve-screen-position t
        global-auto-revert-non-file-buffers t
        recentf-max-saved-items 200
        history-length 1000
        savehist-additional-variables '(search-ring regexp-search-ring)
        delete-by-moving-to-trash t
        dired-listing-switches "-alh")

(global-auto-revert-mode)
(recentf-mode)
(savehist-mode)
(save-place-mode)
(delete-selection-mode)
(electric-pair-mode)

;; macOS: Command is Meta, Option stays available for typing characters.
(when (eq system-type 'darwin)
  (setq mac-command-modifier 'meta
        mac-option-modifier 'none
        mac-right-option-modifier 'none)
  ;; GUI Emacs started from the Dock does not see the shell's PATH.
  (when (and (display-graphic-p) (not (getenv "DOTFILES")))
    (let ((path (shell-command-to-string
                 "$SHELL -lc 'printf %s \"$PATH\"' 2>/dev/null")))
      (unless (string-empty-p path)
        (setenv "PATH" path)
        (setq exec-path (append (parse-colon-path path) (list exec-directory)))))))

;; Lets emacsclient (the $EDITOR set by the shell) reuse this session.
(require 'server)
(unless (or noninteractive (server-running-p))
  (server-start))

(provide 'init-core)
;;; init-core.el ends here
