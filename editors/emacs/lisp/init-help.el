;;; init-help.el --- Command palette, welcome screen and cheatsheet -*- lexical-binding: t; -*-

;;; Commentary:

;; For learning Emacs without memorizing it:
;;   C-S-p / M-m SPC   VSCode-style command palette: every feature by name,
;;                     with its shortcut shown, so the keys come with use
;;   C-c ?             cheatsheet, built from the same list (always current)
;;   right click       Run, Debug, Breakpoint, Rename... at the clicked spot
;; The welcome screen opens when Emacs starts without a file.  Copy, cut,
;; paste and undo use C-c, C-x, C-v and C-z while text is selected (CUA);
;; put (cua-mode -1) in local.el to keep the classic Emacs keys.

;;; Code:

(require 'cl-lib)
(require 'seq)
(require 'subr-x)

(defvar projectile-known-projects)
(defvar recentf-list)

(defconst dotfiles-palette-commands
  '(("Build" "Build project" dotfiles-build)
    ("Build" "Build a target or choose a command" dotfiles-build-choose)
    ("Build" "Run program" dotfiles-run)
    ("Build" "Run tests" dotfiles-test)
    ("Build" "Configure / create virtualenv" dotfiles-configure)
    ("Build" "Clean" dotfiles-clean)
    ("Build" "Stop build, program or debugger" dotfiles-stop)
    ("Build" "Repeat last build" recompile)
    ("Build" "Custom build command" compile)
    ("Build" "Jump to next error" next-error)
    ("Build" "CMake build directory and type" dotfiles-cmake-settings)
    ("Build" "Check installed tools" dotfiles-doctor)
    ("Debug" "Start debugging / continue" dotfiles-debug-or-continue)
    ("Debug" "Toggle breakpoint" dape-breakpoint-toggle)
    ("Debug" "Conditional breakpoint" dape-breakpoint-expression "dape")
    ("Debug" "Log point (print without stopping)" dape-breakpoint-log "dape")
    ("Debug" "Remove all breakpoints" dape-breakpoint-remove-all "dape")
    ("Debug" "Step over" dape-next)
    ("Debug" "Step into" dape-step-in)
    ("Debug" "Step out" dape-step-out)
    ("Debug" "Run to cursor" dape-until "dape")
    ("Debug" "Pause" dape-pause "dape")
    ("Debug" "Restart" dape-restart)
    ("Debug" "Stop debugging" dape-quit)
    ("Debug" "Watch expression" dape-watch-dwim)
    ("Debug" "Evaluate expression" dape-evaluate-expression "dape")
    ("Debug" "Show variables, stack and threads" dape-info)
    ("Debug" "Debugger console (REPL)" dape-repl "dape")
    ("Code" "Go to definition" xref-find-definitions)
    ("Code" "Go back" xref-go-back)
    ("Code" "Find usages" xref-find-references)
    ("Code" "Rename symbol" eglot-rename)
    ("Code" "Quick fix / code actions" eglot-code-actions)
    ("Code" "Format file" eglot-format-buffer)
    ("Code" "Show documentation" eldoc-doc-buffer)
    ("Code" "Switch header / source" dotfiles-cpp-switch-source-header)
    ("Code" "Go to symbol in file" consult-imenu)
    ("Code" "Problems in file" consult-flymake)
    ("Code" "Next problem" flymake-goto-next-error)
    ("Code" "Comment / uncomment" comment-line)
    ("Code" "Insert snippet" yas-insert-snippet "yasnippet")
    ("Code" "Show inlay hints" eglot-inlay-hints-mode)
    ("Code" "Restart language server" eglot-reconnect)
    ("Search" "Find in file" consult-line)
    ("Search" "Find in project" dotfiles-project-search)
    ("Search" "Replace in file" query-replace)
    ("Search" "Go to line" consult-goto-line)
    ("File" "Open file" find-file)
    ("File" "Open file in project" projectile-find-file)
    ("File" "Recent files" consult-recent-file)
    ("File" "Save" save-buffer)
    ("File" "Save all" dotfiles-save-all)
    ("File" "Switch buffer / open files" consult-buffer)
    ("File" "Close file" kill-current-buffer)
    ("Project" "Open project" projectile-switch-project)
    ("Project" "Add a project folder" projectile-add-and-switch-project)
    ("Project" "Toggle project tree" dotfiles-project-tree)
    ("Project" "Terminal in project" project-eshell)
    ("Git" "Status, stage and commit" magit-status)
    ("Git" "History graph" dotfiles-git-graph)
    ("Git" "Blame" magit-blame-addition)
    ("Git" "File history" magit-log-buffer-file)
    ("Git" "Next change" diff-hl-next-hunk "diff-hl")
    ("Git" "Revert change" diff-hl-revert-hunk "diff-hl")
    ("Edit" "Undo" undo)
    ("Edit" "Redo" undo-redo)
    ("Edit" "Select next occurrence (multi cursor)" mc/mark-next-like-this)
    ("Edit" "Select all occurrences (multi cursor)" mc/mark-all-like-this)
    ("Edit" "Duplicate line" duplicate-dwim)
    ("Edit" "Move line up" dotfiles-move-line-up)
    ("Edit" "Move line down" dotfiles-move-line-down)
    ("Edit" "Delete line" kill-whole-line)
    ("Window" "Split right" split-window-right)
    ("Window" "Split below" split-window-below)
    ("Window" "Next window" other-window)
    ("Window" "Close window" delete-window)
    ("Window" "Close other windows" delete-other-windows)
    ("Window" "Full screen" toggle-frame-fullscreen)
    ("Window" "Zoom text" global-text-scale-adjust)
    ("Window" "Change theme" consult-theme)
    ("Help" "Welcome screen" dotfiles-welcome)
    ("Help" "Cheatsheet" dotfiles-cheatsheet)
    ("Help" "What does this key do?" describe-key)
    ("Help" "Describe command" describe-command)
    ("Help" "Emacs tutorial" help-with-tutorial)
    ("Help" "Settings" customize)
    ("Help" "Edit this configuration" dotfiles-open-config)
    ("Help" "All Emacs commands (M-x)" execute-extended-command))
  "Command palette entries as (CATEGORY LABEL COMMAND [LIBRARY]).
LIBRARY is loaded on first use of a command its package does not autoload.
The cheatsheet is built from the same list.")

(pcase-dolist (`(,_ ,_ ,command ,library) dotfiles-palette-commands)
  (when (and library (not (fboundp command)) (locate-library library))
    (autoload command library nil t)))

(defvar dotfiles-palette-history nil)

(defun dotfiles-build-choose ()
  "Build a chosen target or command."
  (interactive)
  (dotfiles-build t))

(defun dotfiles-save-all ()
  "Save every modified file without asking."
  (interactive)
  (save-some-buffers t))

(defun dotfiles-open-config ()
  "Open this Emacs configuration's modules."
  (interactive)
  (find-file (expand-file-name "lisp/" user-emacs-directory)))

(defun dotfiles-palette--key (command)
  "Return the shortest key bound to COMMAND in this buffer, as text."
  (when-let* ((keys (where-is-internal command nil nil t))
              (key (car (sort (mapcar #'key-description keys)
                              (lambda (a b) (< (length a) (length b)))))))
    ;; Menu and mouse bindings are no help when typing.
    (unless (string-match-p "menu\\|mouse\\|<remap>" key) key)))

(defun dotfiles-palette--entries ()
  "Return available palette entries as (TEXT COMMAND KEY CATEGORY)."
  (seq-keep (pcase-lambda (`(,category ,label ,command . ,_))
              (when (fboundp command)
                (list (concat category ": " label) command
                      (dotfiles-palette--key command) category)))
            dotfiles-palette-commands))

(defun dotfiles-command-palette ()
  "Find and run a command by name, as in VSCode's Ctrl+Shift+P.
The shortcut of each command is shown next to it.  Any Emacs command
name typed directly also runs."
  (interactive)
  ;; Keys are read here: the minibuffer has its own key bindings.
  (let* ((entries (dotfiles-palette--entries))
         (width (apply #'max 0 (mapcar (lambda (entry) (length (car entry))) entries)))
         (annotate (lambda (text)
                     (when-let* ((key (nth 2 (assoc text entries))))
                       (concat (propertize " " 'display
                                           `(space :align-to ,(+ width 4)))
                               (propertize key 'face 'help-key-binding)))))
         (group (lambda (text transform)
                  (if transform
                      (substring text (1+ (string-search ":" text)))
                    (nth 3 (assoc text entries)))))
         (table (lambda (string predicate action)
                  (if (eq action 'metadata)
                      `(metadata (category . dotfiles-palette)
                                 (annotation-function . ,annotate)
                                 (group-function . ,group))
                    (complete-with-action action entries string predicate))))
         (choice (completing-read "Command: " table nil nil nil
                                  'dotfiles-palette-history))
         (command (or (nth 1 (assoc choice entries))
                      (and (commandp (intern-soft choice)) (intern-soft choice))
                      (user-error "No command named %s" choice))))
    (setq this-command command)
    (command-execute command 'record)))

(defconst dotfiles-cheatsheet-basics
  '(("C-g" "Cancel whatever is happening (press it when stuck)")
    ("C-S-p" "Command palette: search every feature by name")
    ("C-x C-f" "Open a file")
    ("C-x C-s" "Save")
    ("C-z / C-S-z" "Undo / redo")
    ("C-c C-x C-v" "Copy, cut, paste while text is selected")
    ("C-x b" "Switch between open files")
    ("C-x k" "Close the file")
    ("C-x 2, 3, 0, 1" "Split below, split right, close window, close others")
    ("C-x o" "Move to the next window")
    ("C-s" "Search in the file (C-s again for the next match)")
    ("M-x" "Run any command by its name")
    ("C-x C-c" "Quit Emacs"))
  "Keys to learn first, as (KEY DESCRIPTION).")

(defun dotfiles-cheatsheet ()
  "Show the important keys, generated from the command palette."
  (interactive)
  (let ((entries (dotfiles-palette--entries)))
    (with-help-window "*Cheatsheet*"
      (with-current-buffer standard-output
        (insert (propertize "Emacs cheatsheet" 'face 'bold) "\n"
                "C is Ctrl.  M is "
                (if (eq system-type 'darwin) "Cmd" "Alt")
                ".  C-S-p means Ctrl+Shift+P.  Click a name to run it.\n\n"
                (propertize "First steps" 'face 'bold) "\n")
        (pcase-dolist (`(,key ,description) dotfiles-cheatsheet-basics)
          (insert (format "  %-16s " (propertize key 'face 'help-key-binding))
                  description "\n"))
        (dolist (category (seq-uniq (mapcar (lambda (entry) (nth 3 entry)) entries)))
          (insert "\n" (propertize category 'face 'bold) "\n")
          (pcase-dolist (`(,text ,command ,key ,entry-category) entries)
            (when (and key (equal entry-category category))
              (insert (format "  %-16s " (propertize key 'face 'help-key-binding)))
              (insert-text-button (substring text (+ 2 (length category)))
                                  'action (lambda (_)
                                            (quit-window)
                                            (call-interactively command))
                                  'follow-link t
                                  'help-echo (symbol-name command))
              (insert "\n"))))
        (insert "\nCommands without a key are in the palette (C-S-p).\n")))))

;;;; Welcome screen

(defvar-keymap dotfiles-welcome-mode-map
  :parent special-mode-map
  "p" #'dotfiles-command-palette
  "o" #'projectile-switch-project
  "r" #'consult-recent-file
  "f" #'find-file
  "?" #'dotfiles-cheatsheet
  "t" #'help-with-tutorial
  "g" #'dotfiles-welcome
  "TAB" #'forward-button
  "<backtab>" #'backward-button)

(define-derived-mode dotfiles-welcome-mode special-mode "Welcome"
  "Start page with shortcuts, recent projects and recent files."
  (setq-local cursor-type nil))

(defun dotfiles-welcome--button (label command)
  "Insert a button LABEL that runs COMMAND."
  (insert-text-button label 'action (lambda (_) (call-interactively command))
                      'follow-link t 'help-echo (symbol-name command))
  (insert "  "))

(defun dotfiles-welcome--list (title items)
  "Insert TITLE and up to eight ITEMS, each a file or directory to open."
  (when items
    (insert "\n" (propertize title 'face 'bold) "\n")
    (dolist (item (seq-take items 8))
      (insert "  ")
      (insert-text-button (abbreviate-file-name item)
                          'action (lambda (_) (find-file item))
                          'follow-link t)
      (insert "\n"))))

(defun dotfiles-welcome-buffer ()
  "Return the refreshed welcome buffer."
  (with-current-buffer (get-buffer-create "*Welcome*")
    (let ((inhibit-read-only t))
      (erase-buffer)
      (dotfiles-welcome-mode)
      (insert "\n" (propertize "  Zaryob's Emacs" 'face '(:height 1.6 :weight bold))
              "\n  " (propertize "an IDE that still lets you be an Emacs wizard"
                                'face 'shadow)
              "\n\n  ")
      (pcase-dolist (`(,label ,command)
                     '(("[o] Open project" projectile-switch-project)
                       ("[f] Open file" find-file)
                       ("[r] Recent files" consult-recent-file)
                       ("[p] Command palette" dotfiles-command-palette)
                       ("[?] Cheatsheet" dotfiles-cheatsheet)))
        (when (fboundp command)
          (dotfiles-welcome--button label command)))
      (insert "\n")
      (dotfiles-welcome--list "Recent projects"
                              (if (bound-and-true-p projectile-known-projects)
                                  projectile-known-projects
                                (and (fboundp 'project-known-project-roots)
                                     (project-known-project-roots))))
      (dotfiles-welcome--list "Recent files" (bound-and-true-p recentf-list))
      (insert "\n" (propertize "Everyday keys" 'face 'bold) "\n")
      (pcase-dolist (`(,key ,description)
                     '(("C-S-p" "Command palette (M-m SPC in a terminal)")
                       ("C-S-b" "Build      C-<f5>  Run      C-c p t  Test")
                       ("F5" "Debug / continue   F9 breakpoint   F10 / F11 step")
                       ("M-." "Go to definition   M-, back   M-? usages")
                       ("M-m" "Leader menu: wait a moment and it lists the keys")
                       ("C-g" "Cancel anything")))
        (insert (format "  %-8s " (propertize key 'face 'help-key-binding))
                description "\n"))
      (goto-char (point-min))
      (forward-button 1 nil nil t))
    (current-buffer)))

(defun dotfiles-welcome ()
  "Show the welcome screen."
  (interactive)
  (switch-to-buffer (dotfiles-welcome-buffer)))

(unless noninteractive
  (setq initial-buffer-choice #'dotfiles-welcome-buffer))

;;;; Right-click menu

(defun dotfiles-context-menu (menu click)
  "Add IDE actions for the clicked position in CLICK to MENU."
  (when (derived-mode-p 'prog-mode)
    (let ((index 0))
      (define-key-after menu [dotfiles-separator] menu-bar-separator)
      (pcase-dolist (`(,label ,command)
                     '(("Run" dotfiles-run)
                       ("Debug" dotfiles-debug-or-continue)
                       ("Toggle Breakpoint" dape-breakpoint-toggle)
                       ("Rename Symbol" eglot-rename)
                       ("Quick Fix / Code Actions" eglot-code-actions)
                       ("Format File" eglot-format-buffer)
                       ("Comment / Uncomment" comment-line)))
        (when (fboundp command)
          (define-key-after menu (vector (intern (format "dotfiles-%d" (cl-incf index))))
            `(menu-item ,label
                        ,(lambda ()
                           (interactive)
                           (mouse-set-point click)
                           (call-interactively command))))))))
  menu)

(unless noninteractive
  (context-menu-mode 1))
(add-hook 'context-menu-functions #'dotfiles-context-menu 90)

;;;; Keys

(cua-mode 1)
(setopt cua-keep-region-after-copy t)

(keymap-global-set "C-S-p" #'dotfiles-command-palette)
(keymap-global-set "C-S-z" #'undo-redo)
(keymap-global-set "C-c ?" #'dotfiles-cheatsheet)
(defvar dotfiles-leader-map)
(with-eval-after-load 'init-project
  (keymap-set dotfiles-leader-map "SPC" #'dotfiles-command-palette)
  (keymap-set dotfiles-leader-map "?" #'dotfiles-cheatsheet))

(with-eval-after-load 'which-key
  (which-key-add-key-based-replacements
    "C-c p" "project/build" "C-c d" "debugger" "C-c l" "code"
    "M-m" "leader"))

(provide 'init-help)
;;; init-help.el ends here
