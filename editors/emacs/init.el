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
;; c) UTF-8 Related Probles;;  If you get error messages like:
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
;;
;; f) Java Language Server Error
;;  If you are living error caused due to jdtls server like that:
;;  ```
;;   LSP :: jdtls has exited (exited abnormally with code 13)
;;   Server jdtls:14460/starting exited with status exit(check corresponding stderr buffer for details). Do you want to restart it? (y or n) n
;;  ```
;;  Just follow this steps:
;;    Ensure you are using java-11
;;    Delete workspace lsp-java-workspace-dir
;;    Delete server installation from lsp-java-server-install-dir
;;    Evaluating lsp-java--ls-command will give you the command that is used for starting JDT LS - you could then start it outside of emacs
;;
;; g) `lsp-java-spring-initializr` helm error
;;  If you get helm error like that:
;;  ```
;;  error in process sentinel: apply: Symbol’s value as variable is void: helm-map error in process sentinel: Symbol’s value as variable is void: helm-map
;;  ```

;;  Just remove `~/.emacs.d/elpa/helm-*`
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

;; add gnutls algoritm
                                        ;(setq gnutls-algorithm-priority "NORMAL:-VERS-TLS0.3")
(setq gnutls-algorithm-priority "NORMAL:-VERS-TLS1.3")

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
;; (setq package-check-signature nil)

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
(setq inhibit-startup-screen t)

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
(setq show-paren-mode t)
(setq size-indication-mode t)

;; enable y/n answers
(fset 'yes-or-no-p 'y-or-n-p)

;; maximize the initial frame automatically
(add-to-list 'initial-frame-alist '(fullscreen . maximized))

;; tab configuration
(setq-default indent-tabs-mode nil)   ;; don't use tabs to indent
(setq-default tab-width 4)            ;; but maintain correct appearance

;; newline at end of file
(setq require-final-newline t)

;; wrap lines at 80 characters
(setq-default fill-column 80)

;; revert buffers automatically when underlying files are changed externally
(global-auto-revert-mode t)

;; Longer whitespace, otherwise syntax highlighting is limited to default column
(setq whitespace-line-column 1000)

;; Enable soft-wrap
(global-visual-line-mode 1)

;; Maintain a list of recent files opened
(recentf-mode 1)
(setq recentf-max-saved-items 50)

;;;- Key Configurations -;;;

(global-set-key (kbd "C-S-d" ) 'kill-whole-line)

;; duplicates line with Ctrl-Shift-D
(defun duplicate-line ()
  (interactive)
  (save-mark-and-excursion
    (beginning-of-line)
    (insert (thing-at-point 'line t))))
(global-set-key (kbd "C-S-k") 'duplicate-line)

;; moves current line one line down
(defun move-line-down ()
  "Move down the current line."
  (interactive)
  (let ((col (current-column)))
    (save-excursion
      (forward-line)
      (transpose-lines 1))
    (forward-line)
    (move-to-column col)))
(global-set-key (kbd "C-S-j") 'move-line-down)

;; moves current line one line up
(defun move-line-up ()
  "Move up the current line."
  (interactive)
  (let ((col (current-column)))
    (save-excursion
      (transpose-lines 1)
      (forward-line -1))
    (forward-line -2)
    (move-to-column col)))
(global-set-key (kbd "C-S-l") 'move-line-up)


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
  :load-path "~/.emacs.d/themes/separators/powerline/")
(powerline-default-theme)

;;;- Packages For lsp-mode -;;;

;; optional if you want which-key integration
(use-package which-key
  :config
  (which-key-mode))

(use-package quickrun
  :ensure t
  :bind ("C-c r" . quickrun))


(use-package lsp-mode
  :ensure t
  :hook (
		 (lsp-mode . lsp-enable-which-key-integration)
         (java-mode . lsp)
		 (dart-mode . lsp)
		 )
  :init (setq
		 lsp-keymap-prefix "C-c l"              ; this is for which-key integration documentation, need to use lsp-mode-map
		 lsp-enable-file-watchers nil
		 read-process-output-max (* 1024 1024)  ; 1 mb
		 lsp-completion-provider :capf
		 lsp-idle-delay 0.500
		 lsp-diagnostic-package :flymake)
  :config
  (setq lsp-intelephense-multi-root nil) ; don't scan unnecessary projects
  (with-eval-after-load 'lsp-intelephense
	(setf
	 (lsp--client-multi-root
	  (gethash 'iph lsp-clients))
	 nil))
  (define-key lsp-mode-map (kbd "C-c l") lsp-command-map)
  :commands (lsp lsp-deferred))

(use-package lsp-dart
  :ensure t
  :hook
  (dart-mode . lsp))

;; For java mode of lsp-mode
(use-package lsp-java
   :ensure t
   :config (add-hook 'java-mode-hook 'lsp))

(if (file-directory-p "/usr/lib64/jvm/")  ; if-part
    (setq zinit-java-dir "/usr/lib64/jvm") ; then-part
  (setq zinit-java-dir "/usr/lib/jvm")) ; else-part


(use-package lsp-java
  :defer t
  :init
  ;; (setenv "JAVA_HOME" java-home)
  ;; (setenv "M2_HOME" m2-home)
  ;; (setenv "PATH" (format "/bin:/usr/bin:/usr/local/bin:%s/bin:%s/bin:%s/bin" (expand-file-name "~")  java-home m2-home))
  (setq
        lsp-java-vmargs  '("-XX:+UseParallelGC" "-XX:GCTimeRatio=4" "-XX:AdaptiveSizePolicyWeight=90" "-Dsun.zip.disableMemoryMapping=true" "-Xmx2G" "-Xms100m")
        ;; lsp-java-java-path "/usr/bin/java"
        ;; lsp-java-configuration-runtimes '[
        ;;                          (if (file-directory-p (format "%s/java-1.8.0/" zinit-java-dir))
        ;;                               (:name "OpenJDK-1.8 (Java8)"
        ;;                                     :path (format "%s/java-1.8.0/" zinit-java-dir)))
        ;;                          (if (file-directory-p (format "%s/java-8-openjdk/" zinit-java-dir))
        ;;                               (:name "JavaSE-11"
        ;;                                     :path (format "%s/java-11-openjdk/"  zinit-java-dir)
        ;;                                     :default
        ;;                                     t))
        ;;                          (if (file-directory-p (format "%s/java-16-openjdk/" zinit-java-dir))
        ;;                               (:name "JavaSE-16"  ; Java latest
        ;;                                     :path (format "%s/java-16-openjdk/" zinit-java-dir)))
        ;; ]
        lsp-java-save-action-organize-imports nil
        lsp-java-maven-download-sources t
        lsp-java-autobuild-enabled nil
        lsp-java-import-gradle-enabled nil
        lsp-inhibit-message nil
        lsp-java-format-on-type-enabled nil
        lsp-java-completion-guess-arguments t
        lsp-java-completion-overwrite nil
        c-basic-offset 2
        tab-width 2)
  :hook ((java-mode . lsp))
  :bind (("C-c j b" . lsp-java-build-project)
         ("C-c j o" . lsp-java-organize-imports)
         ("C-c j g g" . lsp-java-generate-getters-and-setters)
         ("C-c j g s" . lsp-java-generate-to-string)
         ("C-c j g e" . lsp-java-generate-equals-and-hash-code)
         ("C-c j u" . lsp-java-update-project-configuration)))


;; For python
(cond ( (eq system-type 'windows-nt)
        (use-package lsp-python-ms
          :ensure t
          :hook (python-mode . (lambda ()
                                 (require 'lsp-python-ms)
                                 (lsp)))
          :init
          (setq lsp-python-ms-executable (executable-find "python-language-server")))))

;; optionally
;;(use-package lsp-ui :commands lsp-ui-mode)
(use-package lsp-ui
  :ensure t
  :after (lsp-mode)
  :bind (:map lsp-ui-mode-map
              ([remap xref-find-definitions] . lsp-ui-peek-find-definitions)
              ([remap xref-find-references] . lsp-ui-peek-find-references))
  :init (setq lsp-ui-doc-delay 1.5
              lsp-ui-doc-position 'bottom
	          lsp-ui-doc-max-width 100
              ))

;; if you are ivy user
(use-package lsp-ivy :commands lsp-ivy-workspace-symbol)
(use-package lsp-treemacs
  :commands lsp-treemacs-errors-list
  :bind (
	     :map lsp-mode-map
		 ("<M-f8>" . lsp-treemacs-symbols)
		 ("<f8>" . lsp-treemacs-errors-list)
	     )
  )

;; optionally if you want to use debugger
(use-package dap-mode
  :ensure t
  :after (lsp-mode)
  :functions dap-hydra/nil
  :config
  (require 'dap-java)
  (setq dap-auto-configure-features '(sessions locals controls tooltip))
  ;; enables mouse hover support
  (setq dap-tooltip-mode 1)
  ;; use tooltips for mouse hover
  ;; if it is not enabled `dap-mode' will use the minibuffer.
  ;; displays floating panel with debug buttons
  ;; requies emacs 26+
  (setq dap-ui-controls-mode t)
  (setq dap-tooltip-mode t)
  ;; use tooltips for mouse hover
  ;; if it is not enabled `dap-mode' will use the minibuffer.
  (setq tooltip-mode t)
  ;; displays floating panel with debug buttons
  ;; requies emacs 26+
  (setq dap-ui-controls-mode t)
  :bind (:map lsp-mode-map
			  ("<f6>" . dap-debug)
			  ("<M-f6>" . dap-hydra))
  :hook (
		 (dap-mode . dap-ui-mode)
		 (dap-session-created . (lambda (&_rest) (dap-hydra)))
		 (dap-terminated . (lambda (&_rest) (dap-hydra/nil)))
	     )

  )

(use-package dap-java :ensure nil)

;;;- Optional packages for lsp-mode -;;;
(use-package projectile
  :ensure t
  :after (lsp-mode)
  :init (projectile-mode t)
  :config (define-key projectile-mode-map (kbd "C-c p") 'projectile-command-map)) ;; project management


(use-package company
  :ensure t
  :after (lsp-mode)) ;; Auto-complete

;; Flycheck checks for errors at runtime in code
(use-package flycheck
  :ensure t
  :init (global-flycheck-mode)
  :after (lsp-mode))

;; Optional Flutter packages
(use-package hover :ensure t) ;; run app from desktop without emulator

(use-package yasnippet
  :ensure t
  :init (yas-global-mode t)
  :after (lsp-mode))
;;;- File specific modes -;;;

;; c++ mode
(add-to-list 'auto-mode-alist '("\\.h\\'" . c++-mode))
(add-to-list 'auto-mode-alist '("\\.hpp\\'" . c++-mode))

;; html mode
(add-to-list 'auto-mode-alist '("\\.css$" . html-mode))
(add-to-list 'auto-mode-alist '("\\.cfm$" . html-mode))

;; css-mode
(add-to-list 'auto-mode-alist '("\\.css$" . css-mode))
(add-to-list 'auto-mode-alist '("\\.less$" . css-mode))

;; js-mode
(add-to-list 'auto-mode-alist '("\\.js$" . js-mode))
(add-to-list 'auto-mode-alist '("\\.es$" . js-mode))
(add-to-list 'auto-mode-alist '("\\.es6$" . js-mode))
(add-to-list 'auto-mode-alist '("\\.jsx$" . js-mode))

;; java-mode
(add-to-list 'auto-mode-alist '("\\.java$" . java-mode))

;; json mode
(add-hook 'json-mode-hook #'flycheck-mode)

;; yaml mode
(use-package yaml-mode
  :mode ("\\.yml$" . yaml-mode))

;; php mode

(use-package php-mode
  :defer t
  :hook (php-mode . (lambda () (progn
 							     (setq indent-tabs-mode t)
 							     (setq lsp-ui-doc-enable t)))))



;; Mode setting function for company-mode and display-line-numbers-mode
(defun emacs-company-mode ()
  "Turn on a good company like mode."
  (interactive)
  (global-set-key (kbd "<f5>") '(. treemacs))
  (company-mode)
  (display-line-numbers-mode))

(add-hook 'prog-mode-hook 'emacs-company-mode)

;;;- Git Gutter -;;;
(use-package git-gutter
  :ensure t
  :config
  (set-face-background 'git-gutter:modified "purple") ;; background color
  (set-face-foreground 'git-gutter:added "green")
  (set-face-foreground 'git-gutter:deleted "red")
  (global-set-key (kbd "C-x v =") 'git-gutter:popup-hunk)
  (global-set-key (kbd "C-x p") 'git-gutter:previous-hunk) ;; Jump to next/previous hunk
  (global-set-key (kbd "C-x n") 'git-gutter:next-hunk)
  (global-set-key (kbd "C-x v s") 'git-gutter:stage-hunk) ;; Stage current hunk
  (global-set-key (kbd "C-x v r") 'git-gutter:revert-hunk) ;; Revert current hunk
  (global-set-key (kbd "C-x v SPC") #'git-gutter:mark-hunk) ;; Mark current hunk
  :hook (global-git-gutter-mode t))
(global-set-key (kbd "C-x g") 'git-gutter-mode)  ;; If you enable git-gutter-mode for some modes

;;;- Git Timemachine -;;;
(use-package git-timemachine)

;;;- Multiple lines -;;;
(use-package multiple-cursors
  :ensure t
  :config
  (global-set-key (kbd "C-S-c C-S-c") 'mc/edit-lines)
  (global-set-key (kbd "C->") 'mc/mark-next-like-this)
  (global-set-key (kbd "C-M->") 'mc/unmark-next-like-this)
  (global-set-key (kbd "C-<") 'mc/mark-previous-like-this)
  (global-set-key (kbd "C-M-<") 'mc/unmark-previous-like-this)
  (global-set-key (kbd "C-S-<mouse-1>") 'mc/add-cursor-on-click)
  (global-set-key (kbd "C-c C-<") 'mc/mark-all-like-this))

;;;- EMMS -;;;
(add-to-list 'load-path "~/.emacs.d/submodules/emms-player/")
(require 'emms-setup)
(emms-all)
(emms-default-players)
(require 'emms-player-simple)
(require 'emms-source-file)
(require 'emms-source-playlist)
(require 'emms-volume)

(setq emms-volume-change-function 'emms-volume-pulse-change)
(setq emms-playlist-buffer-name "*Music Player*")
(setq emms-browser-covers 'emms-browser-cache-thumbnail-async)
(setq emms-player-list '(emms-player-mpg321
                         emms-player-ogg123
                         emms-player-mplayer))

(emms-player-for '(*track* (type . file)
                           (name . "myfile.pls")))
(setq emms-info-asynchronously nil)

(setq emms-playlist-default-major-mode 'emms-playlist-mode)
(if (file-directory-p "~/Music")  ; if-part
    (setq emms-source-file-default-directory "~/Music/") ; then-part
  (if (file-directory-p "~/Müzik")  ; if-part
      (setq emms-source-file-default-directory "~/Müzik/")
    (setq emms-source-file-default-directory "~/") ; then-part
    )
  ) ; else-part


(global-set-key (kbd "<C-XF86Tools>") 'emms-browser)
(global-set-key (kbd "<C-XF86AudioPlay>") 'emms-pause)
(global-set-key (kbd "<C-XF86AudioNext>") 'emms-next)
(global-set-key (kbd "<C-XF86AudioPrev>") 'emms-previous)

;;;- Key Configurations -;;;

(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(default ((t (:family "Mensch for Powerline" :foundry "PfEd" :slant normal :weight normal :height 98 :width normal)))))

;;; init.el ends here
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(ansi-color-faces-vector
   [default default default italic underline success warning error])
 '(ansi-color-names-vector
   ["#2d3743" "#ff4242" "#74af68" "#dbdb95" "#34cae2" "#008b8b" "#00ede1" "#e1e1e0"])
 '(custom-enabled-themes '(melancholy))
 '(custom-safe-themes
   '("46b1ca9d15e7a6fdb6e3f8c94035f26d2827cc97fd05e32f4f3592d6cff7e894" default))
 '(custom-theme-directory "~/.emacs.d/themes/color-themes/")
 '(delete-selection-mode nil)
 '(electric-pair-mode t)
 '(emms-browser-default-browse-type 'info-artist)
 '(git-gutter:added-sign "++")
 '(git-gutter:deleted-sign "--")
 '(git-gutter:modified-sign "**")
 '(org-agenda-loop-over-headlines-in-active-region nil)
 '(package-selected-packages
   '(git-timemachine yasnippet-snippets yaml-mode which-key use-package projectile popup php-mode lsp-ui lsp-ivy lsp-dart lsp-java hover gnu-elpa-keyring-update git-gutter git-gutter+ flycheck company async)))
