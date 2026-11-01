;;; emacs_test.el --- Editing and language setup regressions -*- lexical-binding: t; -*-

(require 'ert)
(require 'cl-lib)
(require 'use-package)

(setq use-package-always-ensure nil
      load-prefer-newer t
      gc-cons-threshold (* 32 1024 1024)
      treesit-auto-install-grammar nil)

(require 'init-editing)
(require 'init-prog)
(require 'eglot)

(ert-deftest dotfiles-native-compilation-works ()
  "Compile and execute native code using the actual runtime toolchain."
  (unless (native-comp-available-p)
    (ert-skip "This Emacs has no native compiler"))
  (let ((compiled (native-compile '(lambda (value) (+ value 1)))))
    (should (native-comp-function-p compiled))
    (should (= (funcall compiled 41) 42))))

(ert-deftest dotfiles-move-line-keeps-text-and-point ()
  "Move both ways without changing the final newline or the current column."
  (dolist (newline '("" "\n"))
    (dolist (case '((dotfiles-move-line-up 1 "second\nfirst\nthird" 0)
                    (dotfiles-move-line-up 2 "first\nthird\nsecond" 1)
                    (dotfiles-move-line-down 0 "second\nfirst\nthird" 1)
                    (dotfiles-move-line-down 1 "first\nthird\nsecond" 2)))
      (pcase-let ((`(,command ,line ,expected ,destination) case))
        (with-temp-buffer
          (insert "first\nsecond\nthird" newline)
          (goto-char (point-min))
          (forward-line line)
          (move-to-column 3)
          (funcall command)
          (should (equal (buffer-string) (concat expected newline)))
          (should (= (line-number-at-pos) (1+ destination)))
          (should (= (current-column) 3)))))))

(ert-deftest dotfiles-move-line-stops-at-boundaries ()
  "Moving beyond either end leaves the contents and point unchanged."
  (dolist (text '("" "only" "only\n" "first\nlast" "first\nlast\n"))
    (dolist (command '(dotfiles-move-line-up dotfiles-move-line-down))
      (with-temp-buffer
        (insert text)
        (goto-char (if (eq command 'dotfiles-move-line-up)
                       (point-min) (point-max)))
        ;; Check the final real line as well as a possible trailing empty line.
        (when (and (eq command 'dotfiles-move-line-down)
                   (bolp) (not (bobp)))
          (backward-char))
        (let ((before (point)))
          (funcall command)
          (should (equal (buffer-string) text))
          (should (= (point) before)))))))

(ert-deftest dotfiles-move-line-handles-empty-lines-and-tabs ()
  (with-temp-buffer
    (insert "\n\tcurrent\nlast")
    (goto-char (point-min))
    (forward-line 1)
    (forward-char 3)
    (let ((column (current-column)))
      (dotfiles-move-line-up)
      (should (equal (buffer-string) "\tcurrent\n\nlast"))
      (should (= (current-column) column))
      (dotfiles-move-line-down)
      (should (equal (buffer-string) "\n\tcurrent\nlast"))
      (should (= (current-column) column)))))

(ert-deftest dotfiles-move-line-respects-narrowing ()
  (with-temp-buffer
    (insert "outside\nfirst\nsecond\noutside")
    (narrow-to-region 9 22)
    (goto-char (point-min))
    (dotfiles-move-line-up)
    (should (equal (buffer-string) "first\nsecond\n"))
    (dotfiles-move-line-down)
    (should (equal (buffer-string) "second\nfirst\n"))
    (dotfiles-move-line-down)
    (should (equal (buffer-string) "second\nfirst\n"))
    (widen)
    (should (equal (buffer-string) "outside\nsecond\nfirst\noutside"))))

(ert-deftest dotfiles-move-line-can-be-undone ()
  (with-temp-buffer
    (buffer-enable-undo)
    (insert "first\nsecond")
    (setq buffer-undo-list nil)
    (goto-char (point-min))
    (dotfiles-move-line-down)
    (undo-boundary)
    (undo 1)
    (should (equal (buffer-string) "first\nsecond"))))

(ert-deftest dotfiles-python-server-priority-and-arguments ()
  "Prefer basedpyright, then pyright, then pylsp, using each server's args."
  (dolist (case '((("pylsp" "pyright-langserver" "basedpyright-langserver")
                   "/tools/basedpyright-langserver" "--stdio")
                  (("pylsp" "pyright-langserver")
                   "/tools/pyright-langserver" "--stdio")
                  (("pylsp") "/tools/pylsp")))
    (cl-letf (((symbol-function 'executable-find)
               (lambda (name)
                 (when (member name (car case)) (concat "/tools/" name)))))
      (should (equal (dotfiles-python-eglot-contact) (cdr case)))))
  (should (eq (cdr (assoc '(python-mode python-ts-mode) eglot-server-programs))
              #'dotfiles-python-eglot-contact)))

(ert-deftest dotfiles-python-server-missing-is-actionable ()
  (cl-letf (((symbol-function 'executable-find) (lambda (_) nil)))
    (should-error (dotfiles-python-eglot-contact) :type 'user-error)
    (with-temp-buffer
      (setq major-mode 'python-mode)
      (cl-letf (((symbol-function 'eglot-ensure)
                 (lambda () (ert-fail "Must not start an unavailable server"))))
        (dotfiles-eglot-maybe)))))

(ert-deftest dotfiles-prog-works-without-tree-sitter ()
  "A build without tree-sitter retains the classic C/C++ and Python modes."
  (let ((auto-mode-alist nil)
        (major-mode-remap-alist nil)
        (treesit-language-source-alist nil)
        (dotfiles-treesit-auto nil))
    (cl-letf (((symbol-function 'treesit-available-p) (lambda () nil))
              ((symbol-function 'treesit-language-available-p)
               (lambda (&rest _) (ert-fail "Tree-sitter is not available"))))
      (load "init-prog" nil t)
      (should-not dotfiles-treesit-auto)
      (should-not auto-mode-alist)
      (should-not major-mode-remap-alist)
      (should-error (dotfiles-install-grammars) :type 'user-error))))

;;; emacs_test.el ends here
