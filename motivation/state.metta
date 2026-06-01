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

;; GOAL SPACE — G component of X=(G,M,S)
!(bind! &goal-space (new-space))

;; SELF MODEL SPACE — S component of X=(G,M,S)
!(bind! &self-model-space (new-space))

;; Performance tracking counters (raw integers, updated each cycle)
!(bind! &success-count  (new-state 0))
!(bind! &failure-count  (new-state 0))
!(bind! &cycle-count    (new-state 0))

(= (fetchGoal $name)
   (match &goal-space (goal $name $value) (goal $name $value)))

(= (fetchGoalValue $name)
   (let $res (collapse (match &goal-space (goal $name $v) $v))
      (if (== $res ())
          0.0
          (car-atom $res))))

(= (replaceGoal $name $newValue)
   (let* (
      ;; Fetch the exact atom currently in the space so remove-atom
      ;; receives the same value representation that was stored.
      ;; Pattern: same as working replaceMotive / replaceModulator.
      ($existing (collapse (match &goal-space (goal $name $v) (goal $name $v))))
      ($_ (if (!= $existing ())
              (let ((goal $n $oldValue) (car-atom $existing))
                 (remove-atom &goal-space (goal $name $oldValue)))
              _))
      ($_ (add-atom &goal-space (goal $name $newValue)))
   ) ()))

(= (getGoals)
   (collapse (match &goal-space (goal $name $value) (goal $name $value))))

;; fetchAntiGoal — returns the full (anti-goal name value) atom
(= (fetchAntiGoal $name)
   (match &goal-space (anti-goal $name $value) (anti-goal $name $value)))

(= (fetchAntiGoalValue $name)
   (let $res (collapse (match &goal-space (anti-goal $name $v) $v))
      (if (== $res ())
          0.0
          (car-atom $res))))

(= (replaceAntiGoal $name $newValue)
   (let* (
      ($existing (collapse (match &goal-space (anti-goal $name $v) (anti-goal $name $v))))
      ($_ (if (!= $existing ())
              (let ((anti-goal $n $oldValue) (car-atom $existing))
                 (remove-atom &goal-space (anti-goal $name $oldValue)))
              _))
      ($_ (add-atom &goal-space (anti-goal $name $newValue)))
   ) ()))

(= (getAntiGoals)
   (collapse (match &goal-space (anti-goal $name $value) (anti-goal $name $value))))



;; fetchSelfMetric — returns the full (self-metric name value) atom
(= (fetchSelfMetric $name)
   (match &self-model-space (self-metric $name $value) (self-metric $name $value)))

(= (fetchSelfMetricValue $name)
   (let $res (collapse (match &self-model-space (self-metric $name $v) $v))
      (if (== $res ())
          0.0
          (car-atom $res))))

(= (replaceSelfMetric $name $newValue)
   (let* (
      ($existing (collapse (match &self-model-space (self-metric $name $v) (self-metric $name $v))))
      ($_ (if (!= $existing ())
              (let ((self-metric $n $oldValue) (car-atom $existing))
                 (remove-atom &self-model-space (self-metric $name $oldValue)))
              _))
      ($_ (add-atom &self-model-space (self-metric $name $newValue)))
   ) ()))

(= (getSelfModel)
   (collapse (match &self-model-space (self-metric $name $value) (self-metric $name $value))))


;; Unified goal/motive lookup for decision scoring
;; Checks &goal-space first (GoalSpec goals), then &motivation-space (existing motives).
;; Returns 0.0 if name is not registered in either space.

(= (fetchGoalOrMotiveValue $name)
   (let $goalRes (collapse (match &goal-space (goal $name $v) $v))
      (if (!= $goalRes ())
          (car-atom $goalRes)
          (let $motiveRes (collapse (match &motivation-space (motive $name $v) $v))
             (if (!= $motiveRes ())
                 (car-atom $motiveRes)
                 0.0)))))



(= (initGoalState)
   (let* (
      ($_ (clearSpace &goal-space))
      ($_ (println! ("Initializing goal state (G) from registry...")))
      ;; Populate goals from GoalSpec atoms
      ($_ (collapse (let (GoalSpec $name $baseline)
                         (match &self (GoalSpec $name $baseline)
                                      (GoalSpec $name $baseline))
                      (add-atom &goal-space (goal $name $baseline)))))
      ;; Populate anti-goals from AntiGoalSpec atoms
      ($_ (collapse (let (AntiGoalSpec $name $weight)
                         (match &self (AntiGoalSpec $name $weight)
                                      (AntiGoalSpec $name $weight))
                      (add-atom &goal-space (anti-goal $name $weight)))))
      ($_ (println! (collapse (get-atoms &goal-space))))
   ) ()))

(= (initSelfModel)
   (let* (
      ($_ (clearSpace &self-model-space))
      ($_ (println! "Initializing self model (S) from registry..."))
      ($_ (collapse (let (SelfModelSpec $name $baseline)
                         (match &self (SelfModelSpec $name $baseline)
                                      (SelfModelSpec $name $baseline))
                      (add-atom &self-model-space (self-metric $name $baseline)))))
      ($_ (change-state! &success-count 0))
      ($_ (change-state! &failure-count 0))
      ($_ (change-state! &cycle-count   0))
      ($_ (println! (collapse (get-atoms &self-model-space))))
   ) ()))




(= (fullMotivationSnapshot)
   (X
      (G (getGoals) (getAntiGoals))
      (M (getModulators))
      (S (getSelfModel))))

