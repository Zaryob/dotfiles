;;; emacs_build_test.el --- Build systems, debugging and the command palette -*- lexical-binding: t; -*-

;;; Commentary:

;; Run with tests/emacs_build_test.sh.  Make and Python projects are real
;; temporary directories, built and run by the actual tools.

;;; Code:

(require 'ert)
(require 'cl-lib)
(require 'seq)
(require 'package)

(setq user-emacs-directory (or (getenv "DOTFILES_BUILD_TEST_DIRECTORY")
                               (error "Run this test through tests/emacs_build_test.sh"))
      package-user-dir (getenv "DOTFILES_BUILD_TEST_PACKAGES")
      use-package-always-ensure nil
      load-prefer-newer t
      project-list-file (expand-file-name "projects" user-emacs-directory))
(when (file-directory-p package-user-dir)
  (package-initialize))
(require 'use-package)
(require 'init-editing)
(require 'init-cmake)
(require 'init-cpp)
(require 'init-build)
(require 'init-help)

(defvar dape-configs)

(defun dotfiles-build-test--write (path text)
  (make-directory (file-name-directory path) t)
  (with-temp-file path (insert text)))

(defun dotfiles-build-test--wait ()
  "Wait for every process and its sentinel to finish."
  (with-timeout (60 (ert-fail "Processes did not finish"))
    (while (seq-some #'process-live-p (process-list))
      (accept-process-output nil 0.05)))
  (accept-process-output nil 0.1))

(defmacro dotfiles-build-test--with-project (&rest body)
  "Run BODY in a fresh project directory bound to `root'."
  (declare (indent 0) (debug t))
  `(let* ((root (file-name-as-directory
                 (file-truename (make-temp-file "emacs build " t))))
          (default-directory root)
          (dotfiles-build--programs (make-hash-table :test #'equal))
          (buffers-before (buffer-list)))
     (unwind-protect
         (save-window-excursion ,@body)
       (dotfiles-build-test--wait)
       (dolist (buffer (buffer-list))
         (unless (memq buffer buffers-before)
           (let ((process (get-buffer-process buffer)))
             (when process (delete-process process)))
           (with-current-buffer buffer (set-buffer-modified-p nil))
           (kill-buffer buffer)))
       (delete-directory root t))))

(defun dotfiles-build-test--output (kind root)
  "Return the text of the KIND output buffer for the project in ROOT."
  (with-current-buffer
      (format "*%s: %s*" kind (file-name-nondirectory (directory-file-name root)))
    (buffer-string)))

(ert-deftest dotfiles-build-detects-each-build-system ()
  (dotfiles-build-test--with-project
    (should-not (dotfiles-build-detect))
    (dotfiles-build-test--write (expand-file-name "pyproject.toml" root) "")
    (should (equal (dotfiles-build-detect) (cons 'python root)))
    (dotfiles-build-test--write (expand-file-name "Makefile" root) "all:\n")
    (should (equal (dotfiles-build-detect) (cons 'make root)))
    ;; A Python buffer runs as Python even beside a Makefile.
    (with-temp-buffer
      (python-mode)
      (should (equal (dotfiles-build-detect t) (cons 'python root))))
    (let ((dotfiles-build-system 'python))
      (should (equal (dotfiles-build-detect) (cons 'python root))))
    (dotfiles-build-test--write (expand-file-name "CMakeLists.txt" root) "")
    (should (eq (car (dotfiles-build-detect)) 'cmake))
    (let ((dotfiles-build-system 'make))
      (should (equal (dotfiles-build-detect) (cons 'make root))))
    ;; Files below the root find the same project.
    (let ((default-directory (expand-file-name "src/deep/" root)))
      (make-directory default-directory t)
      (should (eq (car (dotfiles-build-detect)) 'cmake)))))

(ert-deftest dotfiles-build-reads-explicit-make-targets ()
  (dotfiles-build-test--with-project
    (dotfiles-build-test--write
     (expand-file-name "Makefile" root)
     (concat ".PHONY: all test\nCC := cc\nVAR = x:y\n"
             "all: app\napp lib: main.o\n%.o: %.c\n$(OUT): x\n"
             "test:\n\t./app\nclean:\n\trm -f app\n"))
    (should (equal (dotfiles-make-targets root)
                   '("all" "app" "lib" "test" "clean")))))

(ert-deftest dotfiles-build-make-builds-runs-and-stops-on-failure ()
  (unless (executable-find "make") (ert-skip "make is not installed"))
  (dotfiles-build-test--with-project
    (dotfiles-build-test--write
     (expand-file-name "Makefile" root)
     (concat "all: hello\n"
             "hello:\n\tprintf '#!/bin/sh\\necho \"hello $$1\"\\n' > hello\n"
             "\tchmod +x hello\n"
             "test:\n\techo tests passed\n"
             "broken:\n\tfalse\n"))
    (let ((program (expand-file-name "hello" root)) ran)
      (cl-letf (((symbol-function 'read-file-name) (lambda (&rest _) program))
                ((symbol-function 'read-string) (lambda (&rest _) "\"from make\"")))
        (dotfiles-run)
        (dotfiles-build-test--wait)
        (should (string-match-p "hello from make" (dotfiles-build-test--output "run" root)))
        ;; The chosen program is offered again next time.
        (should (equal (gethash root dotfiles-build--programs) program)))
      (dotfiles-test)
      (dotfiles-build-test--wait)
      (should (string-match-p "tests passed" (dotfiles-build-test--output "make" root)))
      (dotfiles-build--start (dotfiles-make-command "broken") root "make"
                             (lambda () (setq ran t)))
      (dotfiles-build-test--wait)
      (should-not ran))))

(ert-deftest dotfiles-build-python-prefers-the-project-virtualenv ()
  (dotfiles-build-test--with-project
    (let ((python (expand-file-name ".venv/bin/python" root)))
      (dotfiles-build-test--write python "#!/bin/sh\n")
      (set-file-modes python #o755)
      (should (equal (dotfiles-python-interpreter root) python)))
    (should (equal (mapcar #'cdr (dotfiles-python-build-commands root))
                   '(("-m" "pip" "install" "-e" ".") ("-m" "build"))))
    (dotfiles-build-test--write (expand-file-name "setup.py" root) "")
    (should (member '("setup.py" "build_ext" "--inplace")
                    (mapcar #'cdr (dotfiles-python-build-commands root))))))

(ert-deftest dotfiles-build-python-runs-file-and-tests ()
  (unless (executable-find "python3") (ert-skip "python3 is not installed"))
  (dotfiles-build-test--with-project
    (dotfiles-build-test--write (expand-file-name "pyproject.toml" root) "")
    (dotfiles-build-test--write (expand-file-name "app.py" root)
                                "import sys\nprint('hi', *sys.argv[1:])\n")
    (dotfiles-build-test--write
     (expand-file-name "test_app.py" root)
     "import unittest\nclass T(unittest.TestCase):\n    def test_ok(self):\n        pass\n")
    (with-current-buffer (find-file-noselect (expand-file-name "app.py" root))
      (cl-letf (((symbol-function 'read-string) (lambda (&rest _) "there 'two words'")))
        (dotfiles-run))
      (dotfiles-build-test--wait)
      (should (string-match-p "hi there two words" (dotfiles-build-test--output "run" root)))
      (dotfiles-test)
      (dotfiles-build-test--wait)
      (should (string-match-p "Ran 1 test\\|1 passed" (dotfiles-build-test--output "python" root))))))

(ert-deftest dotfiles-build-python-debugger-listens-locally ()
  (unless (locate-library "dape") (ert-skip "Dape is not installed"))
  (let ((config (dotfiles-python-debug-config "/venv/bin/python" "/p/app.py" "/p/" '("a b"))))
    (should (equal (plist-get config 'command) "/venv/bin/python"))
    (should (equal (plist-get config 'command-args)
                   '("-m" "debugpy.adapter" "--host" "127.0.0.1" "--port" :autoport)))
    (should (equal (plist-get config :program) "/p/app.py"))
    (should (equal (plist-get config :cwd) "/p/"))
    (should (equal (plist-get config :args) ["a b"]))
    ;; Dape's own configuration is left untouched.
    (should (equal (plist-get (alist-get 'debugpy dape-configs) 'command) "python"))))

(ert-deftest dotfiles-build-keys-match-vscode-and-clion ()
  (with-temp-buffer
    (dolist (entry '(("C-S-b" . dotfiles-build) ("C-<f9>" . dotfiles-build)
                     ("<f5>" . dotfiles-debug-or-continue) ("C-<f5>" . dotfiles-run)
                     ("S-<f10>" . dotfiles-run) ("S-<f9>" . dotfiles-debug)
                     ("S-<f5>" . dotfiles-stop) ("C-c p b" . dotfiles-build)
                     ("C-c p t" . dotfiles-test) ("C-c p d" . dotfiles-debug)
                     ("C-c p e" . dotfiles-doctor) ("C-c p k" . project-kill-buffers)
                     ("C-S-p" . dotfiles-command-palette) ("C-c ?" . dotfiles-cheatsheet)))
      (should (eq (key-binding (kbd (car entry))) (cdr entry))))))

(ert-deftest dotfiles-palette-shows-keys-and-runs-commands ()
  (let* ((entries (dotfiles-palette--entries))
         (build (assoc "Build: Build project" entries)))
    (should (eq (nth 1 build) 'dotfiles-build))
    (should (member (nth 2 build) '("C-S-b" "C-<f9>" "C-c p b")))
    (should (seq-every-p (lambda (entry) (fboundp (nth 1 entry))) entries))
    (let (ran)
      (cl-letf (((symbol-function 'completing-read)
                 (lambda (_prompt table &rest _)
                   ;; Categories group the list, and labels display without them.
                   (let ((metadata (funcall table "" nil 'metadata)))
                     (should (equal (funcall (alist-get 'group-function (cdr metadata))
                                             "Build: Build project" nil)
                                    "Build"))
                     (should (equal (funcall (alist-get 'group-function (cdr metadata))
                                             "Build: Build project" t)
                                    " Build project")))
                   "Help: Cheatsheet"))
                ((symbol-function 'dotfiles-cheatsheet)
                 (lambda () (interactive) (setq ran t))))
        (dotfiles-command-palette))
      (should ran))
    ;; A typed command name runs even when it is not in the curated list.
    (let (ran)
      (cl-letf (((symbol-function 'completing-read) (lambda (&rest _) "dotfiles-test-only"))
                ((symbol-function 'dotfiles-test-only)
                 (lambda () (interactive) (setq ran t))))
        (dotfiles-command-palette))
      (should ran))))

(ert-deftest dotfiles-welcome-and-cheatsheet-render ()
  (with-current-buffer (dotfiles-welcome-buffer)
    (should (eq major-mode 'dotfiles-welcome-mode))
    (should (string-match-p "Command palette" (buffer-string)))
    (should (button-at (point))))
  (save-window-excursion
    (dotfiles-cheatsheet)
    (with-current-buffer "*Cheatsheet*"
      (should (string-match-p "C-S-b +Build project" (buffer-string)))
      (should (string-match-p "C-g +Cancel" (buffer-string))))))

;;; emacs_build_test.el ends here
