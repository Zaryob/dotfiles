;;; init-cmake.el --- CMake projects, builds and executable targets -*- lexical-binding: t; -*-

;;; Commentary:

;; CMake's File API supplies target names and actual artifact paths, including
;; custom output directories and multi-configuration generators.  The commands
;; use compilation buffers; a failed build never starts a run or debug session.

;;; Code:

(require 'cl-lib)
(require 'compile)
(require 'json)
(require 'project)
(require 'seq)
(require 'subr-x)

(defgroup dotfiles-cmake nil "CMake project workflow." :group 'tools)

(defcustom dotfiles-cmake-build-directory "build"
  "Build directory, absolute or relative to the CMake project root."
  :type 'directory :group 'dotfiles-cmake :safe #'stringp)

(defcustom dotfiles-cmake-build-type "Debug"
  "Build configuration used by CMake and CTest."
  :type 'string :group 'dotfiles-cmake :safe #'stringp)

(defcustom dotfiles-cmake-configure-arguments nil
  "Additional CMake configure arguments, each as a separate string.
For example: (\"-G\" \"Ninja Multi-Config\" \"-DBUILD_TESTING=ON\")."
  :type '(repeat string) :group 'dotfiles-cmake
  :safe (lambda (value) (and (listp value) (seq-every-p #'stringp value))))

(defvar dotfiles-cmake--settings (make-hash-table :test #'equal)
  "Build directory and configuration selected for each project this session.")
(defvar dotfiles-cmake--configured (make-hash-table :test #'equal)
  "Last successfully configured settings for each build directory.")
(defvar dotfiles-cmake--database-links (make-hash-table :test #'equal)
  "Compilation database symlinks created by this configuration.")
(defvar dotfiles-cmake--database-links-loaded nil)
(defvar dotfiles-cmake--target-history nil)
(defvar dotfiles-cmake--argument-history nil)

(defun dotfiles-cmake--find-project (directory)
  "Recognize a non-VC CMake project containing DIRECTORY."
  (when-let* ((root (locate-dominating-file directory "CMakeLists.txt")))
    (cons 'dotfiles-cmake (expand-file-name root))))

(cl-defmethod project-root ((project (head dotfiles-cmake)))
  (cdr project))

;; Keep VC backends first, so a repository's top-level CMake project wins over
;; a nested add_subdirectory() project when one is available.
(add-hook 'project-find-functions #'dotfiles-cmake--find-project t)

(defun dotfiles-cmake-root ()
  "Return this buffer's CMake root, or nil outside a CMake project.
Prefer a project.el root with CMakeLists.txt; otherwise use the nearest one."
  (let* ((project (project-current nil))
         (root (and project (project-root project))))
    (cond ((and root (file-exists-p (expand-file-name "CMakeLists.txt" root)))
           (file-name-as-directory (expand-file-name root)))
          ((locate-dominating-file default-directory "CMakeLists.txt")))))

(defun dotfiles-cmake--context ()
  "Return (ROOT BUILD TYPE ARGS) for the current project."
  (unless (executable-find "cmake")
    (user-error "CMake is missing; install cmake and ninja"))
  (let* ((root (or (dotfiles-cmake-root)
                   (user-error "No CMakeLists.txt found for this buffer")))
         (settings (gethash root dotfiles-cmake--settings))
         (directory (or (car settings) dotfiles-cmake-build-directory))
         (type (or (cadr settings) dotfiles-cmake-build-type)))
    (list root (file-name-as-directory (expand-file-name directory root))
          type dotfiles-cmake-configure-arguments)))

(defun dotfiles-cmake-build-dir (&optional root)
  "Return the absolute build directory for ROOT or the current CMake project."
  (let* ((root (or root (dotfiles-cmake-root)
                   (user-error "No CMakeLists.txt found for this buffer")))
         (settings (gethash root dotfiles-cmake--settings)))
    (file-name-as-directory
     (expand-file-name (or (car settings) dotfiles-cmake-build-directory) root))))

(defun dotfiles-cmake--shell-command (arguments)
  "Quote and join the strings in ARGUMENTS for a shell."
  (mapconcat #'shell-quote-argument arguments " "))

(defun dotfiles-cmake--query (build)
  "Request the codemodel File API object in BUILD."
  (let ((query (expand-file-name
                ".cmake/api/v1/query/client-emacs-dotfiles/codemodel-v2" build)))
    (make-directory (file-name-directory query) t)
    (unless (file-exists-p query)
      (write-region "" nil query nil 'silent))))

(defun dotfiles-cmake--configure-command (context)
  "Return the configure command for CONTEXT, preparing its File API query."
  (pcase-let ((`(,root ,build ,type ,arguments) context))
    (dotfiles-cmake--query build)
    (dotfiles-cmake--shell-command
     (append (list "cmake" "-S" root "-B" build
                   (concat "-DCMAKE_BUILD_TYPE=" type)
                   "-DCMAKE_EXPORT_COMPILE_COMMANDS=ON")
             ;; Retain existing generators and explicit user choices.
             (when (and (not (file-exists-p (expand-file-name "CMakeCache.txt" build)))
                        (not (getenv "CMAKE_GENERATOR"))
                        (not (seq-some (lambda (arg)
                                        (or (string-prefix-p "-G" arg)
                                            (string-prefix-p "--preset" arg)))
                                       arguments))
                        (executable-find "ninja"))
               '("-G" "Ninja"))
             arguments))))

(defun dotfiles-cmake--index-file (build)
  "Return the newest successful File API index in BUILD, or nil."
  (car (last (sort (file-expand-wildcards
                    (expand-file-name ".cmake/api/v1/reply/index-*.json" build) t)
                   #'string-lessp))))

(defun dotfiles-cmake--needs-configure-p (context)
  "Whether CONTEXT needs an initial or settings-driven configure."
  (let ((build (nth 1 context)))
    (or (not (file-exists-p (expand-file-name "CMakeCache.txt" build)))
        (not (dotfiles-cmake--index-file build))
        (not (equal context (gethash build dotfiles-cmake--configured))))))

(defun dotfiles-cmake-build-command (&optional target)
  "Return a quoted configure-if-needed and build command for TARGET.
TARGET nil builds the default targets.  Suitable for Dape's compile setting."
  (let* ((context (dotfiles-cmake--context))
         (build (nth 1 context))
         (command (dotfiles-cmake--shell-command
                   (append (list "cmake" "--build" build "--config" (nth 2 context)
                                 "--parallel")
                           (and target (list "--target" target))))))
    (if (dotfiles-cmake--needs-configure-p context)
        (concat (dotfiles-cmake--configure-command context) " && " command)
      command)))

(defun dotfiles-cmake--link-database (context)
  "Expose CONTEXT's compile database without replacing a user's file or link."
  (dotfiles-cmake--load-database-links)
  (pcase-let* ((`(,root ,build . ,_) context)
               (source (expand-file-name "compile_commands.json" build))
               (destination (expand-file-name "compile_commands.json" root))
               (existing (file-symlink-p destination))
               (managed (gethash destination dotfiles-cmake--database-links)))
    (when (and (file-exists-p source) (not (equal source destination))
               (or (and (not existing) (not (file-exists-p destination)))
                   (and existing managed
                        (equal (expand-file-name existing root) managed))))
      (make-symbolic-link source destination (and existing t))
      (puthash destination source dotfiles-cmake--database-links)
      (dotfiles-cmake--save-database-links))))

(defun dotfiles-cmake--load-database-links ()
  "Load symlink ownership records as JSON data, never executable Lisp."
  (unless dotfiles-cmake--database-links-loaded
    (setq dotfiles-cmake--database-links-loaded t)
    (let ((file (locate-user-emacs-file "var/cmake-database-links.json")))
      (when (file-readable-p file)
        (condition-case nil
            (dolist (entry (dotfiles-cmake--read-json file))
              (when (and (listp entry) (= (length entry) 2)
                         (seq-every-p (lambda (path)
                                        (and (stringp path) (file-name-absolute-p path)))
                                      entry))
                (puthash (car entry) (cadr entry) dotfiles-cmake--database-links)))
          (error (message "Ignoring invalid CMake database ownership records")))))))

(defun dotfiles-cmake--save-database-links ()
  "Persist ownership so switching build directories after restart is safe."
  (let* ((file (locate-user-emacs-file "var/cmake-database-links.json"))
         (directory (file-name-directory file))
         entries temporary)
    (maphash (lambda (destination source)
               (push (vector destination source) entries))
             dotfiles-cmake--database-links)
    (make-directory directory t)
    (setq temporary (make-temp-file (expand-file-name ".cmake-links-" directory)))
    (unwind-protect
        (progn
          (with-temp-file temporary
            (insert (json-serialize (vconcat entries))))
          (rename-file temporary file t))
      (when (file-exists-p temporary) (delete-file temporary)))))

(defun dotfiles-cmake--start (command context &optional callback)
  "Run COMMAND asynchronously for CONTEXT; call CALLBACK only after success."
  (let* ((origin (current-buffer))
         (default-directory (car context))
         (name (format "*cmake: %s*"
                       (file-name-nondirectory (directory-file-name default-directory))))
         (buffer (compilation-start command nil (lambda (_) name)))
         (process (get-buffer-process buffer))
         finish)
    ;; Compilation detaches its process before calling finish hooks.  Capture
    ;; this invocation's process and remove the hook before any follow-up runs.
    (setq finish
          (lambda (finished-buffer _message)
            (with-current-buffer finished-buffer
              (remove-hook 'compilation-finish-functions finish t))
            (when (and process (eq (process-status process) 'exit)
                       (zerop (process-exit-status process)))
              (puthash (nth 1 context) context dotfiles-cmake--configured)
              (dotfiles-cmake--link-database context)
              (when (and callback (buffer-live-p origin))
                (with-current-buffer origin
                  (if (equal context (ignore-errors (dotfiles-cmake--context)))
                      (funcall callback)
                    (message "CMake settings changed during the build; run the command again")))))))
    (with-current-buffer buffer
      (add-hook 'compilation-finish-functions finish nil t))
    buffer))

(defun dotfiles-cmake-configure ()
  "Configure this CMake project and refresh executable targets."
  (interactive)
  (save-some-buffers)
  (let ((context (dotfiles-cmake--context)))
    (dotfiles-cmake--start (dotfiles-cmake--configure-command context) context)))

(defun dotfiles-cmake-build (&optional target)
  "Build this project, or a prompted TARGET with a prefix argument."
  (interactive (list (and current-prefix-arg (read-string "CMake target: "))))
  (save-some-buffers)
  (dotfiles-cmake--start (dotfiles-cmake-build-command target)
                        (dotfiles-cmake--context)))

(defun dotfiles-cmake-after-build (target callback)
  "Build TARGET and call CALLBACK, with no arguments, only after success.
The callback runs in the original buffer.  Used by run and debug commands."
  (save-some-buffers)
  (dotfiles-cmake--start (dotfiles-cmake-build-command target)
                        (dotfiles-cmake--context) callback))

(defun dotfiles-cmake--read-json (file)
  "Read CMake's JSON reply FILE as an alist."
  (with-temp-buffer
    (insert-file-contents file)
    (json-parse-buffer :object-type 'alist :array-type 'list
                       :null-object nil :false-object nil)))

(defun dotfiles-cmake--executables (context)
  "Read executable (NAME . PATH) pairs from CONTEXT's File API replies."
  (let* ((build (nth 1 context))
         (index-file (or (dotfiles-cmake--index-file build)
                         (user-error "Run dotfiles-cmake-configure first")))
         (reply-directory (file-name-directory index-file))
         (index (dotfiles-cmake--read-json index-file))
         (reference (seq-find (lambda (object)
                                (equal (alist-get 'kind object) "codemodel"))
                              (alist-get 'objects index))))
    (unless reference (user-error "No CMake codemodel; run dotfiles-cmake-configure"))
    (let* ((model (dotfiles-cmake--read-json
                   (expand-file-name (alist-get 'jsonFile reference) reply-directory)))
           (configurations (alist-get 'configurations model))
           (configuration (or (seq-find
                               (lambda (config)
                                 (equal (alist-get 'name config) (nth 2 context)))
                               configurations)
                              (and (= (length configurations) 1)
                                   (car configurations))))
           executables)
      (unless configuration
        (user-error "Configuration %s is unavailable; use dotfiles-cmake-settings"
                    (nth 2 context)))
      (dolist (target (alist-get 'targets configuration))
        (let* ((object (dotfiles-cmake--read-json
                        (expand-file-name (alist-get 'jsonFile target) reply-directory)))
               (artifacts (alist-get 'artifacts object))
               (name-on-disk (alist-get 'nameOnDisk object))
               (artifact (or (and name-on-disk
                                  (seq-find
                                   (lambda (entry)
                                     (equal (file-name-nondirectory (alist-get 'path entry))
                                            (file-name-nondirectory name-on-disk)))
                                   artifacts))
                             (car artifacts))))
          (when (and (equal (alist-get 'type object) "EXECUTABLE") artifact)
            (push (cons (alist-get 'name object)
                        (expand-file-name (alist-get 'path artifact) build))
                  executables))))
      (sort executables (lambda (a b) (string-lessp (car a) (car b)))))))

(defun dotfiles-cmake-select-executable ()
  "Choose a configured executable and return (TARGET-NAME . ABSOLUTE-PATH)."
  (let ((targets (dotfiles-cmake--executables (dotfiles-cmake--context))))
    (unless targets (user-error "This CMake configuration has no executable targets"))
    (if (= (length targets) 1)
        (car targets)
      (assoc (completing-read "Executable target: " targets nil t nil
                              'dotfiles-cmake--target-history)
             targets))))

(defun dotfiles-cmake-executable (name)
  "Resolve NAME against the latest codemodel to return (NAME . ABSOLUTE-PATH).
Use this after a build: CMake may regenerate and move an executable artifact."
  (or (assoc name (dotfiles-cmake--executables (dotfiles-cmake--context)))
      (user-error "Executable target %s no longer exists; configure and select again" name)))

(defun dotfiles-cmake-with-executable (callback)
  "Configure if needed, then call CALLBACK with the selected executable pair."
  (let ((context (dotfiles-cmake--context)))
    (if (dotfiles-cmake--needs-configure-p context)
        (progn
          (save-some-buffers)
          (dotfiles-cmake--start
           (dotfiles-cmake--configure-command context) context
           (lambda () (funcall callback (dotfiles-cmake-select-executable)))))
      (funcall callback (dotfiles-cmake-select-executable)))))

(defun dotfiles-cmake-run ()
  "Choose, build and run an executable in an interactive compilation buffer."
  (interactive)
  (dotfiles-cmake-with-executable
   (lambda (target)
     (let* ((arguments (split-string-shell-command
                        (read-string "Program arguments: " nil
                                     'dotfiles-cmake--argument-history)))
            (root (car (dotfiles-cmake--context))))
       (dotfiles-cmake-after-build
        (car target)
        (lambda ()
          (let* ((executable (dotfiles-cmake-executable (car target)))
                 (command (dotfiles-cmake--shell-command (cons (cdr executable) arguments)))
                 (default-directory root))
            (compilation-start command t (lambda (_) "*cmake-run*")))))))))

(defun dotfiles-cmake-test ()
  "Build this project, then run CTest with failure output."
  (interactive)
  (unless (executable-find "ctest") (user-error "CTest is missing; install cmake"))
  (let* ((context (dotfiles-cmake--context))
         (command (dotfiles-cmake--shell-command
                   (list "ctest" "--test-dir" (nth 1 context) "-C" (nth 2 context)
                         "--output-on-failure"))))
    (dotfiles-cmake-after-build
     nil (lambda () (dotfiles-cmake--start command context)))))

(defun dotfiles-cmake-settings ()
  "Choose this project's build directory and configuration for this session.
For persistent choices, set the corresponding variables in .dir-locals.el."
  (interactive)
  (pcase-let* ((`(,root ,build ,type . ,_) (dotfiles-cmake--context))
               (directory (read-directory-name "Build directory: " root build nil))
               (configuration (completing-read "Configuration: "
                                               '("Debug" "Release" "RelWithDebInfo" "MinSizeRel")
                                               nil nil nil nil type)))
    (puthash root (list directory configuration) dotfiles-cmake--settings)
    (message "CMake: %s in %s; configure or build to apply" configuration directory)))

(provide 'init-cmake)
;;; init-cmake.el ends here
