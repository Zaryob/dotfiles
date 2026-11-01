;;; init-prog.el --- C/C++, Python and Rust with eglot and tree-sitter -*- lexical-binding: t; -*-

;;; Commentary:

;; Language servers are not installed by this configuration:
;;   C/C++   clangd           (brew install llvm / apt install clangd)
;;   Python  basedpyright or pyright (pipx install basedpyright)
;;   Rust    rust-analyzer    (rustup component add rust-analyzer)
;; Eglot picks the first server it finds; basedpyright is tried before pyright.
;; Grammars are compiled on first use, which needs git and a C compiler.

;;; Code:

(require 'seq)
(require 'subr-x)
(require 'treesit)

(defconst dotfiles-treesit-auto
  (and (treesit-available-p) (>= emacs-major-version 31))
  "Non-nil when Emacs remaps modes and installs grammars by itself.")

(defun dotfiles-treesit-ready-p (language)
  "Whether tree-sitter and the grammar for LANGUAGE are available."
  (and (treesit-available-p) (treesit-language-available-p language)))

(setopt treesit-enabled-modes '(c-ts-mode c++-ts-mode c-or-c++-ts-mode
                                python-ts-mode rust-ts-mode cmake-ts-mode)
        treesit-auto-install-grammar 'ask
        treesit-font-lock-level 4
        c-ts-mode-indent-offset 4
        c-ts-mode-indent-style 'k&r)

;; Emacs 30 (e.g. Debian stable) has neither option above: give it grammar
;; sources (ABI 14 tags) and use a tree-sitter mode only once its grammar is
;; installed.  Install grammars there with M-x dotfiles-install-grammars.
(unless dotfiles-treesit-auto
  (setq treesit-language-source-alist
        '((c      "https://github.com/tree-sitter/tree-sitter-c" "v0.23.4")
          (cpp    "https://github.com/tree-sitter/tree-sitter-cpp" "v0.23.4")
          (python "https://github.com/tree-sitter/tree-sitter-python" "v0.23.6")
          (rust   "https://github.com/tree-sitter/tree-sitter-rust" "v0.23.2")
          (cmake  "https://github.com/uyha/tree-sitter-cmake" "v0.4.1")))
  (pcase-dolist (`(,mode ,ts-mode ,lang)
                 '((c-mode        c-ts-mode        c)
                   (c++-mode      c++-ts-mode      cpp)
                   (c-or-c++-mode c-or-c++-ts-mode cpp)
                   (python-mode   python-ts-mode   python)))
    (when (dotfiles-treesit-ready-p lang)
      (add-to-list 'major-mode-remap-alist (cons mode ts-mode))))

  (defun dotfiles-install-grammars ()
    "Install the tree-sitter grammars this configuration uses."
    (interactive)
    (unless (treesit-available-p)
      (user-error "This Emacs was built without tree-sitter support"))
    (dolist (lang (mapcar #'car treesit-language-source-alist))
      (unless (treesit-language-available-p lang)
        (treesit-install-language-grammar lang)))
    (message "Grammars installed; restart Emacs to use the tree-sitter modes.")))

(when (or dotfiles-treesit-auto (dotfiles-treesit-ready-p 'rust))
  (add-to-list 'auto-mode-alist '("\\.rs\\'" . rust-ts-mode)))
(when (or dotfiles-treesit-auto (dotfiles-treesit-ready-p 'cmake))
  (add-to-list 'auto-mode-alist '("\\(?:CMakeLists\\.txt\\|\\.cmake\\)\\'" . cmake-ts-mode)))

(defconst dotfiles-python-server-programs
  '(("basedpyright-langserver" "--stdio")
    ("pyright-langserver" "--stdio")
    ("pylsp"))
  "Python language servers, in preference order, with their arguments.")

(defun dotfiles-python-eglot-contact (&optional _interactive)
  "Use the first installed Python server, with its required arguments."
  (or (seq-some (lambda (command)
                  (when-let* ((executable (executable-find (car command))))
                    (cons executable (cdr command))))
                dotfiles-python-server-programs)
      (user-error "Install basedpyright, pyright or python-lsp-server")))

(with-eval-after-load 'eglot
  (add-to-list 'eglot-server-programs
               '((python-mode python-ts-mode) . dotfiles-python-eglot-contact)))

(defvar dotfiles-language-servers
  (let ((c '("clangd"))
        (python (mapcar #'car dotfiles-python-server-programs)))
    `((c-ts-mode . ,c) (c++-ts-mode . ,c) (c-mode . ,c) (c++-mode . ,c)
      (python-ts-mode . ,python) (python-mode . ,python)
      (rust-ts-mode "rust-analyzer")))
  "Executables eglot can use for each mode, in the order eglot tries them.")

(defun dotfiles-eglot-maybe ()
  "Start eglot if a language server for this mode is installed."
  (let ((servers (if (and (fboundp 'dotfiles-cpp-clangd)
                          (derived-mode-p 'c-mode 'c++-mode 'c-ts-mode
                                          'c++-ts-mode 'c-or-c++-ts-mode))
                     (list (or (dotfiles-cpp-clangd) "clangd"))
                   (cdr (assq major-mode dotfiles-language-servers)))))
    (if (seq-some #'executable-find servers)
        (eglot-ensure)
      (message "No language server for %s; install one of: %s"
               major-mode (string-join servers ", ")))))

(use-package eglot
  :ensure nil
  :hook ((c-ts-mode c++-ts-mode c-or-c++-ts-mode python-ts-mode rust-ts-mode
          c-mode c++-mode python-mode) . dotfiles-eglot-maybe)
  :bind (:map eglot-mode-map
              ("C-c l r" . eglot-rename)
              ("C-c l a" . eglot-code-actions)
              ("C-c l f" . eglot-format)
              ("C-c l d" . eldoc-doc-buffer)
              ("C-c l i" . eglot-inlay-hints-mode)
              ("C-c l o" . eglot-code-action-organize-imports))
  :custom
  (eglot-autoshutdown t)
  (eglot-events-buffer-config '(:size 0)))

;; Errors and warnings appear at the end of their line, as in an IDE.
(setopt flymake-show-diagnostics-at-end-of-line 'short)

(setopt compilation-scroll-output 'first-error)
(keymap-global-set "C-c c" #'compile)
(keymap-global-set "C-c C" #'recompile)

(use-package quickrun
  :bind ("C-c r" . quickrun))

(provide 'init-prog)
;;; init-prog.el ends here
