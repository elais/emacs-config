;;; -*- lexical-binding: t; -*-

(require 'cl-lib)

(defgroup orderless nil
  "Completion method that matches space-separated regexps in any order."
  :group 'completion)

(defface orderless-match-face-0
  '((default :weight bold)
    (((class color) (min-colors 88) (background dark)) :foreground "#72a4ff")
    (((class color) (min-colors 88) (background light)) :foreground "#223fbf")
    (t :foreground "blue"))
  "Face for matches of components numbered 0 mod 4."
  :group 'orderless)

(defface orderless-match-face-1
  '((default :weight bold)
    (((class color) (min-colors 88) (background dark)) :foreground "#ed92f8")
    (((class color) (min-colors 88) (background light)) :foreground "#8f0075")
    (t :foreground "magenta"))
  "Face for matches of components numbered 1 mod 4."
  :group 'orderless)

(defface orderless-match-face-2
  '((default :weight bold)
    (((class color) (min-colors 88) (background dark)) :foreground "#90d800")
    (((class color) (min-colors 88) (background light)) :foreground "#145a00")
    (t :foreground "green"))
  "Face for matches of components numbered 2 mod 4."
  :group 'orderless)

(defface orderless-match-face-3
  '((default :weight bold)
    (((class color) (min-colors 88) (background dark)) :foreground "#f0ce43")
    (((class color) (min-colors 88) (background light)) :foreground "#804000")
    (t :foreground "yellow"))
  "Face for matches of components numbered 3 mod 4."
  :group 'orderless)

(defcustom orderless-regexp-separator " +"
  "Regexp to match component separators for orderless completion.
This is passed to `split-string' to divide the pattern into
component regexps."
  :type '(choice (const :tag "Spaces" " +")
                 (const :tag "Spaces, hyphen or slash" " +\\|[-/]")
                 (regexp :tag "Custom regexp"))
  :group 'orderless)

(defcustom orderless-match-faces
  [orderless-match-face-0
   orderless-match-face-1
   orderless-match-face-2
   orderless-match-face-3]
  "Vector of faces used (cyclically) for component matches."
  :type '(vector 'face)
  :group 'orderless)

(defun orderless--highlight-matches (regexps string)
    "Highlight matches of REGEXPS in STRING.
Warning: only call this if you know all REGEXPs match STRING!"
    (setq string (copy-sequence string))
    (cl-loop with n = (length orderless-match-faces)
             for regexp in regexps and i from 0 do
             (string-match regexp string)
             (font-lock-prepend-text-property
              (match-beginning 0)
              (match-end 0)
              'face (aref orderless-match-faces (mod i n))
              string))
    string)

(defun orderless-all-completions (string table pred _point)
  "Split STRING into components and find entries TABLE matching all.
The predicate PRED is used to constrain the entries in TABLE.
This function is part of the `orderless' completion style."
  (condition-case nil
      (save-match-data
        (let* ((limit (car (completion-boundaries string table pred "")))
               (prefix (substring string 0 limit))
               (completion-regexp-list ; used by all-completions!!!
                (split-string (substring string limit)
                              orderless-regexp-separator
                              t))
               (completions (all-completions prefix table pred)))
          (when completions
            (when minibuffer-completing-file-name
              (setq completions
                    (completion-pcm--filename-try-filter completions)))
            (nconc
             (cl-loop for candidate in completions
                      collect (orderless--highlight-matches
                               completion-regexp-list
                               candidate))
             limit))))
    (invalid-regexp nil)))

(defun orderless-try-completion (string table pred point &optional _metadata)
  "Complete STRING to unique matching entry in TABLE.
This uses `orderless-all-completions' to find matches for STRING
in TABLE among entries satisfying PRED.  If there is only one
match, it completes to that match.  If there are no matches, it
returns nil.  In any other case it \"completes\" STRING to
itself, without moving POINT.
This function is part of the `orderless' completion style."
  (let* ((limit (car (completion-boundaries string table pred "")))
         (prefix (substring string 0 limit))
         (all (orderless-all-completions string table pred point)))
    (cond
     ((null all) nil)
     ((atom (cdr all))
      (let ((full (concat prefix (car all))))
        (cons full (length full))))
     (t (cons string point)))))

(cl-pushnew '(orderless
              orderless-try-completion orderless-all-completions
              "Completion of multiple regexps, in any order.")
            completion-styles-alist
            :test #'equal)

(defvar orderless-old-regexp-separator nil
  "Stores the old value of `orderless-regexp-separator'.")

(defun orderless--restore-regexp-separator ()
  "Restore old value of `orderless-regexp-separator'."
  (when orderless-old-regexp-separator
    (setq orderless-regexp-separator orderless-old-regexp-separator
          orderless-old-regexp-separator nil))
  (remove-hook 'minibuffer-exit-hook #'orderless--restore-regexp-separator))

(defun orderless-temporarily-change-separator (separator)
  "Use SEPARATOR to split the input for the current completion session."
  (interactive
   (list (let ((enable-recursive-minibuffers t))
           (read-string "Orderless regexp separator: "))))
  (unless orderless-old-regexp-separator
    (setq orderless-old-regexp-separator orderless-regexp-separator))
  (setq orderless-regexp-separator separator)
  (add-to-list 'minibuffer-exit-hook #'orderless--restore-regexp-separator))

(provide 'orderless)
