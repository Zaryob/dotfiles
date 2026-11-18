;;; init-project.el --- Project navigation -*- lexical-binding: t; -*-

;;; Commentary:

;; Projectile manages projects; Treemacs shows their files and Git state.
;; The keys are under M-m p (init-keys.el); C-x p stays Emacs's own menu.

;;; Code:

(require 'cl-lib)
(require 'project)
(require 'seq)
(require 'subr-x)

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
  (treemacs-is-never-other-window nil)
  :config
  ;; Default's PNG icons have mostly empty terminal fallbacks.  Keep its
  ;; graphical icons and supply Unicode icons that need no Nerd Font in a TTY.
  (treemacs-create-theme "Dotfiles"
    :extends "Default"
    :icon-directory (treemacs-join-path treemacs-dir "icons/default")
    :config
    (let ((icons (treemacs-theme->tui-icons (treemacs-current-theme))))
      (maphash
       (lambda (extension icon)
         (let ((name (format "%s" extension)))
           (cond
            ((and (or (stringp extension) (memq extension '(root-closed dir-closed)))
                  (string-suffix-p "-closed" name))
             (puthash extension "📁 " icons))
            ((and (or (stringp extension) (memq extension '(root-open dir-open)))
                  (string-suffix-p "-open" name))
             (puthash extension "📂 " icons))
            ((and (string-match-p "\\`[[:space:]]*\\'" icon)
                  (or (stringp extension) (eq extension 'fallback)
                      (string-suffix-p "-mode" name)))
             (puthash extension "📄 " icons)))))
       icons)))
  (treemacs-load-theme "Dotfiles")
  (treemacs-follow-mode 1)
  (treemacs-filewatch-mode 1)
  (treemacs-git-mode 'simple))

(use-package treemacs-projectile
  :after (treemacs projectile))

(use-package treemacs-magit
  :after (treemacs magit))

(provide 'init-project)
;;; init-project.el ends here
