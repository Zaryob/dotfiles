;;; init-cpp.el --- C++ IDE commands with clangd and Dape -*- lexical-binding: t; -*-

;;; Commentary:

;; C-c p is the project menu; C-c d is the debugger menu.
;; CMake targets come from init-cmake, rather than guessing binary names.
;; Project .clang-format and .clang-tidy files remain authoritative.

;;; Code:

(require 'cl-lib)
(require 'subr-x)
(require 'project)
(require 'eglot)
(require 'init-cmake)

(defvar dape-configs)
(declare-function dape--live-connection "dape" (type &optional nowarn require-selected))

(defgroup dotfiles-cpp nil
  "C/C++ development tools."
  :group 'tools)

(defcustom dotfiles-cpp-clangd-executable nil
  "Explicit clangd executable, or nil to discover it automatically."
  :type '(choice (const :tag "Automatic" nil) file))

(defcustom dotfiles-cpp-debug-adapter nil
  "Explicit LLDB DAP executable, or nil to discover LLDB or GDB."
  :type '(choice (const :tag "Automatic" nil) file))

(defcustom dotfiles-cpp-format-on-save nil
  "Whether to format C/C++ buffers with clangd before saving."
  :type 'boolean
  :safe #'booleanp)

(defun dotfiles-cpp-find-tool (name)
  "Find NAME in Homebrew LLVM, PATH or versioned Linux executables."
  (or (cl-loop for prefix in '("/opt/homebrew/opt/llvm/bin/"
                               "/usr/local/opt/llvm/bin/"
                               "/home/linuxbrew/.linuxbrew/opt/llvm/bin/")
               for path = (concat prefix name)
               when (and (file-regular-p path) (file-executable-p path))
               return path)
      (executable-find name)
      (cl-loop for path in (sort (file-expand-wildcards
                                 (concat "/usr/bin/" name "-[0-9]*"))
                                (lambda (a b) (string-version-lessp b a)))
               when (and (file-regular-p path) (file-executable-p path))
               return path)))

(defun dotfiles-cpp-clangd ()
  "Return the selected clangd executable, or nil if unavailable."
  (if dotfiles-cpp-clangd-executable
      (executable-find dotfiles-cpp-clangd-executable)
    (dotfiles-cpp-find-tool "clangd")))

(defun dotfiles-cpp-clangd-contact (&optional _interactive)
  "Return an Eglot contact for clangd in this project."
  (list (or (dotfiles-cpp-clangd)
            (user-error "Install clangd (Homebrew llvm or your distro's clangd)"))
        "--background-index" "--clang-tidy" "--completion-style=detailed"))

(add-to-list 'eglot-server-programs
             '((c-mode c++-mode c-ts-mode c++-ts-mode c-or-c++-ts-mode)
               . dotfiles-cpp-clangd-contact))

(defun dotfiles-cpp-format-before-save ()
  "Format this buffer when formatting on save is enabled and Eglot is ready."
  (when (and dotfiles-cpp-format-on-save (eglot-managed-p))
    (eglot-format-buffer)))

(defun dotfiles-cpp-setup ()
  "Enable C/C++ editing conveniences in the current buffer."
  (setq-local c-basic-offset 4)
  (add-hook 'before-save-hook #'dotfiles-cpp-format-before-save nil t))

(dolist (hook '(c-mode-hook c++-mode-hook c-ts-mode-hook c++-ts-mode-hook
               c-or-c++-ts-mode-hook))
  (add-hook hook #'dotfiles-cpp-setup))

(defun dotfiles-cpp-enable-snippets ()
  "Enable snippets, including classic C/C++ templates in tree-sitter modes."
  (require 'yasnippet)
  (yas-minor-mode 1)
  (when (derived-mode-p 'c-ts-mode 'c++-ts-mode)
    (yas-activate-extra-mode
     (if (derived-mode-p 'c++-ts-mode) 'c++-mode 'c-mode))))

(use-package yasnippet
  :commands (yas-minor-mode yas-activate-extra-mode)
  :hook ((c-mode c++-mode c-ts-mode c++-ts-mode c-or-c++-ts-mode)
         . dotfiles-cpp-enable-snippets))

(use-package yasnippet-snippets
  :after yasnippet)

;; Emacs 30 without a grammar still gets CMake syntax highlighting.
(use-package cmake-mode
  :commands cmake-mode
  :init
  (unless (or (and (boundp 'dotfiles-treesit-auto) dotfiles-treesit-auto)
              (and (treesit-available-p)
                   (treesit-language-available-p 'cmake)))
    (add-to-list 'auto-mode-alist
                 '("\\(?:CMakeLists\\.txt\\|\\.cmake\\)\\'" . cmake-mode))))

(defun dotfiles-cpp-switch-source-header ()
  "Visit the header or implementation associated with the current file."
  (interactive)
  (unless buffer-file-name
    (user-error "Visit a C/C++ source or header first"))
  (let ((server (eglot-current-server)))
    (unless server (user-error "clangd is not connected; run M-x eglot"))
    (let ((uri (jsonrpc-request server :textDocument/switchSourceHeader
                                (list :uri (eglot-path-to-uri buffer-file-name)))))
      (if (and (stringp uri) (not (string-empty-p uri)))
          (find-file (eglot-uri-to-path uri))
        (user-error "clangd could not find the corresponding source/header")))))

(defun dotfiles-cpp-lldb-adapter ()
  "Find LLDB's debug adapter, including Xcode's adapter outside PATH."
  (or (and dotfiles-cpp-debug-adapter
           (or (executable-find dotfiles-cpp-debug-adapter)
               (user-error "Cannot execute %s" dotfiles-cpp-debug-adapter)))
      (dotfiles-cpp-find-tool "lldb-dap")
      (when (and (eq system-type 'darwin) (executable-find "xcrun"))
        (with-temp-buffer
          (when (zerop (process-file "xcrun" nil (list t nil) nil
                                    "--find" "lldb-dap"))
            (let ((path (string-trim (buffer-string))))
              (when (file-executable-p path) path)))))
      (dotfiles-cpp-find-tool "lldb-vscode")))

(defun dotfiles-cpp-debug-config (program root args)
  "Return a Dape launch configuration for PROGRAM in ROOT with ARGS."
  (let* ((lldb (dotfiles-cpp-lldb-adapter))
         (config
          (if lldb
              `(command ,lldb :type "lldb-dap" ensure dape-ensure-command)
            (let ((gdb (dotfiles-cpp-find-tool "gdb")))
              (unless gdb
                (user-error "Install lldb-dap or GDB 14.1+ with DAP support"))
              ;; Dape's GDB configuration validates the required version.
              (require 'dape)
              (plist-put (copy-sequence (cdr (assq 'gdb dape-configs)))
                         'command gdb)))))
    (cl-loop for (key value) on
             `(command-cwd ,root :request "launch" :cwd ,root
               :program ,program :args ,(vconcat args)) by #'cddr
             do (setq config (plist-put config key value)))
    config))

(defvar dotfiles-cpp-argument-history nil)

(defun dotfiles-cpp-debug ()
  "Choose a CMake executable, build it and launch the debugger."
  (interactive)
  (require 'dape)
  ;; Resolve adapter before starting configuration/build work.
  (dotfiles-cpp-debug-config "" default-directory nil)
  (dotfiles-cmake-with-executable
   (lambda (target)
     (let* ((root (dotfiles-cmake-root))
            (args (split-string-shell-command
                   (read-string "Program arguments: " nil
                                'dotfiles-cpp-argument-history))))
       (dotfiles-cmake-after-build
        (car target)
        (lambda ()
          ;; --build can regenerate CMake and move the executable artifact.
          (let ((executable (dotfiles-cmake-executable (car target))))
            (dape (dotfiles-cpp-debug-config (cdr executable) root args)))))))))

(defun dotfiles-cpp-debug-or-continue ()
  "Continue an active Dape session, or build and debug a CMake target."
  (interactive)
  (if (and (featurep 'dape) (dape--live-connection 'last t))
      (call-interactively #'dape-continue)
    (dotfiles-cpp-debug)))

(use-package dape
  :commands (dape dape-continue dape-next dape-step-in dape-step-out
             dape-restart dape-quit dape-breakpoint-toggle dape-watch-dwim
             dape-info)
  :custom (dape-buffer-window-arrangement 'right)
  :init (repeat-mode 1)
  :bind (("<f5>" . dotfiles-cpp-debug-or-continue)
         ("S-<f5>" . dape-quit)
         ("<f9>" . dape-breakpoint-toggle)
         ("<f10>" . dape-next)
         ("<f11>" . dape-step-in)
         ("S-<f11>" . dape-step-out)
         ("C-c d d" . dape)
         ("C-c d b" . dape-breakpoint-toggle)
         ("C-c d c" . dape-continue)
         ("C-c d n" . dape-next)
         ("C-c d i" . dape-step-in)
         ("C-c d o" . dape-step-out)
         ("C-c d r" . dape-restart)
         ("C-c d q" . dape-quit)
         ("C-c d w" . dape-watch-dwim)
         ("C-c d v" . dape-info)))

(defun dotfiles-cpp-environment ()
  "Show C++ tool availability and the current CMake project settings."
  (interactive)
  (let ((root (ignore-errors (dotfiles-cmake-root)))
        (adapter (dotfiles-cpp-lldb-adapter)))
    (with-help-window "*C++ environment*"
      (princ "C++ development environment\n\n")
      (dolist (entry `(("clangd" . ,(dotfiles-cpp-clangd))
                       ("CMake" . ,(executable-find "cmake"))
                       ("CTest" . ,(executable-find "ctest"))
                       ("Ninja (optional)" . ,(executable-find "ninja"))
                       ("LLDB DAP" . ,adapter)
                       ("GDB (14.1+ for DAP)" . ,(dotfiles-cpp-find-tool "gdb"))))
        (princ (format "%-22s %s\n" (car entry) (or (cdr entry) "not installed"))))
      (when root
        (princ (format "\nCMake source: %s\nBuild: %s\n"
                       root (dotfiles-cmake-build-dir root))))
      (princ "\nC-c p: project/build/run/test.  C-c d: debugger.\n")
      (princ "C-c l: rename/actions/format/docs.  M-.: definition; M-?: references.\n"))))

(keymap-global-set "C-c p" project-prefix-map)
(keymap-set project-prefix-map "c" #'dotfiles-cmake-configure)
(keymap-set project-prefix-map "b" #'dotfiles-cmake-build)
(keymap-set project-prefix-map "t" #'dotfiles-cmake-test)
(keymap-set project-prefix-map "r" #'dotfiles-cmake-run)
(keymap-set project-prefix-map "d" #'dotfiles-cpp-debug)
(keymap-set project-prefix-map "s" #'dotfiles-cmake-settings)
(keymap-set project-prefix-map "h" #'dotfiles-cpp-switch-source-header)
(keymap-set project-prefix-map "e" #'dotfiles-cpp-environment)
(keymap-set project-prefix-map "g" #'consult-ripgrep)
(keymap-global-set "C-c l h" #'dotfiles-cpp-switch-source-header)

(provide 'init-cpp)
;;; init-cpp.el ends here
