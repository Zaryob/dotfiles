;;; init.el --- Zaryob's Emacs configuration
;;
;; Copyright (c) 2021 Suleyman Poyraz
;;
;; Author: Suleyman Poyraz <zaryob.dev@gmail.com>
;; URL: https://github.com/Zaryob/dotfiles
;; Keywords: convenience


;;; License:

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 3
;; of the License, or (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Some notes for future:
;;
;; If you are living some problems follow that paths
;;
;; a) ELPA problem:
;;  If error message is one of the bottom:
;;  ```
;;   Failed to download `elpa` 
;;  ```
;;  or
;;  ```
;;   Failed to verify signature archive-contents.sig:
;;   No public key for 066DAFCB81E42C40 created at 2019-10-02T10:10:02+0100 using RSA
;;   Command output:
;;   gpg: Signature made Wed 02 Oct 2019 10:10:02 AM BST
;;   gpg:                using RSA key C433554766D3DDC64221BFAA066DAFCB81E42C40
;;   gpg: Can't check signature: No public key
;;  ```
;; Follow that:
;;  1.  set package-check-signature to nil, e.g. M-: (setq package-check-signature nil) RET
;;  2.  download the package gnu-elpa-keyring-update and run the function with the same name, e.g. M-x package-install RET gnu-elpa-keyring-update RET.
;;  3.  reset package-check-signature to the default value allow-unsigned
;;
;; b) ‘spinner-1.7.3’ not installed:
;;  If error message is that:
;;  ```
;;  Error (use-package): Failed to install lsp-mode: Package ‘spinner-1.7.3’ is unavailable
;;  ```
;;  This is related with elpa, Follow a)
;;
;; c) UTF-8 Related Probles
;;  If you get error messages like:
;;  ```
;;  Eager macro-expansion failure: (error "Unknown key: :test-id.
;;      Available keys: (:type :time :test-ıd :result :skipped :hidden)") [2 times]
;;  File mode specification error: (error Unknown key: :test-id.
;;      Available keys: (:type :time :test-ıd :result :skipped :hidden))
;;  Error (use-package): dap-mode/:catch: Unknown key: :test-id.
;;      Available keys: (:type :time :test-ıd :result :skipped :hidden)
;;  Emergency (url): Unknown proxy directive: DIRECT [8 times]
;;  Error (use-package): Failed to install dap-dart: Package ‘dap-dart-’ is unavailable
;;  Error (use-package): Cannot load dap-dart
;;  ```
;;
;;  This is related with local settings.
;;    Run this macro in emacs:
;;    ```
;;    M-: (downcase "ID") RET
;;    ```
;;    If it gives string "id" there is no problem but wont give there is problem.
;;  Follow that:
;;     * set your emacs local to "English" and "utf-8":
;;
;;       (set-language-environment "English")
;;       (set-locale-environment "en.UTF-8")
;;       (prefer-coding-system 'utf-8)
;;
;;     * If it continues change your system language
;;       $ localectl set-locale en-US.UTF-8
;;
;; d) Flutter server not working
;;  This project uses `lsp-mode`. If running flutter project is not working with giving this type of error output
;;   ```
;;   internal/modules/cjs/loader.js:638
;;       throw err;
;;       ^
;;
;;   Error: Cannot find module '/home/zaryob/.emacs.d/.extension/vscode/Dart-Code.Dart-Code/3.19.2/extension/out/dist/debug.js'
;;       at Function.Module._resolveFilename (internal/modules/cjs/loader.js:636:15)
;;       at Function.Module._load (internal/modules/cjs/loader.js:562:25)
;;       at Function.Module.runMain (internal/modules/cjs/loader.js:831:12)
;;       at startup (internal/bootstrap/node.js:283:19)
;;       at bootstrapNodeJSCore (internal/bootstrap/node.js:623:3)
;; 
;;   Process Flutter Run stderr finished
;;   ```
;;
;;   Follow this steps:
;;   * remove directory: `.emacs.d/.extension`
;;   * Then open emacs and run command `dap-dart-setup`
;;        `M-x RET dap-dart-setup RET`
;;
;; e) Dart Analyzer Server Error
;;  If you are taking analysis_server based error like that:
;;  ```
;;    Could not find a command named "/home/zaryob/Android/flutter/bin/snapshots/analysis_server.dart.snapshot".
;;  ```
;;  And if you install dart-sdk with flutter this problem caused due to lack of snapshots in correct path. Just make that:
;;  ```
;;    ln -sv cache/dart-sdk/bin/snapshots/ snapshots
;;  ```
;;

;;; Code:

;; use utf-8 coding system for both config and shell
(set-language-environment "English")
(set-locale-environment "en.UTF-8")
(prefer-coding-system 'utf-8)
(set-default-coding-systems 'utf-8)
(set-terminal-coding-system 'utf-8)
(set-keyboard-coding-system 'utf-8)


;; package repositories
(require 'package)

;; Add to load-path this directory containing local add-ons.
(add-to-list 'load-path "~/.emacs.d/lisp/")

;; Add online repositories
(add-to-list 'package-archives
	     '("elpa" . "https://elpa.gnu.org/packages/") t)
(add-to-list 'package-archives
             '("melpa" . "https://melpa.org/packages/") t)
(add-to-list 'package-archives 
	     '("org" . "http://orgmode.org/elpa/") t) ; Org-mode's repository
(add-to-list 'package-archives
             '("melpa-stable" . "https://stable.melpa.org/packages/") t) ; Melpa stable

(add-to-list 'package-archives 
             '("marmalade" . "https://marmalade-repo.org/packages/") t) ; Marmale Repository

;; add gnutls algoritm 
;(setq gnutls-algorithm-priority "NORMAL:-VERS-TLS0.3")

;; keep the installed packages in .emacs.d
(setq package-user-dir (expand-file-name "elpa" user-emacs-directory))
(package-initialize)

;; update the package metadata is the local cache is missing
(unless package-archive-contents
  (package-refresh-contents))


;;;- Install Needed Packages -;;;

(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

; (setq package-check-signature nil)
(unless (package-installed-p 'gnu-elpa-keyring-update)
  (setq package-check-signature nil)
  (package-refresh-contents)
  (package-install 'gnu-elpa-keyring-update))

(require 'use-package)
(setq use-package-always-ensure t)

;;;- Emacs Editor Configuration -;;;

;;;- User Configuration -;;;

(setq user-full-name "Suleyman Poyraz"
      user-mail-address "zaryob.dev@gmail.com")


;;;- Emacs System Preferences -;;;

;; reduce garbage collection  frequency
;; default: 0.76MB
;; set: 50MB
(setq gc-cons-threshold 50000000)

;; warn when opening files bigger than 100MB
(setq large-file-warning-threshold 100000000)


;;;- Editor Preferences -;;;

;; disable the annoying bell ring
(setq ring-bell-function 'ignore)

;; disable startup screen
; (setq inhibit-startup-screen t)

;; nice scrolling
(setq scroll-margin 0
      scroll-conservatively 100000
      scroll-preserve-screen-position 1)

;; set frame title
(setq frame-title-format
      '((:eval (if (buffer-file-name)
                   (abbreviate-file-name (buffer-file-name))
                 "%b"))))

;; mode line settings
(setq line-number-mode t)
(setq column-number-mode t)
(setq size-indication-mode t)

;; enable y/n answers
(fset 'yes-or-no-p 'y-or-n-p)

;; maximize the initial frame automatically
(add-to-list 'initial-frame-alist '(fullscreen . maximized))

;; tab configuration
(setq-default indent-tabs-mode nil)   ;; don't use tabs to indent
(setq-default tab-width 8)            ;; but maintain correct appearance

;; newline at end of file
(setq require-final-newline t)

;; wrap lines at 80 characters
(setq-default fill-column 80)

;; revert buffers automatically when underlying files are changed externally
(global-auto-revert-mode t)

;;;- Theme Configurations -;;;

;;;- Toolbar colors -;;;
(set-face-attribute 'tty-menu-disabled-face nil
 :background "black" :foreground "lightgray")
(set-face-attribute 'tty-menu-enabled-face  nil
 :background "black" :foreground "white")
(set-face-attribute 'tty-menu-selected-face nil
 :background "black" :foreground "brightgreen")

;;;- Powerline -;;;

(use-package powerline
  :ensure nil
  :load-path "~/.emacs.d/themes/powerline/")
(powerline-default-theme)

;;;- NeoTree -;;;
;(add-to-list 'load-path "~/.emacs.d/additional/emacs-neotree/")
;  (require 'neotree)
;  (global-set-key [f8] 'neotree-toggle)

;;;- Packages For lsp-mode -;;;
(use-package lsp-mode
  :init
  ;; set prefix for lsp-command-keymap (few alternatives - "C-l", "C-c l")
  (setq lsp-diagnostic-package :flymake)
  :hook (;; replace XXX-mode with concrete major-mode(e. g. python-mode)
         (dart-mode . lsp)
         ;; if you want which-key integration
         (lsp-mode . lsp-enable-which-key-integration))
  :commands lsp)

(use-package lsp-dart
  :ensure t
  :hook
  (dart-mode . lsp))

;; For java mode of lsp-mode
(use-package lsp-java :config (add-hook 'java-mode-hook 'lsp))

;; For python 
;;(use-package lsp-python-ms
;;  :ensure t
;;  :hook (python-mode . (lambda ()
;;                         (require 'lsp-python-ms)
;;                         (lsp)))
;;  :init
;;  (setq lsp-python-ms-executable (executable-find "python-language-server")))

;; optionally
(use-package lsp-ui :commands lsp-ui-mode)
;; if you are helm user
(use-package helm-lsp :commands helm-lsp-workspace-symbol)
;; if you are ivy user
(use-package lsp-ivy :commands lsp-ivy-workspace-symbol)
(use-package lsp-treemacs 
	     :commands lsp-treemacs-errors-list
	     :bind (("<f8>"  . treemacs)))

;; optionally if you want to use debugger
(use-package dap-mode :after lsp-mode)
(use-package dap-java :ensure nil)

;; (setq lsp-java-java-path "/usr/lib/jvm/java")

;(use-package dap-dart) ; to load the dap adapter for your language
;; Enabling only some features
(setq dap-auto-configure-features '(sessions locals controls tooltip))

(dap-mode 1)

;; The modes below are optional
(dap-ui-mode 1)
;; enables mouse hover support
(dap-tooltip-mode 1)
;; use tooltips for mouse hover
;; if it is not enabled `dap-mode' will use the minibuffer.
(tooltip-mode 1)
;; displays floating panel with debug buttons
;; requies emacs 26+
(dap-ui-controls-mode 1)

;; optional if you want which-key integration
(use-package which-key
    :config
    (which-key-mode))

;; Optional packages
(use-package projectile :ensure t) ;; project management
(use-package yasnippet
  :ensure t
  :config (yas-global-mode)) ;; snipets
(use-package company :ensure t) ;; Auto-complete

;; Optional Flutter packages
(use-package hover :ensure t) ;; run app from desktop without emulator



;;;- Key Configurations -;;;
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(ansi-color-faces-vector
   [default default default italic underline success warning error])
 '(column-number-mode t)
 '(custom-enabled-themes '(melancholy))
 '(custom-safe-themes
   '("46b1ca9d15e7a6fdb6e3f8c94035f26d2827cc97fd05e32f4f3592d6cff7e894" default))
 '(custom-theme-directory "~/.emacs.d/themes/color-themes/")
 '(org-agenda-loop-over-headlines-in-active-region nil)
 '(package-selected-packages '(lsp-dart lsp-mode use-package))
 '(show-paren-mode t)
 '(size-indication-mode t))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(default ((t (:family "Mensch for Powerline" :foundry "PfEd" :slant normal :weight normal :height 98 :width normal)))))
