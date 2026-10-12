;;; early-init.el --- Startup settings applied before the first frame -*- lexical-binding: t; -*-

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
