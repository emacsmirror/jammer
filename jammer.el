;;; jammer.el --- Punish yourself for using Emacs inefficiently

;; Copyright (C) 2015 Vasilij Schneidermann <v.schneidermann@gmail.com>

;; Author: Vasilij Schneidermann <v.schneidermann@gmail.com>
;; URL: https://github.com/wasamasa/jammer
;; Version: 0.0.1
;; Keywords: games

;; This file is NOT part of GNU Emacs.

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING. If not, write to
;; the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Commentary:

;; This global minor mode allows you to slow down command execution
;; globally in Emacs.

;; See the README for more info:
;; https://github.com/wasamasa/jammer

;;; Code:

(defgroup jammer nil
  "Punish yourself for using Emacs inefficiently"
  :group 'games
  :prefix "jammer-")

(defcustom jammer-lighter " ^_^"
  "Lighter for `jammer-mode'."
  :type 'string
  :group 'jammer)

(defcustom jammer-block-type 'whitelist
  "Block list type for `jammer-block-list'.
When set to 'blacklist, only affect the items of
`jammer-block-list'.  When set to 'whitelist, affect everything
except the items of `jammer-block-list'."
  :type '(choice (const :tag "Blacklist" blacklist)
                 (const :tag "Whitelist" whitelist))
  :group 'jammer)

(defcustom jammer-block-list '()
  "List of exclusively affected or exempt commands.
The behaviour is set by `jammer-block-type'."
  :type '(repeat symbol)
  :group 'jammer)

(defcustom jammer-type 'repeat
  "Type of blocking.

'repeat: Block repeated key strokes.

'constant: Slow everything down.

'random: Slow down randomly."
  :type '(choice (const :tag "Repeat" repeat)
                 (const :tag "Constant" constant)
                 (const :tag "Random" random))
  :group 'jammer)

(defcustom jammer-repeat-type 'constant
  "Type of slowdown.

'constant: Constant delay.

'linear:  Delay increases by repetition count.

'quadratic: Delay increases by repetition count squared."
  :type '(choice (const :tag "Constant" constant)
                 (const :tag "Linear" linear)
                 (const :tag "Quadratic" quadratic))
  :group 'jammer)

(defcustom jammer-repeat-delay 0.05
  "Base delay value in seconds.
Applies to a value of 'repeat for `jammer-repeat-type'."
  :type 'float
  :group 'jammer)

(defcustom jammer-repeat-window 0.1
  "Repetition window in seconds.
An event happening in less seconds than this value will be
counted as repetition."
  :type 'float
  :group 'jammer)

(defcustom jammer-repeat-allowed-repetitions 1
  "Maximum value of allowed repetitions.
Events detected as repetitions are not taken into account if the
repetition count is smaller or equal to this value."
  :type 'integer
  :group 'jammer)

(defvar jammer-repeat-state [[] 0 0.0]
  "Internal state of last repeated event.
The first element is the last event as returned by
`this-command-keys-vector', the second is its repetition count,
the third its floating point timestamp as returned by
`float-time'.")

(defcustom jammer-constant-delay 0.04
  "Base delay value in seconds.
Applies to a value of 'constant for `jammer-repeat-type'."
  :type 'float
  :group 'jammer)

(defcustom jammer-random-delay 0.01
  "Base delay value in seconds.
Applies to a value of 'random for `jammer-repeat-type'."
  :type 'float
  :group 'jammer)

(defcustom jammer-random-probability 0.2
  "Probability for a slowdown to happen.
It has to be a floating point number between 0 and 1."
  :type 'float
  :group 'jammer)

(defvar jammer-random-minimum-probability 0.01
  "Minimum allowed probability for a slowdown.")

(defvar jammer-random-maximum-probability 1.0
  "Maximum allowed probability for a slowdown.")

(defcustom jammer-random-amplification 10
  "Amplification span of the random delay.
The base delay can be amplified with a random factor up to this
value."
  :type 'integer
  :group 'jammer)

(defun jammer ()
  "Slow down command execution.
The general behaviour is determined by `jammer-type'."
  (when (or (and (eq jammer-block-type 'whitelist)
                 (not (memq this-command jammer-block-list)))
            (and (eq jammer-block-type 'blacklist)
                 (memq this-command jammer-block-list)))
    (cond
     ((eq jammer-type 'repeat)
      (let ((window (- (float-time) (aref jammer-repeat-state 2)))
            ;; use constant, linear, quadratic or no delay in the
            ;; erroneous customization case, similiar to the no-op done
            ;; if no known jammer type is enabled
            (delay (or (cond
                        ((eq jammer-repeat-type 'constant)
                         jammer-repeat-delay)
                        ((eq jammer-repeat-type 'linear)
                         (* (- (aref jammer-repeat-state 1)
                               jammer-repeat-allowed-repetitions)
                            jammer-repeat-delay))
                        ((eq jammer-repeat-type 'quadratic)
                         (* (expt (- (aref jammer-repeat-state 1)
                                     jammer-repeat-allowed-repetitions)
                                  2)
                            jammer-repeat-delay))) 0)))
        ;; did a different key event happen or enough time pass?
        (if (or (not (equal (this-command-keys-vector)
                            (aref jammer-repeat-state 0)))
                (> window jammer-repeat-window))
            ;; if yes, reset the counter
            (aset jammer-repeat-state 1 0)
          ;; otherwise increment it
          (aset jammer-repeat-state 1 (1+ (aref jammer-repeat-state 1))))
        ;; if too little time passed, sleep for the delay calculated
        ;; earlier
        (when (and (>= (aref jammer-repeat-state 1)
                       jammer-repeat-allowed-repetitions)
                   (< window jammer-repeat-window))
          ;; `sleep-for' does uninterruptable sleep without display update,
          ;; `discard-input' throws away piled up input from that
          ;; sleeping time
          (sleep-for delay)
          (discard-input)))
      ;; do book keeping for the next command
      (aset jammer-repeat-state 0 (this-command-keys-vector))
      (aset jammer-repeat-state 2 (float-time)))
     ((eq jammer-type 'constant)
      (sleep-for jammer-constant-delay)
      (discard-input))
     ((eq jammer-type 'random)
      ;; the random function simulates a rare event and amplifies its
      ;; extent randomly
      (when (= (random (floor (/ 1 (min jammer-random-maximum-probability
                                        (max jammer-random-minimum-probability
                                             jammer-random-probability))))) 0)
        (sleep-for (* (random (1+ jammer-random-amplification))
                      jammer-random-delay))
        (discard-input))))))

(define-minor-mode jammer-mode
  "Toggle `jammer-mode'.
This global minor mode allows you to slow down command execution
globally in Emacs."
  :lighter jammer-lighter
  :global t
  (if jammer-mode
      (add-hook 'post-command-hook 'jammer)
    (remove-hook 'post-command-hook 'jammer)))

(provide 'jammer)
;;; jammer.el ends here