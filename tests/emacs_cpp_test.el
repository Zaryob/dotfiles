;;; emacs_cpp_test.el --- C++ workflow integration tests -*- lexical-binding: t; -*-

;;; Commentary:

;; Run with tests/emacs_cpp_test.sh.  This loads early-init and workflow modules:
;; the user's init, packages and project list are deliberately isolated.
;; CMake integration tests use a real compiler and project, including paths
;; containing spaces.  Missing external tools are reported as ERT skips.

;;; Code:

(require 'ert)
(require 'cl-lib)
(require 'seq)
(require 'subr-x)
(require 'use-package)

(setq user-emacs-directory
      (or (getenv "DOTFILES_CPP_TEST_EMACS_DIRECTORY")
          (error "Run this test through tests/emacs_cpp_test.sh"))
      use-package-always-ensure nil
      package-enable-at-startup nil
      load-prefer-newer t
      project-list-file (expand-file-name "projects" user-emacs-directory))

(require 'init-cmake)
(require 'init-cpp)

(defvar dape-configs)

(defun dotfiles-cpp-test--write (path text)
  "Write TEXT to PATH, creating its parent directory."
  (make-directory (file-name-directory path) t)
  (with-temp-file path (insert text)))

(defun dotfiles-cpp-test--read (path)
  "Read PATH as text."
  (with-temp-buffer
    (insert-file-contents path)
    (buffer-string)))

(defun dotfiles-cpp-test--wait (predicate &optional seconds)
  "Wait at most SECONDS for PREDICATE while dispatching process events."
  (let ((deadline (+ (float-time) (or seconds 30))))
    (while (and (not (funcall predicate)) (< (float-time) deadline))
      (accept-process-output nil 0.1))
    (should (funcall predicate))))

(defun dotfiles-cpp-test--wait-processes ()
  "Wait for test processes and their sentinels to finish."
  (dotfiles-cpp-test--wait
   (lambda () (not (seq-some #'process-live-p (process-list)))) 60))

(defun dotfiles-cpp-test--require-toolchain ()
  "Skip an integration test when CMake or a C++ compiler is unavailable."
  (unless (and (executable-find "cmake")
               (or (executable-find "c++")
                   (executable-find "g++")
                   (executable-find "clang++")))
    (ert-skip "CMake and a C++ compiler are needed for this integration test")))

(defun dotfiles-cpp-test--fixture (root)
  "Create a CMake project under ROOT with an executable, library and CTest."
  (dotfiles-cpp-test--write
   (expand-file-name "CMakeLists.txt" root)
   "cmake_minimum_required(VERSION 3.16)\nproject(EmacsCppFixture LANGUAGES CXX)\nset(CMAKE_CXX_STANDARD 17)\nadd_library(cpp_test_support STATIC src/helper.cpp)\nadd_executable(hello_app src/main.cpp)\ntarget_link_libraries(hello_app PRIVATE cpp_test_support)\nset_target_properties(hello_app PROPERTIES RUNTIME_OUTPUT_DIRECTORY \"${CMAKE_BINARY_DIR}/runtime with spaces\")\nenable_testing()\nadd_test(NAME argument_round_trip COMMAND hello_app ctest-value)\n")
  (dotfiles-cpp-test--write
   (expand-file-name "src/helper.cpp" root)
   "#include <string>\nstd::string greeting(const std::string& value) { return \"cpp-fixture:\" + value; }\n")
  (dotfiles-cpp-test--write
   (expand-file-name "src/main.cpp" root)
   "#include <iostream>\n#include <string>\nstd::string greeting(const std::string&);\nint main(int argc, char** argv) {\n  if (argc != 2) return 2;\n  std::cout << greeting(argv[1]) << '\\n';\n  return 0;\n}\n"))

(defmacro dotfiles-cpp-test--with-project (&rest body)
  "Execute BODY in an isolated CMake project with spaces in its path."
  (declare (indent 0) (debug t))
  `(let* ((trial (make-temp-file "emacs cpp tests " t))
          (root (file-name-as-directory
                 (expand-file-name "project with spaces" trial)))
          (default-directory root)
          (dotfiles-cmake-build-directory "build with spaces")
          (dotfiles-cmake-build-type "Debug")
          (dotfiles-cmake-configure-arguments nil)
          (dotfiles-cmake--settings (make-hash-table :test #'equal))
          (dotfiles-cmake--configured (make-hash-table :test #'equal))
          (dotfiles-cmake--database-links (make-hash-table :test #'equal))
          (dotfiles-cmake--database-links-loaded nil)
          (user-emacs-directory (expand-file-name "emacs state/" trial))
          (buffers-before (buffer-list)))
     (unwind-protect
         (progn
           (make-directory user-emacs-directory t)
           (dotfiles-cpp-test--fixture root)
           ,@body)
       (dolist (process (process-list))
         (when (process-live-p process) (delete-process process)))
       (dolist (buffer (buffer-list))
         (unless (memq buffer buffers-before)
           (with-current-buffer buffer (set-buffer-modified-p nil))
           (kill-buffer buffer)))
       (delete-directory trial t))))

(ert-deftest dotfiles-cpp-non-git-project-discovery ()
  "A source buffer in a non-Git CMake project is recognized by project.el."
  (dotfiles-cpp-test--with-project
    (let* ((default-directory (expand-file-name "src/" root))
           (project (project-current nil)))
      (should-not (file-exists-p (expand-file-name ".git" root)))
      (should project)
      (should (equal (file-name-as-directory (project-root project)) root))
      (should (equal (dotfiles-cmake-root) root))
      (should (equal (dotfiles-cmake-build-dir)
                     (expand-file-name "build with spaces/" root))))))

(ert-deftest dotfiles-cpp-project-build-settings-are-independent ()
  "Interactive settings belong to one project; dir-local values also work."
  (dotfiles-cpp-test--require-toolchain)
  (dotfiles-cpp-test--with-project
    (let* ((second-root (file-name-as-directory
                         (expand-file-name "second project" trial)))
           (chosen-build (expand-file-name "custom build/" root)))
      (dotfiles-cpp-test--fixture second-root)
      (cl-letf (((symbol-function 'read-directory-name)
                 (lambda (&rest _) chosen-build))
                ((symbol-function 'completing-read)
                 (lambda (&rest _) "Release")))
        (dotfiles-cmake-settings))
      (should (equal (dotfiles-cmake-build-dir) chosen-build))
      (should (equal (nth 2 (dotfiles-cmake--context)) "Release"))
      (let ((default-directory second-root))
        (should (equal (dotfiles-cmake-build-dir)
                       (expand-file-name "build with spaces/" second-root)))
        (should (equal (nth 2 (dotfiles-cmake--context)) "Debug")))
      (with-temp-buffer
        (setq default-directory second-root)
        (setq-local dotfiles-cmake-build-directory "dir local build"
                    dotfiles-cmake-build-type "RelWithDebInfo"
                    dotfiles-cmake-configure-arguments '("-DFIXTURE=value with spaces"))
        (should (equal (dotfiles-cmake--context)
                       (list second-root
                             (expand-file-name "dir local build/" second-root)
                             "RelWithDebInfo" '("-DFIXTURE=value with spaces"))))))))

(ert-deftest dotfiles-cpp-configure-build-run-and-ctest ()
  "Real File API targets, paths, arguments, builds and CTest work together."
  (dotfiles-cpp-test--require-toolchain)
  (unless (executable-find "ctest") (ert-skip "CTest is not installed"))
  (dotfiles-cpp-test--with-project
    (let ((dotfiles-cmake-configure-arguments
           '("-DFIXTURE_OPTION:STRING=value with spaces")))
      (dotfiles-cmake-configure)
      (dotfiles-cpp-test--wait-processes)
      (let* ((build (dotfiles-cmake-build-dir))
             (database (expand-file-name "compile_commands.json" root))
             (targets (dotfiles-cmake--executables (dotfiles-cmake--context)))
             (target (dotfiles-cmake-select-executable)))
        (should (equal (mapcar #'car targets) '("hello_app")))
        (should-not (assoc "cpp_test_support" targets))
        (should (equal (car target) "hello_app"))
        (should (file-name-absolute-p (cdr target)))
        (should (string-match-p "runtime with spaces/hello_app" (cdr target)))
        (should (file-symlink-p database))
        (should (string-match-p "src/main.cpp" (dotfiles-cpp-test--read database)))
        (should (string-match-p "FIXTURE_OPTION:STRING=value with spaces"
                                (dotfiles-cpp-test--read
                                 (expand-file-name "CMakeCache.txt" build))))
        (let (built)
          (dotfiles-cmake-after-build (car target) (lambda () (setq built t)))
          (dotfiles-cpp-test--wait-processes)
          (should built)
          (should (file-executable-p (cdr target)))
          (with-temp-buffer
            (should (zerop (call-process (cdr target) nil t nil "argument with spaces")))
            (should (equal (buffer-string) "cpp-fixture:argument with spaces\n"))))
        (cl-letf (((symbol-function 'read-string)
                   (lambda (&rest _) "\"two words\"")))
          (dotfiles-cmake-run))
        (dotfiles-cpp-test--wait-processes)
        (with-current-buffer (get-buffer "*cmake-run*")
          (should (string-match-p "cpp-fixture:two words" (buffer-string))))
        (dotfiles-cmake-test)
        (dotfiles-cpp-test--wait-processes)
        (should (string-match-p "Test Passed"
                                (dotfiles-cpp-test--read
                                 (expand-file-name "Testing/Temporary/LastTest.log" build))))))))

(ert-deftest dotfiles-cpp-configure-before-selecting-executable ()
  "An initial executable request waits for successful asynchronous configure."
  (dotfiles-cpp-test--require-toolchain)
  (dotfiles-cpp-test--with-project
    (let (selected callback-buffer)
      (dotfiles-cmake-with-executable
       (lambda (target)
         (setq selected target callback-buffer (current-buffer))))
      (dotfiles-cpp-test--wait-processes)
      (should (equal (car selected) "hello_app"))
      (should (eq callback-buffer (current-buffer)))
      (should (file-exists-p (expand-file-name "CMakeCache.txt"
                                               (dotfiles-cmake-build-dir)))))))

(ert-deftest dotfiles-cpp-run-refreshes-artifact-after-cmake-regeneration ()
  "Run uses a regenerated target path even when its old executable remains."
  (dotfiles-cpp-test--require-toolchain)
  (dotfiles-cpp-test--with-project
    (dotfiles-cmake-build "hello_app")
    (dotfiles-cpp-test--wait-processes)
    (let* ((old-target (dotfiles-cmake-select-executable))
           (cmake-file (expand-file-name "CMakeLists.txt" root))
           (helper-file (expand-file-name "src/helper.cpp" root)))
      (should (file-executable-p (cdr old-target)))
      ;; --build regenerates CMake's File API after this edit.  The target
      ;; selected before that build still points at the previous artifact.
      (dotfiles-cpp-test--write
       cmake-file
       (replace-regexp-in-string "runtime with spaces" "new runtime with spaces"
                                 (dotfiles-cpp-test--read cmake-file) t t))
      (dotfiles-cpp-test--write
       helper-file
       (replace-regexp-in-string "cpp-fixture:" "cpp-fixture-new:"
                                 (dotfiles-cpp-test--read helper-file) t t))
      (cl-letf (((symbol-function 'read-string)
                 (lambda (&rest _) "\"round trip\"")))
        (dotfiles-cmake-run))
      (dotfiles-cpp-test--wait-processes)
      (let ((new-target (dotfiles-cmake-executable "hello_app")))
        (should-not (equal (cdr new-target) (cdr old-target)))
        (should (string-match-p "new runtime with spaces/hello_app"
                                (cdr new-target)))
        (should (file-executable-p (cdr new-target))))
      (should (file-executable-p (cdr old-target)))
      (with-temp-buffer
        (should (zerop (call-process (cdr old-target) nil t nil "round trip")))
        (should (equal (buffer-string) "cpp-fixture:round trip\n")))
      (with-current-buffer (get-buffer "*cmake-run*")
        (should (string-match-p "cpp-fixture-new:round trip" (buffer-string)))))))

(ert-deftest dotfiles-cpp-project-menu-is-globally-bound ()
  "The documented project shortcuts reach their commands from a new buffer."
  (with-temp-buffer
    (dolist (binding '(("c" . dotfiles-cmake-configure)
                       ("b" . dotfiles-cmake-build)
                       ("t" . dotfiles-cmake-test)
                       ("r" . dotfiles-cmake-run)
                       ("d" . dotfiles-cpp-debug)
                       ("s" . dotfiles-cmake-settings)
                       ("h" . dotfiles-cpp-switch-source-header)
                       ("e" . dotfiles-cpp-environment)))
      (should (eq (key-binding (kbd (concat "C-c p " (car binding))))
                  (cdr binding))))))

(ert-deftest dotfiles-cpp-failed-build-never-runs-callback ()
  "A failed rebuild cannot run a stale executable through its callback."
  (dotfiles-cpp-test--require-toolchain)
  (dotfiles-cpp-test--with-project
    (let (built)
      (dotfiles-cmake-after-build "hello_app" (lambda () (setq built t)))
      (dotfiles-cpp-test--wait-processes)
      (should built))
    (let* ((target (dotfiles-cmake-select-executable))
           (marker (expand-file-name "must not be created" root))
           invoked)
      (should (file-executable-p (cdr target)))
      (dotfiles-cpp-test--write (expand-file-name "src/main.cpp" root)
                                "#error deliberately invalid source\n")
      (dotfiles-cmake-after-build
       (car target)
       (lambda ()
         (setq invoked t)
         (dotfiles-cpp-test--write marker "callback ran")))
      (dotfiles-cpp-test--wait-processes)
      (should-not invoked)
      (should-not (file-exists-p marker)))))

(ert-deftest dotfiles-cpp-user-compilation-database-is-preserved ()
  "Configure preserves user-owned compilation databases, including links."
  (dotfiles-cpp-test--require-toolchain)
  (dolist (kind '(file symlink broken-symlink))
    (dotfiles-cpp-test--with-project
      (let* ((database (expand-file-name "compile_commands.json" root))
             (owned (expand-file-name "owned database.json" trial))
             (content "[{\"user-owned\":true}]\n"))
        (pcase kind
          ('file (dotfiles-cpp-test--write database content))
          ('symlink
           (dotfiles-cpp-test--write owned content)
           (make-symbolic-link owned database))
          ('broken-symlink (make-symbolic-link owned database)))
        (dotfiles-cmake-configure)
        (dotfiles-cpp-test--wait-processes)
        (should (file-exists-p (expand-file-name "compile_commands.json"
                                                 (dotfiles-cmake-build-dir))))
        (if (eq kind 'file)
            (progn
              (should-not (file-symlink-p database))
              (should (equal (dotfiles-cpp-test--read database) content)))
          (should (equal (file-symlink-p database) owned))
          (if (eq kind 'symlink)
              (should (equal (dotfiles-cpp-test--read database) content))
            (should-not (file-exists-p owned))))))))

(ert-deftest dotfiles-cpp-lldb-debug-configuration ()
  "LLDB gets the selected artifact, working directory and argument vector."
  (cl-letf (((symbol-function 'dotfiles-cpp-lldb-adapter)
             (lambda () "/tool path/lldb-dap")))
    (let ((config (dotfiles-cpp-debug-config
                   "/project path/runtime with spaces/hello_app"
                   "/project path/" '("two words" "--flag"))))
      (should (equal (plist-get config 'command) "/tool path/lldb-dap"))
      (should (equal (plist-get config :type) "lldb-dap"))
      (should (eq (plist-get config 'ensure) 'dape-ensure-command))
      (should (equal (plist-get config :request) "launch"))
      (should (equal (plist-get config 'command-cwd) "/project path/"))
      (should (equal (plist-get config :cwd) "/project path/"))
      (should (equal (plist-get config :program)
                     "/project path/runtime with spaces/hello_app"))
      (should (equal (plist-get config :args) ["two words" "--flag"])))))

(ert-deftest dotfiles-cpp-gdb-debug-configuration-overrides-defaults ()
  "A GDB launch uses project values and preserves Dape's version validator."
  (let* ((original-require (symbol-function 'require))
         (original '(command "gdb" command-args ("--interpreter=dap")
                     ensure dape-ensure-gdb-version :type "gdb"
                     command-cwd "/old/" :cwd "/old/"
                     :request "attach" :program "old-program" :args ["old"]))
         (dape-configs (list (cons 'gdb original))))
    (cl-letf (((symbol-function 'require)
               (lambda (feature &rest arguments)
                 (if (eq feature 'dape) t
                   (apply original-require feature arguments))))
              ((symbol-function 'dotfiles-cpp-lldb-adapter) (lambda () nil))
              ((symbol-function 'dotfiles-cpp-find-tool)
               (lambda (name) (and (equal name "gdb") "/tool path/gdb"))))
      (let ((config (dotfiles-cpp-debug-config
                     "/project path/hello_app" "/project path/"
                     '("two words" "--flag"))))
        (should (equal (plist-get config 'command) "/tool path/gdb"))
        (should (equal (plist-get config 'command-args) '("--interpreter=dap")))
        (should (eq (plist-get config 'ensure) 'dape-ensure-gdb-version))
        (should (equal (plist-get config :type) "gdb"))
        (should (equal (plist-get config :request) "launch"))
        (should (equal (plist-get config 'command-cwd) "/project path/"))
        (should (equal (plist-get config :cwd) "/project path/"))
        (should (equal (plist-get config :program) "/project path/hello_app"))
        (should (equal (plist-get config :args) ["two words" "--flag"]))
        (dolist (field '(command command-cwd :request :cwd :program :args))
          (should (= 1 (cl-loop for (key _value) on config by #'cddr
                                count (eq key field)))))
        (should (equal original (cdr (assq 'gdb dape-configs))))))))

(ert-deftest dotfiles-cpp-managed-database-link-survives-restart ()
  "Recorded helper-owned links follow a new build directory after a restart."
  (dotfiles-cpp-test--require-toolchain)
  (dotfiles-cpp-test--with-project
    (let ((database (expand-file-name "compile_commands.json" root)))
      (dotfiles-cmake-configure)
      (dotfiles-cpp-test--wait-processes)
      (should (equal (file-symlink-p database)
                     (expand-file-name "compile_commands.json"
                                       (dotfiles-cmake-build-dir))))
      (should (file-readable-p
               (locate-user-emacs-file "var/cmake-database-links.json")))
      ;; A fresh Emacs instance has empty memory but the same state directory.
      (setq dotfiles-cmake--database-links (make-hash-table :test #'equal)
            dotfiles-cmake--database-links-loaded nil
            dotfiles-cmake--configured (make-hash-table :test #'equal)
            dotfiles-cmake-build-directory "new build with spaces")
      (dotfiles-cmake-configure)
      (dotfiles-cpp-test--wait-processes)
      (should (equal (file-symlink-p database)
                     (expand-file-name "compile_commands.json"
                                       (dotfiles-cmake-build-dir))))
      (should (string-match-p "src/main.cpp" (dotfiles-cpp-test--read database))))))

(ert-deftest dotfiles-cpp-settings-change-cancels-build-callback ()
  "Changing settings during a real build prevents running its old target."
  (dotfiles-cpp-test--require-toolchain)
  (dotfiles-cpp-test--with-project
    (let ((original-build (dotfiles-cmake-build-dir))
          invoked)
      (dotfiles-cmake-after-build "hello_app" (lambda () (setq invoked t)))
      ;; Compilation is asynchronous.  Change the originating context before
      ;; dispatching process events; no timing assumption or sleep is needed.
      (setq dotfiles-cmake-build-type "Release")
      (dotfiles-cpp-test--wait-processes)
      (should (file-executable-p
               (expand-file-name "runtime with spaces/hello_app" original-build)))
      (should-not invoked))))

(provide 'emacs_cpp_test)
;;; emacs_cpp_test.el ends here
