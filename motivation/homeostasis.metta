;; Homeostatic Governance Layer
;;
;; Maintains the agent within a safe motivational region.
;; Fires AFTER the motivation update cycle and BEFORE candidate scoring.
;;
;; Reads HomeostaticRule atoms from the registry and applies them
;; when their trigger conditions are met.
;;
;; Trigger types:
;;   modulator-exceeds  — fires when modulator value > threshold
;;   self-metric-below  — fires when self-model metric value < threshold
;;
;; Action types:
;;   raise-modulator    — adjustModulator  target +delta
;;   lower-modulator    — adjustModulator  target -delta
;;   raise-goal         — adjustGoal       target +delta
;;   lower-goal         — adjustGoal       target -delta
;;
;; The homeostasis layer DAMPS goal updates and exploration when:
;;   • risk becomes excessive (securing > 0.75)
;;   • confidence collapses   (memory_confidence < 0.20)
;;   • success rate is low    (success_rate < 0.15)
;;   • identity continuity degrades (identity_continuity < 0.30)


;; Evaluate whether a HomeostaticRule condition is currently triggered.
(= (homeoRuleFires $condType $metric $threshold)
   (case $condType (
      ((modulator-exceeds)
       (> (eval (fetchModulatorValue $metric)) $threshold))
      ((self-metric-below)
       (< (eval (fetchSelfMetricValue $metric)) $threshold))
      ($other False))))



;; Apply a single homeostatic action atom.
;; Returns done or empty (if action type is unrecognised).
(= (applyHomeoAction $actionType $target $delta)
   (case $actionType (
      ((raise-modulator)
       (let $_ (eval (adjustModulator $target $delta)) done))
      ((lower-modulator)
       (let $_ (eval (adjustModulator $target (- 0.0 $delta))) done))
      ((raise-goal)
       (let $_ (eval (adjustGoal $target $delta)) done))
      ((lower-goal)
       (let $_ (eval (adjustGoal $target (- 0.0 $delta))) done))
      ($other (empty)))))


;; Iterates over every HomeostaticRule atom.
;; When the condition fires, applies the corresponding action.
;; All matching rules fire (not just the first one).
(= (runHomeostasis)
   (let* (
      ($fired (collapse
         (let (HomeostaticRule $condType $metric $threshold $actionType $target $delta)
              (match &self
                 (HomeostaticRule $condType $metric $threshold $actionType $target $delta)
                 (HomeostaticRule $condType $metric $threshold $actionType $target $delta))
           (if (homeoRuleFires $condType $metric $threshold)
               (let $_ (applyHomeoAction $actionType $target $delta)
                  (homeostatic-action $condType $metric $actionType $target $delta))
               (empty)))))
      ($nFired (let $l (collapse (let $_ (match &self (HomeostaticRule $_ $_ $_ $_ $_ $_) 1) 1)) 0))
      ($_ (if (== $fired ())
              (println! "Homeostasis: no rules triggered.")
              (println! (eval (py-str ("Homeostasis fired: " (repr $fired)))))))
   )
   $fired))
