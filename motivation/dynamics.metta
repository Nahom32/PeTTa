;; dynamics.metta — Generic decay, adjustment, and signal application.

;; Decay rate: how quickly values return to baseline each tick
(= (decayRate) 0.15)


;; Clamping
(= (clamp $value)
   (if (< $value 0.0)
       0.0
       (if (> $value 1.0) 1.0 $value)))


;; Adjustment — add a delta to a motive or modulator, clamped to [0,1]
(= (adjustMotive $name $delta)
   (let* (
      ($current (fetchMotiveValue $name))
      ($newValue (clamp (+ $current $delta)))
      ($_ (replaceMotive $name $newValue))
   )
   (motive $name $newValue)))

(= (adjustModulator $name $delta)
   (let* (
      ($current (fetchModulatorValue $name))
      ($newValue (clamp (+ $current $delta)))
      ($_ (replaceModulator $name $newValue))
   )
   (modulator $name $newValue)))


;; Decay — generic, iterates over all registered specs
(= (decayMotive $name)
   (let* (
      ($current (fetchMotiveValue $name))
      ($baseline (let (MotiveSpec $name $b) (match &self (MotiveSpec $name $b)
                     (MotiveSpec $name $b)) $b))
      ($delta (* (decayRate) (- $baseline $current)))
   )
   (adjustMotive $name $delta)))

(= (decayModulator $name)
   (let* (
      ($current (fetchModulatorValue $name))
      ($baseline (let (ModulatorSpec $name $b) (match &self (ModulatorSpec $name $b)
                     (ModulatorSpec $name $b)) $b))
      ($delta (* (decayRate) (- $baseline $current)))
   )
   (adjustModulator $name $delta)))

(= (decayMotivationState)
   (let* (
      ;; Decay all registered motives
      ($_ (collapse (let (MotiveSpec $name $_b) (match &self (MotiveSpec $name $_b)
              (MotiveSpec $name $_b))
           (decayMotive $name))))
      ;; Decay all registered modulators
      ($_ (collapse (let (ModulatorSpec $name $_b) (match &self (ModulatorSpec $name $_b)
              (ModulatorSpec $name $_b))
           (decayModulator $name))))
   )
   ()))


;; Apply a single signal — driven entirely by SignalEffect atoms in registry
(= (applySignal $signal)
   (case $signal
      (((signal $kind $strength)
        (let* (
           ;; Apply all registered effects for this signal kind
           ($_ (collapse (let (SignalEffect $kind $type $target $scale)
                   (match &self (SignalEffect $kind $type $target $scale)
                      (SignalEffect $kind $type $target $scale))
                (if (== $type motive)
                    (adjustMotive $target (* $scale $strength))
                    (adjustModulator $target (* $scale $strength))))))
           ;; Apply mode override if one is registered for this signal
           ($_ (collapse (let (SignalMode $kind $mode)
                   (match &self (SignalMode $kind $mode)
                      (SignalMode $kind $mode))
                (replaceMode $mode))))
        )
        done))
       ($other (empty)))))


;; Apply all signals from a list
(= (applySignals $signals)
   (if (== $signals ())
       ()
       (let* (
          (($head $tail) (decons-atom $signals))
          ($_ (applySignal $head))
       )
       (applySignals $tail))))


;; Run the full motivation update cycle
(= (runMotivationUpdate)
   (let* (
      ($_ (println! "Running motivation update cycle..."))
      ($_ (decayMotivationState))
      ($_ (applySignals (getSignals)))
   )
   (motivationSnapshot)))

;; Adjust a goal value by delta, clamped to [0,1].
(= (adjustGoal $name $delta)
   (let* (
      ($current  (fetchGoalValue $name))
      ($newValue (clamp (+ $current $delta)))
      ($_ (replaceGoal $name $newValue))
   )
   (goal $name $newValue)))

;; Pull a goal value back toward its GoalSpec baseline (same decay law as motives).
(= (decayGoal $name)
   (let* (
      ($current  (fetchGoalValue $name))
      ($baseline (let $b (collapse (match &self (GoalSpec $name $bl) $bl))
                     (if (== $b ()) $current (car-atom $b))))
      ($delta    (* (decayRate) (- $baseline $current)))
   )
   (adjustGoal $name $delta)))

;; Decay all goals toward their baselines.
(= (decayGoalState)
   (collapse (let (GoalSpec $name $_b)
                  (match &self (GoalSpec $name $_b) (GoalSpec $name $_b))
               (decayGoal $name))))


;; SELF MODEL UPDATE — S component

;; Exponential moving average alpha for self-model metrics.
(= (selfModelAlpha) 0.20)

;; Update the self model after each cycle.
;;   $hadError   — True if the cycle produced an error
;;   $hadResults — True if the cycle produced non-empty results
(= (updateSelfModel $hadError $hadResults)
   (let* (
      ;; Increment cycle counter
      ($_ (change-state! &cycle-count (+ (get-state &cycle-count) 1)))
      ;; Update raw success/failure counts
      ($_ (if (and $hadResults (not $hadError))
              (change-state! &success-count (+ (get-state &success-count) 1))
              _))
      ($_ (if $hadError
              (change-state! &failure-count (+ (get-state &failure-count) 1))
              _))

      ;; Compute instantaneous rates
      ($cycles   (get-state &cycle-count))
      ($successes (get-state &success-count))
      ($failures  (get-state &failure-count))
      ($instSuccess (if (> $cycles 0) (/ $successes $cycles) 0.5))
      ($instFailure (if (> $cycles 0) (/ $failures  $cycles) 0.1))

      ;; Apply EMA: new = (1-α)×old + α×inst
      ($alpha    (selfModelAlpha))
      ($oldSucc  (fetchSelfMetricValue success_rate))
      ($oldFail  (fetchSelfMetricValue failure_rate))
      ($newSucc  (clamp (+ (* (- 1.0 $alpha) $oldSucc) (* $alpha $instSuccess))))
      ($newFail  (clamp (+ (* (- 1.0 $alpha) $oldFail) (* $alpha $instFailure))))
      ($_ (replaceSelfMetric success_rate $newSucc))
      ($_ (replaceSelfMetric failure_rate $newFail))

      ;; Memory confidence: approximated from success rate (scales to [0,1])
      ($memConf  (clamp (* $newSucc 1.4)))
      ($_ (replaceSelfMetric memory_confidence $memConf))

      ;; Identity continuity: degrades with failure streak, recovers with success
      ($streak   (get-state &failure-streak))
      ($identCont (clamp (- 0.90 (* $streak 0.08))))
      ($_ (replaceSelfMetric identity_continuity $identCont))
      
      ;; Resource usage: proxy — rises with cycle count, plateaus
      ($resUsage (clamp (/ $cycles (+ $cycles 50.0))))
      ($_ (replaceSelfMetric resource_usage $resUsage))
   ) ()))

