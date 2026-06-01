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


;; GOAL VECTOR — G (over-arching + domain goals + anti-goals)

;; (GoalSpec <name> <baseline>)
;;   gInd_over  — stability / self-preservation (always-on, high baseline)
;;   gTrans_over — growth / exploration / transcendence (moderate baseline)
(GoalSpec gInd_over   0.70)
(GoalSpec gTrans_over 0.40)

;; Domain goals
(GoalSpec help_user   0.60)
(GoalSpec learn       0.45)
(GoalSpec cooperate   0.50)

;; Anti-goals: penalty weight applied to candidates that raise these risks.
;; (AntiGoalSpec <name> <penalty-weight>)
(AntiGoalSpec risk          0.10)
(AntiGoalSpec contradiction 0.10)
(AntiGoalSpec unsafe        0.05)


;; ADDITIONAL MODULATORS — M (PSI theory extensions)

;; arousal   — activity / exploration intensity       (PSI: activation level)
;; valence   — positive/negative appraisal register
;; threshold — conservativeness required before acting (PSI: selection threshold)
;; securing  — safety / caution bias                  (PSI: safety valence)
;; focus     — concentration on current goal
(ModulatorSpec arousal    0.50)
(ModulatorSpec valence    0.50)
(ModulatorSpec threshold  0.40)
(ModulatorSpec securing   0.30)
(ModulatorSpec focus      0.55)


;; SELF MODEL — S (performance & identity metrics)

;; (SelfModelSpec <name> <baseline>)
(SelfModelSpec success_rate        0.50)
(SelfModelSpec failure_rate        0.10)
(SelfModelSpec resource_usage      0.30)
(SelfModelSpec memory_confidence   0.70)
(SelfModelSpec identity_continuity 0.90)


;; CANDIDATE OPERATIONS

;; (CandidateSpec <name> <type>)
;;   type ∈ { execution | knowledge | growth | safety }
(CandidateSpec respond           execution)
(CandidateSpec retrieve-memory   knowledge)
(CandidateSpec search-knowledge  knowledge)
(CandidateSpec execute-skill     execution)
(CandidateSpec learn             growth)
(CandidateSpec self-improve      growth)
(CandidateSpec defer             safety)
(CandidateSpec ask-clarification safety)

;; Candidate → Goal/Motive alignment weights
;; (CandidateGoalAlignment <candidate> <goal-or-motive> <weight>)
(CandidateGoalAlignment respond           help_user       0.90)
(CandidateGoalAlignment respond           responsiveness  0.80)
(CandidateGoalAlignment respond           cooperate       0.50)
(CandidateGoalAlignment retrieve-memory   clarity         0.80)
(CandidateGoalAlignment retrieve-memory   coherence       0.60)
(CandidateGoalAlignment retrieve-memory   learn           0.40)
(CandidateGoalAlignment search-knowledge  clarity         0.70)
(CandidateGoalAlignment search-knowledge  learn           0.70)
(CandidateGoalAlignment search-knowledge  gTrans_over     0.40)
(CandidateGoalAlignment execute-skill     progress        0.85)
(CandidateGoalAlignment execute-skill     help_user       0.70)
(CandidateGoalAlignment execute-skill     responsiveness  0.60)
(CandidateGoalAlignment learn             learn           0.90)
(CandidateGoalAlignment learn             gTrans_over     0.80)
(CandidateGoalAlignment learn             adaptivity      0.50)
(CandidateGoalAlignment self-improve      gTrans_over     0.85)
(CandidateGoalAlignment self-improve      adaptivity      0.70)
(CandidateGoalAlignment self-improve      learn           0.60)
(CandidateGoalAlignment defer             gInd_over       0.80)
(CandidateGoalAlignment defer             reliability     0.60)
(CandidateGoalAlignment ask-clarification clarity         0.85)
(CandidateGoalAlignment ask-clarification help_user       0.60)
(CandidateGoalAlignment ask-clarification coherence       0.50)

;; Candidate risk factors [0,1] — used in stability and risk penalties
;; (CandidateRiskFactor <candidate> <risk>)
(CandidateRiskFactor respond           0.10)
(CandidateRiskFactor retrieve-memory   0.05)
(CandidateRiskFactor search-knowledge  0.05)
(CandidateRiskFactor execute-skill     0.40)
(CandidateRiskFactor learn             0.15)
(CandidateRiskFactor self-improve      0.65)
(CandidateRiskFactor defer             0.02)
(CandidateRiskFactor ask-clarification 0.02)

;; Candidate type → modulator weight links
;; (CandidateTypeModulator <type> <modulator> <sign>)
;;   sign > 0 means modulator boosts this candidate type's score
;;   sign < 0 means modulator suppresses it
(CandidateTypeModulator execution  urgency           1.0)
(CandidateTypeModulator execution  persistence       0.5)
(CandidateTypeModulator execution  threshold        -0.5)
(CandidateTypeModulator knowledge  context_depth     1.0)
(CandidateTypeModulator knowledge  caution           0.5)
(CandidateTypeModulator knowledge  urgency          -0.3)
(CandidateTypeModulator growth     exploration_bias  1.0)
(CandidateTypeModulator growth     arousal           0.5)
(CandidateTypeModulator growth     persistence      -0.5)
(CandidateTypeModulator safety     securing          1.0)
(CandidateTypeModulator safety     threshold         0.5)
(CandidateTypeModulator safety     caution           0.5)

;; Candidate → Decision output: maps winning candidate to behavioral mode + directive
;; (CandidateDecisionMap <candidate> <mode> <directive>)
(CandidateDecisionMap respond           execute  execute)
(CandidateDecisionMap retrieve-memory   orient   inspect)
(CandidateDecisionMap search-knowledge  orient   inspect)
(CandidateDecisionMap execute-skill     execute  execute)
(CandidateDecisionMap learn             orient   inspect)
(CandidateDecisionMap self-improve      recover  recover)
(CandidateDecisionMap defer             verify   verify)
(CandidateDecisionMap ask-clarification orient   inspect)


;; APPRAISAL LAYER — signal → dimension mappings

;; (SignalAppraisal <signal-kind> <dimension> <weight>)
;;   dimension ∈ { novelty | risk | importance | uncertainty | opportunity | progress }
;;   Appraisal dimension value = Σ (signal_strength × weight)  clamped to [0,1]
(SignalAppraisal failure           risk          0.70)
(SignalAppraisal failure           importance    0.50)
(SignalAppraisal failure           uncertainty   0.40)
(SignalAppraisal failure           progress     -0.30)
(SignalAppraisal repeated-failure  risk          0.85)
(SignalAppraisal repeated-failure  importance    0.70)
(SignalAppraisal repeated-failure  uncertainty   0.60)
(SignalAppraisal repeated-failure  progress     -0.50)
(SignalAppraisal ambiguity         uncertainty   0.60)
(SignalAppraisal ambiguity         importance    0.40)
(SignalAppraisal ambiguity         novelty       0.30)
(SignalAppraisal verified-success  progress      0.70)
(SignalAppraisal verified-success  opportunity   0.50)
(SignalAppraisal verified-success  risk         -0.30)
(SignalAppraisal progress-made     progress      0.45)
(SignalAppraisal progress-made     opportunity   0.30)
(SignalAppraisal stalled-progress  progress     -0.20)
(SignalAppraisal stalled-progress  importance    0.50)
(SignalAppraisal user-waiting      importance    0.60)
(SignalAppraisal task-drift        novelty       0.60)
(SignalAppraisal task-drift        uncertainty   0.40)


;; Appraisal dimension → Modulator update effects
;; (AppraisalEffect <dimension> <modulator> <delta-scale>)
;;   Effect = dimension_value × delta-scale  added to modulator (then clamped)
(AppraisalEffect novelty      arousal           0.30)
(AppraisalEffect novelty      exploration_bias  0.20)
(AppraisalEffect novelty      focus            -0.10)
(AppraisalEffect risk         securing          0.40)
(AppraisalEffect risk         threshold         0.35)
(AppraisalEffect risk         arousal          -0.20)
(AppraisalEffect importance   urgency           0.30)
(AppraisalEffect importance   focus             0.25)
(AppraisalEffect uncertainty  threshold         0.25)
(AppraisalEffect uncertainty  caution           0.20)
(AppraisalEffect uncertainty  arousal          -0.10)
(AppraisalEffect opportunity  arousal           0.25)
(AppraisalEffect opportunity  valence           0.30)
(AppraisalEffect opportunity  exploration_bias  0.15)
(AppraisalEffect progress     valence           0.35)
(AppraisalEffect progress     persistence       0.15)
(AppraisalEffect progress     urgency          -0.10)


;; HOMEOSTATIC GOVERNANCE RULES

;; (HomeostaticRule <condition-type> <metric-name> <threshold>
;;                  <action-type> <target> <delta>)
;;
;;   condition-type: modulator-exceeds | self-metric-below
;;   action-type:    raise-modulator | lower-modulator | raise-goal | lower-goal
;;
;; Rule fires when: condition-type(metric-name) crosses threshold.
;; Action: adjusts target by ±delta.

;; Excessive securing → raise threshold, dampen exploration and arousal
(HomeostaticRule modulator-exceeds  securing            0.75 raise-modulator threshold         0.25)
(HomeostaticRule modulator-exceeds  securing            0.75 lower-modulator arousal           0.20)
(HomeostaticRule modulator-exceeds  securing            0.75 lower-modulator exploration_bias  0.20)

;; Excessive caution → dampen exploration
(HomeostaticRule modulator-exceeds  caution             0.80 lower-modulator exploration_bias  0.15)

;; Low memory confidence → raise threshold, lower persistence (don't persist on bad info)
(HomeostaticRule self-metric-below  memory_confidence   0.20 raise-modulator threshold         0.20)
(HomeostaticRule self-metric-below  memory_confidence   0.20 lower-modulator persistence       0.15)

;; Low success rate → raise caution, dampen growth goal
(HomeostaticRule self-metric-below  success_rate        0.15 raise-modulator caution           0.20)
(HomeostaticRule self-metric-below  success_rate        0.15 lower-goal      gTrans_over       0.05)

;; Low identity continuity → strengthen stability goal and securing
(HomeostaticRule self-metric-below  identity_continuity 0.30 raise-goal      gInd_over         0.05)
(HomeostaticRule self-metric-below  identity_continuity 0.30 raise-modulator securing          0.10)
