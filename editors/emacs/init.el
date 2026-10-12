;;; init.el --- Zaryob's Emacs configuration -*- lexical-binding: t; -*-

;; Author: Suleyman Poyraz <zaryob.dev@gmail.com>
;; URL: https://github.com/Zaryob/dotfiles
;; Requires Emacs 31 (built-in use-package, eglot, tree-sitter modes).

;;; Commentary:

;; Modules live in lisp/ and are loaded in order below.  Packages,
;; grammars and caches are written inside `user-emacs-directory' and
;; ignored by git.

;;; Code:

(add-hook 'emacs-startup-hook
          (lambda ()
            (setq gc-cons-threshold (* 32 1024 1024)
                  gc-cons-percentage 0.1)))

(require 'package)
(setopt package-archives
        '(("gnu"    . "https://elpa.gnu.org/packages/")
          ("nongnu" . "https://elpa.nongnu.org/nongnu/")
          ("melpa"  . "https://melpa.org/packages/"))
        package-archive-priorities '(("gnu" . 3) ("nongnu" . 2) ("melpa" . 1))
        use-package-always-ensure t)
;; Emacs 30 only applies `use-package-always-ensure' once this is loaded.
(require 'use-package-ensure)

(setq custom-file (locate-user-emacs-file "custom.el"))
(load custom-file :noerror :nomessage)

(add-to-list 'load-path (expand-file-name "lisp" user-emacs-directory))
(require 'init-core)
(require 'init-ui)
(require 'init-completion)
(require 'init-editing)
(require 'init-prog)
(require 'init-vc)

;; Machine-specific additions, not tracked.
(load (locate-user-emacs-file "local.el") :noerror :nomessage)

;;; init.el ends here
