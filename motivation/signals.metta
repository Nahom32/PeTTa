;; Signal extraction from OmegaClaw loop state.

;; Required atoms from OmegaClaw:
;;   &prevmsg       — last received user message (string)
;;   &lastresults   — results from the previous skill dispatch (string)
;;   &error         — error list from the previous cycle (list)



(= (hasContent $value)
   (> (eval (string_length (eval (string-safe $value)))) 2))

(= (clearSignals)
   (clearSpace &signal-space))

(= (addSignal $kind $strength)
   (add-atom &signal-space (signal $kind $strength)))

(= (getSignals)
   (collapse (match &signal-space (signal $kind $strength) (signal $kind $strength))))


;; refreshSignals
;; Extract signals from current OmegaClaw state.
(= (refreshSignals)
   (let* (
      ($_ (collapse (clearSignals)))
      ;; Read OmegaClaw state (interface contract)
      ($msg        (get-state &prevmsg))
      ($activeTask (get-state &active-task))
      ($results    (get-state &lastresults))
      ($error      (get-state &error))
      ;; Compute predicates once
      ($hasMsg     (hasContent $msg))
      ($hasResults (hasContent $results))
      ($hasError   (> (eval (string_length (eval (string-safe (repr $error))))) 4))
      ($resultsLen (eval (string_length (eval (string-safe $results)))))
      ;; Update failure streak
      ($_ (if $hasError
              (change-state! &failure-streak (+ (get-state &failure-streak) 1))
              (change-state! &failure-streak 0)))
      ($failureStreak (get-state &failure-streak))

      ;; --- Signal emission (prioritized) ---

      ;; 1. Repeated failure: multiple consecutive errors
      ($_ (if (and (> $failureStreak 1) $hasError)
              (addSignal repeated-failure 0.85)
              _))
      ;; 2. Single failure
      ($_ (if (and $hasError (<= $failureStreak 1))
              (addSignal failure 0.80)
              _))
      ;; 3. Task drift: user said something new while a different task was active
      ($_ (if (and $hasMsg (hasContent $activeTask) (!= $msg $activeTask))
              (addSignal task-drift 0.45)
              _))
      ;; 4. Ambiguity: user spoke but no results produced
      ($_ (if (and $hasMsg (not $hasResults) (not $hasError))
              (addSignal ambiguity 0.60)
              _))
      ;; 5. Verified success: substantial results, no errors
      ($_ (if (and (> $resultsLen 20) (not $hasError))
              (addSignal verified-success 0.55)
              _))
      ;; 6. Progress made: some results (but not large enough for verified-success)
      ($_ (if (and $hasResults (<= $resultsLen 20) (not $hasError))
              (addSignal progress-made 0.40)
              _))
      ;; 7. Stalled progress: user waiting, minimal results, no error
      ($_ (if (and $hasMsg (not $hasResults) (not $hasError))
              (addSignal stalled-progress 0.35)
              _))
      ;; 8. User waiting: user has a message pending
      ($_ (if $hasMsg
              (addSignal user-waiting 0.30)
              _))
      ;; Track the active task
      ($_ (if $hasMsg
              (change-state! &active-task $msg)
              _))
   )
   (getSignals)))
