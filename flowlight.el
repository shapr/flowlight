;; fl-activity-intervals is a list of pairs of
;; (now-in-unix-time, emacs-idle-time-in-seconds)
(defvar fl-activity-intervals nil)

;; this timer runs every ten seconds and adds another pair of
;; (unix-time . emacs-idle-time) into fl-activity-intervals

;; A variable that holds the timer
(defvar fl-write-interval-timer-var nil)

;; the function that writes a new pair into the variable
(defun fl-write-interval ()
  (interactive)
  (push (cons (time-convert nil 'integer) (time-convert (current-idle-time) 'integer)) fl-activity-intervals))

;; start timer function
(defun fl-write-interval-timer-start ()
  (interactive)
  ;; what does this section do for me?
  (when (timerp fl-write-interval-timer-var)
    (cancel-timer fl-write-interval-timer-var))
  (setq fl-write-interval-timer-var
	(run-with-timer 10 10 #'fl-write-interval)))

;; stop timer function
(defun fl-write-interval-timer-stop ()
  (interactive)
  (when (timerp fl-write-interval-timer-var)
    (cancel-timer fl-write-interval-timer-var)
    (setq fl-write-interval-timer-var nil)))

;; This time runs every thirty seconds and calculates the color to send to the LED
(defvar fl-update-color-timer-var nil)

(defun is-active (pair)
  (if (cdr pair) 1 -1))

(defun fl-update-color ()
  (interactive)
  (progn
    (fl-prune-activity-intervals) ;; remove old values
    (if
	(> (apply '+ (cl-mapcar 'is-active fl-test-intervals)) 0)
	;; send RED for busy
	(url-retrieve "http://flowlight.local/unsafe?runthis=WygyNTUsMCwwKSBmb3IgaSBpbiByYW5nZSgzMCld" 'message)
      ;; send GREEN for not-busy
      (url-retrieve "http://flowlight.local/unsafe?runthis=WygwLDI1NSwwKSBmb3IgaSBpbiByYW5nZShudW1fcGl4ZWxzKV0=" 'message))))

(defun fl-update-color-timer-start ()
  (interactive)
  ;; what does this section do for me?
  (when (timerp fl-update-color-timer-var)
    (cancel-timer fl-update-color-timer-var))
  (setq fl-update-color-timer-var
	(run-with-timer 30 30 #'fl-update-color)))

(defun fl-update-color-timer-stop ()
  (interactive)
  (when (timerp fl-update-color-timer-var)
    (cancel-timer fl-update-color-timer-var)
    (setq fl-update-color-timer-var nil)))

;; this function removes values that are older than seven minutes ago
(defun fl-prune-activity-intervals ()
  (interactive)
  (let
      ((seven-minutes-before-now (- (time-convert nil 'integer) (* 60 7))))
    (setq fl-activity-intervals
	  (remove-if '(lambda (row) (> seven-minutes-before-now (car row))) fl-activity-intervals))))

;; start recording idle time every ten seconds!
(fl-write-interval-timer-start)
;; start updating the activity color every thirty seconds!
(fl-update-color-timer-start)
