;;; init-prog.el --- C/C++, Python and Rust with eglot and tree-sitter -*- lexical-binding: t; -*-

;;; Commentary:

;; Language servers are not installed by this configuration:
;;   C/C++   clangd           (brew install llvm / apt install clangd)
;;   Python  basedpyright or pyright (pipx install basedpyright)
;;   Rust    rust-analyzer    (rustup component add rust-analyzer)
;; Eglot picks the first server it finds; basedpyright is tried before pyright.
;; Grammars are compiled on first use, which needs git and a C compiler.

;;; Code:

(setopt treesit-enabled-modes '(c-ts-mode c++-ts-mode c-or-c++-ts-mode
                                python-ts-mode rust-ts-mode cmake-ts-mode)
        treesit-auto-install-grammar 'ask
        treesit-font-lock-level 4
        c-ts-mode-indent-offset 4
        c-ts-mode-indent-style 'k&r)

(add-to-list 'auto-mode-alist '("\\.rs\\'" . rust-ts-mode))
(add-to-list 'auto-mode-alist '("\\(?:CMakeLists\\.txt\\|\\.cmake\\)\\'" . cmake-ts-mode))

(defvar dotfiles-language-servers
  '((c-ts-mode      "clangd")
    (c++-ts-mode    "clangd")
    (python-ts-mode "basedpyright-langserver" "pyright-langserver" "pylsp")
    (rust-ts-mode   "rust-analyzer"))
  "Executables eglot can use for each mode, in the order eglot tries them.")

(defun dotfiles-eglot-maybe ()
  "Start eglot if a language server for this mode is installed."
  (let ((servers (cdr (assq major-mode dotfiles-language-servers))))
    (if (seq-some #'executable-find servers)
        (eglot-ensure)
      (message "No language server for %s; install one of: %s"
               major-mode (string-join servers ", ")))))

(use-package eglot
  :ensure nil
  :hook ((c-ts-mode c++-ts-mode python-ts-mode rust-ts-mode) . dotfiles-eglot-maybe)
  :bind (:map eglot-mode-map
              ("C-c l r" . eglot-rename)
              ("C-c l a" . eglot-code-actions)
              ("C-c l f" . eglot-format)
              ("C-c l o" . eglot-code-action-organize-imports))
  :custom
  (eglot-autoshutdown t)
  (eglot-events-buffer-config '(:size 0)))

(setopt compilation-scroll-output 'first-error)
(keymap-global-set "C-c c" #'compile)
(keymap-global-set "C-c C" #'recompile)

(use-package quickrun
  :bind ("C-c r" . quickrun))

(provide 'init-prog)
;;; init-prog.el ends here
