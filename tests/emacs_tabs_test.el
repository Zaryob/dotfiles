;;; emacs_tabs_test.el --- Welcome and visible-tab navigation -*- lexical-binding: t; -*-

(require 'ert)
(require 'init-ui)
(require 'init-help)
(require 'init-keys)

(ert-deftest dotfiles-welcome-shows-tab-line ()
  "The welcome screen keeps the same tab bar as an editing buffer."
  (with-current-buffer (dotfiles-welcome-buffer)
    (run-hooks 'post-command-hook)
    (should tab-line-mode)
    (should-not (memq major-mode tab-line-exclude-modes))))

(ert-deftest dotfiles-visible-tabs-cycle-through-welcome ()
  "Both shortcuts follow the visible order and wrap past Welcome both ways."
  (let ((first (generate-new-buffer "first.txt"))
        (second (generate-new-buffer "second.txt"))
        (welcome (dotfiles-welcome-buffer)))
    (unwind-protect
        (save-window-excursion
          (delete-other-windows)
          (set-window-buffer nil welcome)
          (set-window-prev-buffers nil nil)
          (set-window-next-buffers nil nil)
          (set-window-parameter nil 'tab-line-buffers nil)
          (dolist (buffer (list welcome first second))
            (switch-to-buffer buffer)
            (funcall tab-line-tabs-function))
          (should (equal (funcall tab-line-tabs-function)
                         (list welcome first second)))
          (dolist (key '("M-m b n" "C-x <right>"))
            (switch-to-buffer second)
            (dolist (expected (list welcome first second welcome))
              (with-current-buffer (window-buffer)
                (call-interactively (key-binding (kbd key))))
              (should (eq (window-buffer) expected))))
          (dolist (key '("M-m b p" "C-x <left>"))
            (switch-to-buffer first)
            (dolist (expected (list welcome second first welcome))
              (with-current-buffer (window-buffer)
                (call-interactively (key-binding (kbd key))))
              (should (eq (window-buffer) expected))))
          ;; A sole Welcome tab is a valid cycle too.
          (set-window-buffer nil welcome)
          (set-window-prev-buffers nil nil)
          (set-window-next-buffers nil nil)
          (set-window-parameter nil 'tab-line-buffers nil)
          (with-current-buffer (window-buffer)
            (call-interactively (key-binding (kbd "M-m b n"))))
          (should (eq (window-buffer) welcome)))
      (kill-buffer first)
      (kill-buffer second))))

;;; emacs_tabs_test.el ends here
