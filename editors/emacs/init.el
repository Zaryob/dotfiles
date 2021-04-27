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

;;; Code:

;; package repositories
(require 'package)

(add-to-list 'package-archives
             '("melpa" . "https://melpa.org/packages/") t)
(add-to-list 'package-archives 
	     '("org" . "http://orgmode.org/elpa/") t) ; Org-mode's repository
(add-to-list 'package-archives
         '("melpa-stable" . "https://stable.melpa.org/packages/") t) ; Melpa stable

; (add-to-list 'package-archives 
;             '("marmalade" . "https://marmalade-repo.org/packages/") t) ; Marmale Repository


;; keep the installed packages in .emacs.d
(setq package-user-dir (expand-file-name "elpa" user-emacs-directory))
(package-initialize)

;; update the package metadata is the local cache is missing
(unless package-archive-contents
  (package-refresh-contents))

;;;;--- Install Needed Packages ---;;;;

(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

(require 'use-package)
(setq use-package-always-ensure t)

;;;;--- Emacs Editor Configuration ---;;;;

;;;-- User Configuration --;;;

(setq user-full-name "Suleyman Poyraz"
      user-mail-address "zaryob.dev@gmail.com")


;;;++ Emacs System Preferences ++;;;

;; reduce garbage collection  frequency
;; default: 0.76MB
;; set: 50MB
(setq gc-cons-threshold 50000000)

;; warn when opening files bigger than 100MB
(setq large-file-warning-threshold 100000000)

;;;++ Emacs System Preferences ++;;;

;;;++ Editor Preferences ++;;;

;; disable the annoying bell ring
; (setq ring-bell-function 'ignore)

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

;; use utf-8 coding system for both config and shell
(prefer-coding-system 'utf-8)
(set-default-coding-systems 'utf-8)
(set-terminal-coding-system 'utf-8)
(set-keyboard-coding-system 'utf-8)

;;;-- End of Editor Preferences --;;;

;;;- Key Configurations -;;;
