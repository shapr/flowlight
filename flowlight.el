;;; flowlight.el --- This is my cool package --- -*- lexical-binding: t; -*-

;;; Commentary:
;;; This is a reimplementation of the FlowLight from
;;; https://christop.club/publications/pdfs/Zuger-etal_2017.pdf


;;; Code:
(require 'cl-lib)
;; flowlight-activity-intervals is a list of pairs of
;; (now-in-unix-time, emacs-idle-time-in-seconds)
(defvar flowlight-activity-intervals nil)

;; this timer runs every ten seconds and adds another pair of
;; (unix-time . emacs-idle-time) into flowlight-activity-intervals

;; A variable that holds the timer
(defvar flowlight-write-interval-timer-var nil)

(defun flowlight-write-interval ()
  "The function that writes a new pair into the variable."
  (interactive)
  (push (cons (time-convert nil 'integer) (time-convert (current-idle-time) 'integer)) flowlight-activity-intervals))

(defun flowlight-write-interval-timer-start ()
  "Start the interval timer."
  (interactive)
  ;; what does this section do for me?
  (when (timerp flowlight-write-interval-timer-var)
    (cancel-timer flowlight-write-interval-timer-var))
  (setq flowlight-write-interval-timer-var
	(run-with-timer 10 10 #'flowlight-write-interval)))

(defun flowlight-write-interval-timer-stop ()
  "Stop the interval timer."
  (interactive)
  (when (timerp flowlight-write-interval-timer-var)
    (cancel-timer flowlight-write-interval-timer-var)
    (setq flowlight-write-interval-timer-var nil)))

;; This time runs every thirty seconds and calculates the color to send to the LED
(defvar flowlight-update-color-timer-var nil)


;; will this break if I type fast enough for (current-idle-time) to return nil ?
(defun is-active (pair)
  "Check PAIR, idle values less than 10 seconds counts as active.
idle returns -1 and active returns 1."
  (if (< (cdr pair) 10) 1 -1)) ;; 10 seconds is the sample time, best to match that?

(defun flowlight-update-color ()
  "Update the color.
This is done by checking whether more than half of the samples
from the last seven minutes have activity."
  (interactive)
  (progn
    (flowlight-prune-activity-intervals) ;; remove old values
    (if
	;; is-active converts idle values to -1 and non-idle to +1
	;; sum together all the idle and active values, if positive, send RED for BUSY
	(> (apply '+ (cl-mapcar 'is-active flowlight-activity-intervals)) 0)
	;; send RED for busy
	(url-retrieve "http://flowlight.local/status?status=busy" 'message)
      ;; send GREEN for not-busy
      (url-retrieve "http://flowlight.local/status?status=free" 'message))))

(defun flowlight-update-color-timer-start ()
  "Start the color update timer."
  (interactive)
  ;; what does this section do for me?
  (when (timerp flowlight-update-color-timer-var)
    (cancel-timer flowlight-update-color-timer-var))
  (setq flowlight-update-color-timer-var
	(run-with-timer 30 30 #'flowlight-update-color)))

(defun flowlight-update-color-timer-stop ()
  "Stop the color update timer."
  (interactive)
  (when (timerp flowlight-update-color-timer-var)
    (cancel-timer flowlight-update-color-timer-var)
    (setq flowlight-update-color-timer-var nil)))

;; this function removes values that are older than seven minutes ago
(defun flowlight-prune-activity-intervals ()
  "Remove any samples older than seven minutes."
  (interactive)
  (let ((seven-minutes-before-now (- (time-convert nil 'integer) (* 60 7))))
    (setq flowlight-activity-intervals
	  (cl-remove-if (lambda (row) (> seven-minutes-before-now (car row))) flowlight-activity-intervals))))

;; start recording idle time every ten seconds!
(flowlight-write-interval-timer-start)
;; start updating the activity color every thirty seconds!
(flowlight-update-color-timer-start)

(provide 'flowlight)
;;; flowlight.el ends here
