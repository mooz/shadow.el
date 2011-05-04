;;; shadow.el --- That's not the file. That's shadow.

;; Copyright (C) 2011  mooz

;; Author: mooz <stillpedant@gmail.com>
;; Keywords: shadow.vim, files, processes

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;; See https://github.com/ujihisa/shadow.vim to check basic idea.

;;; Usage:
;;
;; In your emacs config, put below lines.
;;
;; (require 'shadow)
;; (add-hook 'shadow-mode-hook 'shadow-set-auto-mode)
;;

;;; Code:

(eval-when-compile (require 'cl))

(defvar shadow-minor-mode nil
  "Dummy variable to suppress compiler warnings.")

(defvar shadow-mode-hook nil
  "Hook for `shadow-mode'.")

(defcustom shadow-command-skip-count 3
  "Skip characters count for shadow.vim style command specification line.
For instance, when `shadow-command-skip-count' is 3
and command specification line is given as described below,

###cat

first 3 characters (###) are skipped and \"cat\" is used as a command.")

(defcustom shadow-command-line-number 0
  "Line number (zero-originated) of shadow.vim style command specification line.")

(defcustom shadow-unshadow-regexp "^\\(.*\\)\\.shd$"
  "Regexp which is used to extract unshadowed file name from shadow file name.")

(defcustom shadow-display-unshadow-message-p nil
  "When this value is non-nil, message is displayed when unshadowed file is wrote.")

(defcustom shadow-update-file-local-variables-on-save-p t
  "When this value is non-nil, update file local variables when user save shadow file.")

(defmacro shadow-defvar (name &optional value safep doc)
  "Define buffer-local and safe-local variable."
  (declare (indent defun))
  `(progn
     (defvar ,name ,value ,doc)
     (make-variable-buffer-local (quote ,name))
     ;; Suppress file local variable warning
     (put (quote ,name) 'safe-local-variable (quote ,safep))))

(shadow-defvar shadow-command
  nil stringp
  "Specify shadow command directly as a file local variable like below example.

# -*- shadow-command: \"tac\" -*-

If this value is nil, shadow.vim style command is used alternatively.")

(defun shadow-buffer-get-nth-line (buffer n)
  "Get nth line of `buffer' as a raw string."
  (with-current-buffer buffer
    (save-excursion
      (goto-char (point-min))
      (forward-line n)
      (buffer-substring-no-properties (point)
                                      (progn (end-of-line) (point))))))

(defun shadow-get-command-for-buffer (&optional buffer)
  "Get unshadow command from shadowed buffer."
  (condition-case nil
      (substring (shadow-buffer-get-nth-line (or buffer (current-buffer))
                                             shadow-command-line-number)
                 shadow-command-skip-count)
    (error nil)))

(defun shadow-unshadow-name (shadowed-name)
  "Extract unshadowed filename from shadowed filename."
  (when (string-match shadow-unshadow-regexp shadowed-name)
    (match-string-no-properties 1 shadowed-name)))

(defun shadow-purge-command-specification (shadowed)
  "Create command which purge command specification line in shadow file."
  (format "sed '%dd' %s"
          (1+ shadow-command-line-number)
          shadowed))

(defun shadow-get-shadowed-command (shadowed)
  (if shadow-command
      (format "cat %s" shadowed)
    ;; remove command specification line in shadowed file
    (setq shadowed (shadow-purge-command-specification shadowed))))

(defvar shadow-haunting-command-builder
  (lambda (command shadowed-command shadowed unshadowed)
    (format "(%s | %s) > %s" shadowed-command command unshadowed))
  "Build final command which is executed when user saves shadow file.")

(defun shadow-get-haunting-command ()
  "Get command for unshadowed file creation."
  (let* ((command (or shadow-command (shadow-get-command-for-buffer)))
         (shadowed (buffer-file-name))
         (unshadowed (shadow-unshadow-name shadowed)))
    (and command
         unshadowed
         (funcall shadow-haunting-command-builder
                  command
                  (shadow-get-shadowed-command shadowed)
                  shadowed
                  unshadowed))))

(defun shadow-haunt ()
  "Write unshadowed file."
  (when shadow-update-file-local-variables-on-save-p
    (hack-local-variables))
  (let ((haunting-command (shadow-get-haunting-command)))
    (when haunting-command
      (shadow-with-suppressing-messages
       (shell-command haunting-command))
      (when shadow-display-unshadow-message-p
        (message "Shadow: %s" haunting-command))))
  nil)

(defun shadow-set-auto-mode ()
  "Set proper mode for unshadowed file in shadowed file."
  (let ((buffer-file-name (shadow-unshadow-name (buffer-file-name))))
    (set-auto-mode t)))

(defun shadow-arrange ()
  "Arrange shadow.el in target buffer."
  (interactive)
  (run-hooks 'shadow-mode-hook)
  (shadow-minor-mode 1))

(defmacro shadow-with-suppressing-messages (&rest body)
  "All messages are suppressed in this context."
  `(flet ((message (&rest) nil))
     ,@body))

(define-minor-mode shadow-minor-mode
  "Shadow mode"
  :lighter " Shadow"
  (if shadow-minor-mode
      (progn
        ;; enable
        (add-hook 'after-save-hook 'shadow-haunt nil t))
    ;; disable
    (remove-hook 'after-save-hook 'shadow-haunt t)))

(defadvice normal-mode (after after-normal-mode activate)
  "Activate shadow mode if this file is a shadow."
  (when (string-match-p shadow-unshadow-regexp buffer-file-name)
    (run-hooks 'shadow-mode-hook)
    (shadow-minor-mode 1)))

(provide 'shadow)
;;; shadow.el ends here
