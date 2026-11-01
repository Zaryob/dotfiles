;;; init-project.el --- Spacemacs-style project navigation -*- lexical-binding: t; -*-

;;; Commentary:

;; M-m is the leader key, without changing Emacs's editing keys.
;; Projectile manages projects; Treemacs shows their files and Git state.
;; C-c p keeps the existing project.el/CMake commands.

;;; Code:

(require 'cl-lib)
(require 'project)
(require 'seq)

(defun dotfiles-project-visit ()
  "Open the selected project in Dired with its Treemacs sidebar."
  (interactive)
  (let ((root (or (projectile-project-root)
                  (user-error "Choose a Git, CMake or .projectile project"))))
    (dired root)
    (require 'treemacs)
    (save-selected-window
      (treemacs-add-and-display-current-project))))

(defun dotfiles-project-tree ()
  "Toggle the sidebar, adding the current project when opening it."
  (interactive)
  (require 'treemacs)
  (if (eq (treemacs-current-visibility) 'visible)
      (treemacs)
    (unless (projectile-project-root)
      (user-error "Open a project with M-m p p or M-m p a first"))
    (treemacs-add-and-display-current-project)))

(defun dotfiles-project-search ()
  "Search from the current Projectile root with Consult and ripgrep."
  (interactive)
  (consult-ripgrep (or (projectile-project-root)
                       (user-error "Open a project first"))))

(defun dotfiles-projectile-find-project (directory)
  "Make Projectile projects in DIRECTORY available to project.el and Eglot."
  (when-let* ((root (projectile-project-root directory)))
    (cons 'dotfiles-projectile root)))

(cl-defmethod project-root ((project (head dotfiles-projectile)))
  (cdr project))

(use-package projectile
  :demand t
  :custom
  (projectile-completion-system 'default)
  (projectile-switch-project-action #'dotfiles-project-visit)
  (projectile-known-projects-file (locate-user-emacs-file "var/projectile-projects.eld"))
  (projectile-cache-file (locate-user-emacs-file "var/projectile.cache"))
  (projectile-project-search-path
   (mapcar (lambda (directory) (cons (expand-file-name directory) 1))
           (seq-filter #'file-directory-p '("~/Development/" "~/Projects/" "~/projects/"))))
  (projectile-auto-discover t)
  :config
  (make-directory (locate-user-emacs-file "var/") t)
  (projectile-mode 1)
  ;; Preserve VC and CMake backends; use Projectile for other project markers.
  (add-hook 'project-find-functions #'dotfiles-projectile-find-project t))

(use-package treemacs
  :commands (treemacs treemacs-add-and-display-current-project
             treemacs-current-visibility treemacs-select-window)
  :custom
  (treemacs-width 32)
  (treemacs-persist-file (locate-user-emacs-file "var/treemacs-persist"))
  (treemacs-is-never-other-window t)
  :config
  (treemacs-follow-mode 1)
  (treemacs-filewatch-mode 1)
  (treemacs-git-mode 'simple))

(use-package treemacs-projectile
  :after (treemacs projectile))

(use-package treemacs-magit
  :after (treemacs magit))

(defvar dotfiles-leader-map (make-sparse-keymap "Leader"))
(defvar dotfiles-project-map (make-sparse-keymap "Project"))
(defvar dotfiles-git-map (make-sparse-keymap "Git"))
(defvar dotfiles-build-map (make-sparse-keymap "Build and debug"))
(defvar dotfiles-file-map (make-sparse-keymap "Files"))
(defvar dotfiles-buffer-map (make-sparse-keymap "Buffers"))

(keymap-global-set "M-m" dotfiles-leader-map)
(dolist (group `(("p" "project" ,dotfiles-project-map)
                 ("g" "git" ,dotfiles-git-map)
                 ("c" "build/debug" ,dotfiles-build-map)
                 ("f" "files" ,dotfiles-file-map)
                 ("b" "buffers" ,dotfiles-buffer-map)))
  (keymap-set dotfiles-leader-map (car group) (cons (cadr group) (caddr group))))
(keymap-set dotfiles-leader-map "SPC" #'execute-extended-command)
(keymap-set dotfiles-leader-map "w" (cons "windows" window-prefix-map))

(keymap-set dotfiles-project-map "p" #'projectile-switch-project)
(keymap-set dotfiles-project-map "a" #'projectile-add-and-switch-project)
(keymap-set dotfiles-project-map "f" #'projectile-find-file)
(keymap-set dotfiles-project-map "b" #'projectile-switch-to-buffer)
(keymap-set dotfiles-project-map "r" #'projectile-recentf)
(keymap-set dotfiles-project-map "s" #'dotfiles-project-search)
(keymap-set dotfiles-project-map "t" #'dotfiles-project-tree)
(keymap-set dotfiles-project-map "d" #'projectile-dired)
(keymap-set dotfiles-project-map "D" #'projectile-discover-projects-in-search-path)
(keymap-set dotfiles-project-map "x" #'projectile-remove-known-project)
(keymap-set dotfiles-project-map "k" #'projectile-kill-buffers)

(keymap-set dotfiles-git-map "s" #'magit-status)
(keymap-set dotfiles-git-map "g" #'dotfiles-git-graph)
(keymap-set dotfiles-git-map "l" #'dotfiles-git-graph)
(keymap-set dotfiles-git-map "b" #'magit-show-refs-head)
(keymap-set dotfiles-git-map "f" #'magit-log-buffer-file)
(keymap-set dotfiles-git-map "d" #'magit-diff-unstaged)
(keymap-set dotfiles-git-map "B" #'magit-blame-addition)

(keymap-set dotfiles-build-map "c" #'dotfiles-cmake-configure)
(keymap-set dotfiles-build-map "b" #'dotfiles-cmake-build)
(keymap-set dotfiles-build-map "t" #'dotfiles-cmake-test)
(keymap-set dotfiles-build-map "r" #'dotfiles-cmake-run)
(keymap-set dotfiles-build-map "d" #'dotfiles-cpp-debug)
(keymap-set dotfiles-build-map "s" #'dotfiles-cmake-settings)
(keymap-set dotfiles-build-map "C" #'compile)

(keymap-set dotfiles-file-map "f" #'find-file)
(keymap-set dotfiles-file-map "s" #'save-buffer)
(keymap-set dotfiles-file-map "r" #'consult-recent-file)
(keymap-set dotfiles-buffer-map "b" #'consult-buffer)
(keymap-set dotfiles-buffer-map "d" #'kill-current-buffer)
(keymap-set dotfiles-buffer-map "n" #'next-buffer)
(keymap-set dotfiles-buffer-map "p" #'previous-buffer)

(provide 'init-project)
;;; init-project.el ends here
