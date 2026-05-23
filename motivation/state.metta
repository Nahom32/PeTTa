;; state.metta — Generic motivation state operations.
!(bind! &motivation-space (new-space))
!(bind! &signal-space (new-space))

;; Mutable state atoms for tracking streaks and decisions
!(bind! &failure-streak (new-state 0))
!(bind! &active-task (new-state ""))
!(bind! &last-motivation-decision (new-state (decision clarity orient inspect 0.0)))


;; Initialization — populates &motivation-space from registry specs
(= (initMotivationState)
   (let* (
      ($_ (clearSpace &motivation-space))
      ($_ (println! "Initializing motivation state from registry..."))
      
      ($_ (collapse (let (MotiveSpec $name $baseline) (match &self (MotiveSpec $name $baseline)
               (MotiveSpec $name $baseline))
            (add-atom &motivation-space (motive $name $baseline)))))
            
      ($_ (collapse (let (ModulatorSpec $name $baseline) (match &self (ModulatorSpec $name $baseline)
               (ModulatorSpec $name $baseline))
            (add-atom &motivation-space (modulator $name $baseline)))))
            
      ($_ (add-atom &motivation-space (mode orient)))
      
      ($_ (change-state! &failure-streak 0))
      ($_ (change-state! &active-task ""))
      ($_ (change-state! &last-motivation-decision (decision clarity orient inspect 0.0)))
      ($_ (println! (collapse (get-atoms &motivation-space))))
   )
   ()))


(= (clearSpace $space)
   (collapse (let $atom (get-atoms $space) (remove-atom $space $atom))))


(= (fetchMotive $name)
   (match &motivation-space (motive $name $value) (motive $name $value)))

(= (fetchMotiveValue $name)
   (let (motive $n $value) (fetchMotive $name) $value))

(= (fetchModulator $name)
   (match &motivation-space (modulator $name $value) (modulator $name $value)))

(= (fetchModulatorValue $name)
   (let (modulator $n $value) (fetchModulator $name) $value))

(= (fetchMode)
   (match &motivation-space (mode $name) (mode $name)))


(= (replaceMotive $name $newValue)
   (let* (
      ((motive $name $oldValue) (fetchMotive $name))
      ($_ (remove-atom &motivation-space (motive $name $oldValue)))
      ($_ (add-atom &motivation-space (motive $name $newValue)))
   )
   ()))

(= (replaceModulator $name $newValue)
   (let* (
      ((modulator $name $oldValue) (fetchModulator $name))
      ($_ (remove-atom &motivation-space (modulator $name $oldValue)))
      ($_ (add-atom &motivation-space (modulator $name $newValue)))
   )
   ()))

(= (replaceMode $newMode)
   (let* (
      ((mode $oldMode) (fetchMode))
      ($_ (remove-atom &motivation-space (mode $oldMode)))
      ($_ (add-atom &motivation-space (mode $newMode)))
   )
   ()))


(= (getMotives)
   (collapse (match &motivation-space (motive $name $value) (motive $name $value))))

(= (getModulators)
   (collapse (match &motivation-space (modulator $name $value) (modulator $name $value))))

(= (motivationSnapshot)
   (state
      (getMotives)
      (getModulators)
      (fetchMode)))
