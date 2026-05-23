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
