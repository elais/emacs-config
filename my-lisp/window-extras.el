;;; -*- lexical-binding: t; -*-

(defun toggle-window-split ()
  "Toggle window split from vertical to horizontal."
  (interactive)
  (if (> (length (window-list)) 2)
      (error "Can't toggle with more than 2 windows.")
    (let ((was-full-height (window-full-height-p)))
      (delete-other-windows)
      (if was-full-height
          (split-window-vertically)
        (split-window-horizontally))
      (save-selected-window
        (other-window 1)
        (switch-to-buffer (other-buffer))))))

(defun transpose-windows ()
  "Swap the buffers shown in current and next window."
  (interactive)
  (let ((this-buffer (window-buffer))
        (next-window (next-window nil :no-minibuf nil)))
    (set-window-buffer nil (window-buffer next-window))
    (set-window-buffer next-window this-buffer)
    (select-window next-window)))

;; Written by alphapapa, https://www.reddit.com/r/emacs/comments/idz35e/emacs_27_can_take_svg_screenshots_of_itself/g2c2c6y
(defun screenshot-svg ()
  "Save a screenshot of the current frame as an SVG image.
Saves to a temp file and puts the filename in the kill ring."
  (interactive)
  (let* ((filename (make-temp-file "Emacs" nil ".svg"))
         (data (x-export-frames nil 'svg)))
    (with-temp-file filename
      (insert data))
    (kill-new filename)
    (message filename)))

(provide 'window-extras)
