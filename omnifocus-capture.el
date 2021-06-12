;; Based on omnifocus-capture.el by Ken Case with the following original comment:
;;
;; To capture tasks from Emacs to OmniFocus using Control-C Control-O,
;; drop this script in your emacs load path and add lines like these to
;; your .emacs:
;;
;; (autoload 'send-region-to-omnifocus "omnifocus-capture" "Send region to OmniFocus" t)
;; (global-set-key (kbd "C-c C-o") 'send-region-to-omnifocus)
;;
;; The send-region-to-emacs function has been rewritten as follows:
;; * The task is sent directly to the Inbox rather than the quick entry window.
;; * It now uses `do-applescript' instead of writing a temporary script file.
;; * The first line of the region is used as the name of the task
;; * Subsequent lines of the region are used as the task note.
;; * "Added from Emacs on <current date>" is appended to the end of the note.
;;
;; References:
;;
;; 1. Sending text from Emacs to OmniFocus by Ken Case
;;    http://forums.omnigroup.com/showthread.php?t=12115
;; 2. Omnifocus Quick Entry from Emacs by Tim Prouty
;;    http://timprouty-tech.blogspot.com/2009/08/omnifocus-quick-entry-from-emacs.html
;; 3. omnifocus.el by Rob Bevan
;;    https://github.com/robbevan/omnifocus.el
;;
;; See http://jblevins.org/log/emacs-omnifocus for details.

(defun applescript-quote-string (argument)
  "Quote a string for passing as a string to AppleScript."
  (if (or (not argument) (string-equal argument ""))
      "\"\""
    ;; Quote using double quotes, but escape any existing quotes or
    ;; backslashes in the argument with backslashes.
    (let ((result "")
          (start 0)
          end)
      (save-match-data
        (if (or (null (string-match "[^\"\\]" argument))
                (< (match-end 0) (length argument)))
            (while (string-match "[\"\\]" argument start)
              (setq end (match-beginning 0)
                    result (concat result (substring argument start end)
                                   "\\" (substring argument end (1+ end)))
                    start (1+ end))))
        (concat "\"" result (substring argument start) "\"")))))

(defun send-region-to-omnifocus (beg end)
  "Send the selected region to OmniFocus.
Use the first line of the region as the task name and the second
and subsequent lines as the task note."
  (interactive "r")
  (let* ((region (buffer-substring-no-properties beg end))
         (match (string-match "^\\(.*\\)$" region))
         (name (substring region (match-beginning 1) (match-end 1)))
         (note (if (< (match-end 0) (length region))
                   (concat (substring region (+ (match-end 0) 1) nil) "\n\n")
                 "")))
    (do-applescript
     (format "set theDate to current date
              set taskName to %s
              set taskNote to %s
              set taskNote to (taskNote) & \"Added from Emacs on \" & (theDate as string)
              tell front document of application \"OmniFocus\"
                make new inbox task with properties {name:(taskName), note:(taskNote)}
              end tell"
             (applescript-quote-string name)
             (applescript-quote-string note)))
    ;; (message "Sent to OmniFocus: `%s'" name)))
    (message "Sent to OmniFocus: %s" name)))
