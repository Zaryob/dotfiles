;;; init-build.el --- One build/run/test/debug workflow for CMake, Make and Python -*- lexical-binding: t; -*-

;;; Commentary:

;; The same keys work in every project; the build system is detected from the
;; files nearest to the current buffer, in this order:
;;   CMakeLists.txt                        -> init-cmake (targets from File API)
;;   GNUmakefile, makefile, Makefile       -> make
;;   pyproject.toml, setup.py, setup.cfg   -> python (prefers .venv/venv)
;; A Python buffer always runs and debugs as Python.  Force a choice per
;; project with (dotfiles-build-system . make) in .dir-locals.el.
;;
;; Keys (VSCode and CLion style):
;;   C-S-b / C-<f9>   build          F5          debug / continue
;;   C-<f5> / S-<f10> run            S-<f5>      stop
;;   S-<f9>           debug          F9          toggle breakpoint
;; With a prefix argument (C-u), build asks for a target or a command.

;;; Code:

(require 'cl-lib)
(require 'compile)
(require 'project)
(require 'seq)
(require 'subr-x)
(require 'init-cmake)
(require 'init-cpp)

(defvar dape-configs)
(declare-function dape "dape" (config &optional skip-compile))
(declare-function dape-quit "dape" (&optional conn))
(declare-function dape-continue "dape" (conn))
(declare-function dape--live-connection "dape" (type &optional nowarn require-selected))

(defgroup dotfiles-build nil "Build, run, test and debug projects." :group 'tools)

(defcustom dotfiles-build-system nil
  "Build system for this project, or nil to detect it."
  :type '(choice (const :tag "Detect" nil) (const cmake) (const make) (const python))
  :group 'dotfiles-build
  :safe (lambda (value) (memq value '(nil cmake make python))))

(defconst dotfiles-build-makefiles '("GNUmakefile" "makefile" "Makefile"))
(defconst dotfiles-build-python-markers '("pyproject.toml" "setup.py" "setup.cfg"))

(defvar dotfiles-build--programs (make-hash-table :test #'equal)
  "Program last chosen to run or debug in each Make or Python project.")
(defvar dotfiles-build--argument-history nil)
(defvar dotfiles-build--target-history nil)

;;;; Detection

(defun dotfiles-build--locate (names)
  "Return the nearest directory above `default-directory' with one of NAMES."
  (when-let* ((root (locate-dominating-file
                     default-directory
                     (lambda (directory)
                       (seq-some (lambda (name)
                                   (file-exists-p (expand-file-name name directory)))
                                 names)))))
    (file-name-as-directory (expand-file-name root))))

(defun dotfiles-build--python-root ()
  "Python project root, else the project root, else this directory."
  (or (dotfiles-build--locate dotfiles-build-python-markers)
      (when-let* ((project (project-current nil)))
        (file-name-as-directory (expand-file-name (project-root project))))
      (file-name-as-directory (expand-file-name default-directory))))

(defun dotfiles-build-detect (&optional prefer-buffer)
  "Return (SYSTEM . ROOT) for this buffer, or nil without a build system.
With PREFER-BUFFER, a Python buffer is always handled as Python."
  (let ((wanted (lambda (system)
                  (memq dotfiles-build-system (list nil system)))))
    (or (and prefer-buffer (null dotfiles-build-system)
             (derived-mode-p 'python-mode 'python-ts-mode)
             (cons 'python (dotfiles-build--python-root)))
        (and (funcall wanted 'cmake)
             (when-let* ((root (dotfiles-cmake-root)))
               (cons 'cmake (file-name-as-directory (expand-file-name root)))))
        (and (funcall wanted 'make)
             (when-let* ((root (dotfiles-build--locate dotfiles-build-makefiles)))
               (cons 'make root)))
        (and (funcall wanted 'python)
             (when-let* ((root (or (dotfiles-build--locate dotfiles-build-python-markers)
                                   (and (eq dotfiles-build-system 'python)
                                        (dotfiles-build--python-root)))))
               (cons 'python root))))))

(defun dotfiles-build--require (&optional prefer-buffer)
  "Like `dotfiles-build-detect', but explain how to proceed when nothing is found."
  (or (dotfiles-build-detect prefer-buffer)
      (user-error "No CMakeLists.txt, Makefile, setup.py or pyproject.toml found; try M-x compile")))

;;;; Processes

(defun dotfiles-build--shell (arguments)
  "Quote and join the strings in ARGUMENTS for a shell."
  (mapconcat #'shell-quote-argument arguments " "))

(defun dotfiles-build--start (command root kind &optional callback interactive)
  "Run COMMAND in ROOT in a buffer named after KIND.
Call CALLBACK in the original buffer only after success.  INTERACTIVE
non-nil lets the program read input."
  (let* ((origin (current-buffer))
         (default-directory root)
         (name (format "*%s: %s*" kind
                       (file-name-nondirectory (directory-file-name root))))
         (buffer (compilation-start command interactive (lambda (_) name)))
         (process (get-buffer-process buffer))
         finish)
    (when callback
      ;; Compilation detaches its process before running finish hooks.
      (setq finish
            (lambda (finished-buffer _message)
              (with-current-buffer finished-buffer
                (remove-hook 'compilation-finish-functions finish t))
              (when (and process (eq (process-status process) 'exit)
                         (zerop (process-exit-status process))
                         (buffer-live-p origin))
                (with-current-buffer origin (funcall callback)))))
      (with-current-buffer buffer
        (add-hook 'compilation-finish-functions finish nil t)))
    buffer))

(defun dotfiles-build--read-arguments ()
  "Read program arguments, split as a shell would."
  (split-string-shell-command
   (read-string "Program arguments: " nil 'dotfiles-build--argument-history)))

(defun dotfiles-build--read-program (root prompt &optional predicate)
  "Read a file in ROOT with PROMPT, defaulting to the last one chosen there.
PREDICATE limits the accepted files."
  (let* ((last (gethash root dotfiles-build--programs))
         (file (expand-file-name
                (read-file-name prompt root last t
                                (and last (file-relative-name last root))
                                predicate))))
    (puthash root file dotfiles-build--programs)
    file))

;;;; Make

(defun dotfiles-make-targets (root)
  "Return explicit target names from the Makefile in ROOT."
  (when-let* ((file (seq-find #'file-readable-p
                              (mapcar (lambda (name) (expand-file-name name root))
                                      dotfiles-build-makefiles))))
    (with-temp-buffer
      (insert-file-contents file)
      (let (targets)
        (goto-char (point-min))
        ;; "name other: deps" but not "name := value"; skip .SPECIAL targets.
        (while (re-search-forward
                "^\\([[:alnum:]_][^:#=\n]*\\):\\(?:[^=]\\|$\\)" nil t)
          (dolist (target (split-string (match-string 1)))
            (unless (string-match-p "[%$]" target)
              (cl-pushnew target targets :test #'equal))))
        (nreverse targets)))))

(defun dotfiles-make-command (&optional target)
  "Return the make command for TARGET, or for the default target."
  (dotfiles-build--shell
   (append (list "make" "-k" (format "-j%d" (num-processors)))
           (and target (list target)))))

(defun dotfiles-make--executable-p (file)
  "Whether FILE is a regular executable file, or a directory to descend."
  (or (file-directory-p file)
      (and (file-regular-p file) (file-executable-p file))))

;;;; Python

(defun dotfiles-python-interpreter (root)
  "Return the project virtualenv's Python in ROOT, or the system Python."
  (or (seq-find #'file-executable-p
                (mapcar (lambda (directory) (expand-file-name directory root))
                        '(".venv/bin/python" "venv/bin/python" "env/bin/python")))
      (when-let* ((venv (getenv "VIRTUAL_ENV"))
                  (python (expand-file-name "bin/python" venv)))
        (and (file-executable-p python) python))
      (executable-find "python3")
      (executable-find "python")
      (user-error "Python is missing; install python3")))

(defun dotfiles-python--has-module-p (python module)
  "Whether PYTHON can import MODULE."
  (zerop (process-file python nil nil nil "-c" (concat "import " module))))

(defun dotfiles-python-build-commands (root)
  "Return (DESCRIPTION . ARGUMENTS) build choices for the project in ROOT."
  (let ((setup (file-exists-p (expand-file-name "setup.py" root))))
    (append '(("Install in editable mode (pip install -e .)" "-m" "pip" "install" "-e" "."))
            (and setup
                 '(("Build C extensions in place (setup.py build_ext --inplace)"
                    "setup.py" "build_ext" "--inplace")
                   ("Build (setup.py build)" "setup.py" "build")))
            '(("Build wheel and sdist (python -m build)" "-m" "build")))))

(defun dotfiles-python-debug-config (python program root args)
  "Return a Dape debugpy configuration running PROGRAM with PYTHON in ROOT."
  (require 'dape)
  (let ((config (copy-sequence (alist-get 'debugpy dape-configs))))
    (unless config (user-error "This Dape version has no debugpy configuration"))
    ;; Dape's default adapter listens on every interface; keep it local.
    (cl-loop for (key value) on
             `(command ,python
               command-args ("-m" "debugpy.adapter" "--host" "127.0.0.1"
                             "--port" :autoport)
               command-cwd ,root :cwd ,root :program ,program :args ,(vconcat args))
             by #'cddr
             do (setq config (plist-put config key value)))
    config))

(defun dotfiles-python--ensure-debugpy (python root)
  "Signal unless PYTHON has debugpy, offering to install it from ROOT."
  (unless (dotfiles-python--has-module-p python "debugpy")
    (when (y-or-n-p (format "%s has no debugpy.  Install it now? " python))
      (dotfiles-build--start
       (dotfiles-build--shell (list python "-m" "pip" "install" "debugpy"))
       root "python")
      (user-error "Installing debugpy; press F5 again when it finishes"))
    (user-error "Debugging Python needs: %s -m pip install debugpy" python)))

(defun dotfiles-python--program (root)
  "Return this buffer's Python file, or read one in ROOT."
  (if (and buffer-file-name (string-suffix-p ".py" buffer-file-name))
      buffer-file-name
    (dotfiles-build--read-program
     root "Python file: "
     (lambda (file) (or (file-directory-p file) (string-suffix-p ".py" file))))))

;;;; Commands

(defun dotfiles-build (&optional choose)
  "Build this project.  With CHOOSE (\\[universal-argument]), pick a target or command."
  (interactive "P")
  (save-some-buffers)
  (pcase-let ((`(,system . ,root) (or (dotfiles-build-detect)
                                      (cons nil default-directory))))
    (pcase system
      ('cmake (dotfiles-cmake-build
               (and choose (read-string "CMake target: " nil 'dotfiles-build--target-history))))
      ('make (dotfiles-build--start
              (dotfiles-make-command
               (and choose (completing-read "Make target: " (dotfiles-make-targets root)
                                            nil nil nil 'dotfiles-build--target-history)))
              root "make"))
      ('python
       (let* ((choices (dotfiles-python-build-commands root))
              (choice (if choose
                          (assoc (completing-read "Build: " choices nil t) choices)
                        (car choices))))
         (dotfiles-build--start
          (dotfiles-build--shell (cons (dotfiles-python-interpreter root) (cdr choice)))
          root "python")))
      (_ (call-interactively #'compile)))))

(defun dotfiles-run ()
  "Build if needed, then run a program from this project without debugging."
  (interactive)
  (pcase-let ((`(,system . ,root) (dotfiles-build--require t)))
    (pcase system
      ('cmake (dotfiles-cmake-run))
      ('make
       (let ((program (dotfiles-build--read-program
                       root "Program to run: " #'dotfiles-make--executable-p))
             (arguments (dotfiles-build--read-arguments)))
         (save-some-buffers)
         (dotfiles-build--start
          (dotfiles-make-command) root "make"
          (lambda ()
            (dotfiles-build--start (dotfiles-build--shell (cons program arguments))
                                   root "run" nil t)))))
      ('python
       (let ((program (dotfiles-python--program root))
             (arguments (dotfiles-build--read-arguments)))
         (save-some-buffers)
         (dotfiles-build--start
          (dotfiles-build--shell
           (append (list (dotfiles-python-interpreter root) program) arguments))
          root "run" nil t))))))

(defun dotfiles-test ()
  "Run this project's tests: CTest, make test/check, or pytest/unittest."
  (interactive)
  (save-some-buffers)
  (pcase-let ((`(,system . ,root) (dotfiles-build--require)))
    (pcase system
      ('cmake (dotfiles-cmake-test))
      ('make
       (let ((target (seq-find (lambda (name) (member name (dotfiles-make-targets root)))
                               '("test" "check" "tests"))))
         (unless target (user-error "The Makefile has no test, check or tests target"))
         (dotfiles-build--start (dotfiles-make-command target) root "make")))
      ('python
       (let ((python (dotfiles-python-interpreter root)))
         (dotfiles-build--start
          (dotfiles-build--shell
           (if (dotfiles-python--has-module-p python "pytest")
               (list python "-m" "pytest")
             (list python "-m" "unittest" "discover")))
          root "python"))))))

(defun dotfiles-clean ()
  "Remove build products."
  (interactive)
  (pcase-let ((`(,system . ,root) (dotfiles-build--require)))
    (pcase system
      ('cmake (dotfiles-cmake-build "clean"))
      ('make (dotfiles-build--start (dotfiles-make-command "clean") root "make"))
      ('python
       (unless (file-exists-p (expand-file-name "setup.py" root))
         (user-error "Nothing to clean: this project has no setup.py"))
       (dotfiles-build--start
        (dotfiles-build--shell (list (dotfiles-python-interpreter root)
                                     "setup.py" "clean" "--all"))
        root "python")))))

(defun dotfiles-configure ()
  "Prepare the project: CMake configure, ./configure, or a Python virtualenv."
  (interactive)
  (pcase-let ((`(,system . ,root) (dotfiles-build--require t)))
    (pcase system
      ('cmake (dotfiles-cmake-configure))
      ('make
       (let ((default-directory root))
         (cond ((file-executable-p "configure")
                (dotfiles-build--start "./configure" root "make"))
               ((file-executable-p "autogen.sh")
                (dotfiles-build--start "./autogen.sh && ./configure" root "make"))
               (t (user-error "This Makefile project has no configure step")))))
      ('python
       (let ((venv (expand-file-name ".venv" root)))
         (when (file-exists-p venv)
           (user-error "%s already exists" (abbreviate-file-name venv)))
         (dotfiles-build--start
          (concat (dotfiles-build--shell
                   (list (or (executable-find "python3") "python") "-m" "venv" venv))
                  (when (seq-some (lambda (name) (file-exists-p (expand-file-name name root)))
                                  dotfiles-build-python-markers)
                    (concat " && " (dotfiles-build--shell
                                    (list (expand-file-name "bin/python" venv)
                                          "-m" "pip" "install" "-e" ".")))))
          root "python"))))))

(defun dotfiles-debug ()
  "Build if needed, then start the debugger on a program from this project."
  (interactive)
  (require 'dape)
  (pcase-let ((`(,system . ,root) (dotfiles-build--require t)))
    (pcase system
      ('cmake (dotfiles-cpp-debug))
      ('make
       ;; Find an adapter before building, so a missing debugger fails fast.
       (dotfiles-cpp-debug-config "" root nil)
       (let ((program (dotfiles-build--read-program
                       root "Program to debug: " #'dotfiles-make--executable-p))
             (arguments (dotfiles-build--read-arguments)))
         (save-some-buffers)
         (dotfiles-build--start
          (dotfiles-make-command) root "make"
          (lambda () (dape (dotfiles-cpp-debug-config program root arguments))))))
      ('python
       (let ((python (dotfiles-python-interpreter root)))
         (dotfiles-python--ensure-debugpy python root)
         (let ((program (dotfiles-python--program root))
               (arguments (dotfiles-build--read-arguments)))
           (save-some-buffers)
           (dape (dotfiles-python-debug-config python program root arguments))))))))

(defun dotfiles-debug--live-p ()
  "Whether a debugger session is running."
  (and (featurep 'dape) (dape--live-connection 'last t)))

(defun dotfiles-debug-or-continue ()
  "Continue a running debugger session, or start a new one."
  (interactive)
  (if (dotfiles-debug--live-p)
      (call-interactively #'dape-continue)
    (dotfiles-debug)))

(defun dotfiles-stop ()
  "Stop the debugger, or the running build or program."
  (interactive)
  (if (dotfiles-debug--live-p)
      (call-interactively #'dape-quit)
    ;; The most recently used build or program buffer that is still running.
    (if-let* ((buffer (seq-find (lambda (buffer)
                                  (and (get-buffer-process buffer)
                                       (with-current-buffer buffer
                                         (or (derived-mode-p 'compilation-mode)
                                             (bound-and-true-p
                                              compilation-shell-minor-mode)))))
                                (buffer-list))))
        (interrupt-process (get-buffer-process buffer))
      (message "Nothing is running"))))

(defun dotfiles-doctor ()
  "Show which development tools are installed and how to install missing ones."
  (interactive)
  (let* ((detected (dotfiles-build-detect t))
         (python (ignore-errors (dotfiles-python-interpreter
                                 (or (cdr detected) default-directory))))
         (module (lambda (name) (and python (dotfiles-python--has-module-p python name)
                                     (format "%s (%s)" name python))))
         (brew (eq system-type 'darwin)))
    (with-help-window "*Development tools*"
      (princ (format "Build system for this buffer: %s\n\n"
                     (if detected
                         (format "%s in %s" (car detected)
                                 (abbreviate-file-name (cdr detected)))
                       "none (C-S-b runs M-x compile)")))
      (pcase-dolist (`(,name ,found ,hint)
                     `(("CMake" ,(executable-find "cmake")
                        ,(if brew "brew install cmake" "apt install cmake"))
                       ("Ninja (faster builds)" ,(executable-find "ninja")
                        ,(if brew "brew install ninja" "apt install ninja-build"))
                       ("Make" ,(executable-find "make")
                        ,(if brew "xcode-select --install" "apt install build-essential"))
                       ("clangd (C/C++ IDE)" ,(dotfiles-cpp-clangd)
                        ,(if brew "brew install llvm" "apt install clangd"))
                       ("LLDB DAP (C/C++ debugger)" ,(dotfiles-cpp-lldb-adapter)
                        ,(if brew "brew install llvm" "apt install lldb"))
                       ("GDB 14.1+ (C/C++ debugger)" ,(dotfiles-cpp-find-tool "gdb")
                        ,(if brew "brew install gdb" "apt install gdb"))
                       ("Python" ,python ,(if brew "brew install python" "apt install python3"))
                       ("debugpy (Python debugger)" ,(funcall module "debugpy")
                        "python -m pip install debugpy")
                       ("pytest" ,(funcall module "pytest") "python -m pip install pytest")
                       ("Python language server"
                        ,(seq-some (lambda (command) (executable-find (car command)))
                                   dotfiles-python-server-programs)
                        "pipx install basedpyright")
                       ("ripgrep (project search)" ,(executable-find "rg")
                        ,(if brew "brew install ripgrep" "apt install ripgrep"))))
        (princ (format "%-28s %s\n" name
                       (or found (format "missing  ->  %s" hint)))))
      (princ "\nAfter installing a language server, reopen the file or run M-x eglot-reconnect.\n"))))

;;;; Keys and windows

(dolist (binding '(("C-S-b"   . dotfiles-build)
                   ("C-<f9>"  . dotfiles-build)
                   ("<f5>"    . dotfiles-debug-or-continue)
                   ("C-<f5>"  . dotfiles-run)
                   ("S-<f10>" . dotfiles-run)
                   ("S-<f9>"  . dotfiles-debug)
                   ("S-<f5>"  . dotfiles-stop)))
  (keymap-global-set (car binding) (cdr binding)))

(defun dotfiles-build-bind (map)
  "Point MAP's build keys at the commands for every build system."
  (keymap-set map "c" #'dotfiles-configure)
  (keymap-set map "b" #'dotfiles-build)
  (keymap-set map "t" #'dotfiles-test)
  (keymap-set map "r" #'dotfiles-run)
  (keymap-set map "d" #'dotfiles-debug)
  (keymap-set map "e" #'dotfiles-doctor))

(dotfiles-build-bind project-prefix-map)
(defvar dotfiles-build-map)
(with-eval-after-load 'init-project
  (dotfiles-build-bind dotfiles-build-map)
  ;; Only the leader map: C-c p x and C-c p k keep their project.el commands.
  (keymap-set dotfiles-build-map "x" #'dotfiles-clean)
  (keymap-set dotfiles-build-map "k" #'dotfiles-stop))

;; Build and program output opens in a bottom panel, as in an IDE.
(add-to-list 'display-buffer-alist
             '("\\`\\*\\(?:compilation\\|cmake\\|make\\|python\\|run\\)\\(?::\\|-run\\|\\*\\)"
               (display-buffer-reuse-window display-buffer-in-side-window)
               (side . bottom) (slot . 0) (window-height . 0.3)))

(provide 'init-build)
;;; init-build.el ends here
