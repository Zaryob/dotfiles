;;; early-init.el --- Startup settings applied before the first frame -*- lexical-binding: t; -*-

;; Older bundled libgccjit versions infer a nonexistent macOS 18 deployment
;; target on Darwin 27.  Choose a valid baseline for native Lisp compilation
;; before package activation can start workers.  Keep explicit user targets.
(when (and (eq system-type 'darwin)
           (version<= "25" operating-system-release)
           (native-comp-available-p))
  (require 'seq)
  (defvar native-comp-driver-options '("-Wl,-w"))
  (unless (or (getenv "MACOSX_DEPLOYMENT_TARGET")
              (seq-some (lambda (option)
                          (string-prefix-p "-mmacosx-version-min=" option))
                        native-comp-driver-options))
    (push "-mmacosx-version-min=11.0" native-comp-driver-options)))

;; Collect garbage rarely during startup; init.el restores a sane value.
(setq gc-cons-threshold most-positive-fixnum
      gc-cons-percentage 0.6)

;; Avoid UI flicker and resizing while the frame is created.
(setq frame-inhibit-implied-resize t
      inhibit-startup-screen t
      inhibit-startup-echo-area-message user-login-name
      initial-scratch-message nil)
(push '(menu-bar-lines . 0) default-frame-alist)
(push '(tool-bar-lines . 0) default-frame-alist)
(push '(vertical-scroll-bars) default-frame-alist)
(push '(fullscreen . maximized) initial-frame-alist)

;; Prefer newer source over stale byte code.
(setq load-prefer-newer t)

;;; early-init.el ends here
