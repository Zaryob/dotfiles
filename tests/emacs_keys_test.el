;;; emacs_keys_test.el --- Prefix cancellation regressions -*- lexical-binding: t; -*-

(require 'ert)
(require 'init-keys)

(ert-deftest dotfiles-prefixes-accept-control-g ()
  "C-g cancels incomplete project, window and leader commands."
  (dolist (prefix (append '("C-x" "C-x p" "C-x w" "M-m")
                          (mapcar (lambda (group) (concat "M-m " (car group)))
                                  dotfiles-leader-groups)
                          '("M-m w")))
    (let* ((key (kbd (concat prefix " C-g")))
           (command (key-binding key)))
      (should (commandp command))
      (should (eq (condition-case nil
                      (progn (call-interactively command) 'returned)
                    (quit 'cancelled))
                  'cancelled)))))

(ert-deftest dotfiles-prefix-cancellation-preserves-project-commands ()
  "Adding cancellation leaves ordinary project and file commands available."
  (should (eq (key-binding (kbd "C-x p f")) #'project-find-file))
  (should (eq (key-binding (kbd "C-x C-f")) #'find-file))
  (should (eq (key-binding (kbd "M-m p p")) #'projectile-switch-project)))

;;; emacs_keys_test.el ends here
