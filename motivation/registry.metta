;; Motive specifications: (MotiveSpec <name> <baseline>)
(MotiveSpec clarity         0.45)
(MotiveSpec progress        0.55)
(MotiveSpec reliability     0.50)
(MotiveSpec adaptivity      0.40)
(MotiveSpec coherence       0.45)
(MotiveSpec responsiveness  0.45)


;; Modulator specifications: (ModulatorSpec <name> <baseline>)
(ModulatorSpec urgency           0.50)
(ModulatorSpec caution           0.50)
(ModulatorSpec persistence       0.55)
(ModulatorSpec exploration_bias  0.40)
(ModulatorSpec context_depth     0.50)
(ModulatorSpec human_deference   0.40)


;; Score weights: (ScoreWeight <motive> <modulator> <sign>)
;;   sign = 1.0  means the modulator adds positively to the motive's score
;;   sign = -1.0 means it subtracts (e.g. adaptivity anti-correlates with persistence)
(ScoreWeight clarity         context_depth     1.0)
(ScoreWeight clarity         caution           1.0)
(ScoreWeight progress        urgency           1.0)
(ScoreWeight progress        persistence       1.0)
(ScoreWeight reliability     caution           1.0)
(ScoreWeight reliability     human_deference   1.0)
(ScoreWeight adaptivity      exploration_bias  1.0)
(ScoreWeight adaptivity      persistence      -1.0)
(ScoreWeight coherence       context_depth     1.0)
(ScoreWeight coherence       human_deference   1.0)
(ScoreWeight responsiveness  urgency           1.0)
(ScoreWeight responsiveness  human_deference   1.0)


;; Decision mappings: (DecisionMap <motive> <mode> <directive>)
;;   When a motive wins, this determines the agent's behavioral mode.
(DecisionMap clarity         orient   inspect)
(DecisionMap progress        execute  execute)
(DecisionMap reliability     verify   verify)
(DecisionMap adaptivity      recover  recover)
(DecisionMap coherence       orient   inspect)
(DecisionMap responsiveness  execute  execute)


;; Signal→Effect mappings: (SignalEffect <signal-kind> <target-type> <target-name> <scale>)
;;   target-type is either 'motive' or 'modulator'
;;   scale > 0 means signal raises the target; < 0 means it lowers it

;; ambiguity
(SignalEffect ambiguity        motive    clarity         0.40)
(SignalEffect ambiguity        modulator caution         0.15)
(SignalEffect ambiguity        modulator context_depth   0.20)

;; failure
(SignalEffect failure          motive    reliability     0.35)
(SignalEffect failure          motive    adaptivity      0.25)
(SignalEffect failure          modulator caution         0.20)
(SignalEffect failure          modulator urgency         0.15)

;; repeated-failure
(SignalEffect repeated-failure motive    adaptivity      0.40)
(SignalEffect repeated-failure motive    reliability     0.15)
(SignalEffect repeated-failure modulator persistence    -0.30)
(SignalEffect repeated-failure modulator exploration_bias 0.30)

;; stalled-progress
(SignalEffect stalled-progress motive    progress        0.30)
(SignalEffect stalled-progress motive    adaptivity      0.20)
(SignalEffect stalled-progress modulator urgency         0.15)

;; verified-success
(SignalEffect verified-success motive    reliability    -0.30)
(SignalEffect verified-success motive    clarity        -0.20)
(SignalEffect verified-success modulator caution        -0.15)

;; progress-made
(SignalEffect progress-made    motive    progress       -0.25)
(SignalEffect progress-made    modulator persistence     0.10)

;; task-drift
(SignalEffect task-drift       motive    coherence       0.35)
(SignalEffect task-drift       modulator context_depth   0.10)
(SignalEffect task-drift       modulator human_deference 0.10)

;; user-waiting
(SignalEffect user-waiting     motive    responsiveness  0.35)
(SignalEffect user-waiting     modulator urgency         0.15)
(SignalEffect user-waiting     modulator human_deference 0.10)


;; Signal→Mode overrides: (SignalMode <signal-kind> <mode>)
;;   Some signals force a mode change regardless of current dominant motive.
(SignalMode ambiguity        orient)
(SignalMode failure          verify)
(SignalMode repeated-failure recover)
(SignalMode verified-success execute)
(SignalMode task-drift       orient)


;; Directive guidance text: (DirectiveText <directive> <guidance-string>)
(DirectiveText inspect  "Inspect first. Prefer reading, querying, and narrowing the problem before broader action.")
(DirectiveText verify   "Verify first. Check consistency and avoid making multiple changes before confidence improves.")
(DirectiveText recover  "FORMAT ERROR RECOVERY: Output raw lines ONLY. NO parentheses. NO quotes. Example: send Hello")
(DirectiveText execute  "Execute normally. Advance the task directly while respecting current motivation state.")
