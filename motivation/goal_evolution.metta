;; Incremental Goal Evolution
;;
;; Goals must evolve gradually. Never replace goals directly.
;;
;; Update rule:
;;   G_next = (1 - α) × G_current + α × G_proposed
;;
;; where α (learning rate) is adaptive:
;;   α = α_min + (α_max - α_min) × safety_score
;;   safety_score = gInd_over × (1 - risk) × (1 - threshold)
;;
;;   α_min = 0.01  (used when stability is threatened)
;;   α_max = 0.15  (used when conditions are fully safe)
;;
;; Proposals are derived from the current appraisal state:
;;   high risk      → strengthen gInd_over
;;   high opportunity → strengthen gTrans_over
;;   high novelty   → strengthen learn
;;   verified success → strengthen help_user, cooperate
;;   high uncertainty → strengthen learn
;;   stalled progress → no goal changes (let homeostasis handle it)


;; α bounds
(= (alphaMin) 0.01)
(= (alphaMax) 0.15)

;; Compute adaptive α from current stability indicators.
;; High gInd_over + low risk + low threshold → high α (safe to evolve faster).
(= (computeAlpha)
   (let* (
      ($gInd    (eval (fetchGoalValue gInd_over)))
      ($risk    (eval (getAppraisalDim risk)))
      ($thr     (eval (fetchModulatorValue threshold)))
      ;; safety_score ∈ [0,1]: high when stable, low when stressed
      ($safety  (* $gInd (* (- 1.0 $risk) (- 1.0 $thr))))
      ($alpha   (+ (alphaMin) (* (- (alphaMax) (alphaMin)) $safety)))
   )
   (clamp $alpha)))


;; evolveGoal — blends proposed value with current value using α.
;; Returns (goal name new_value).
(= (evolveGoal $name $proposed)
   (let* (
      ($current (eval (fetchGoalValue $name)))
      ($alpha   (eval (computeAlpha)))
      ($new     (eval (clamp (+ (* (- 1.0 $alpha) $current)
                          (* $alpha $proposed)))))
      ($_ (eval (replaceGoal $name $new)))
   )
   (goal $name $new)))



;; Compute a proposed value for a single goal based on the current appraisal.
;; The proposal is the current value ± a small appraisal-driven delta.
;; The actual evolution step will α-blend this with the current value,
;; so the net change per cycle is small.
(= (proposedGoalValue $name)
   (let* (
      ($current   (eval (fetchGoalValue $name)))
      ($risk      (eval (getAppraisalDim risk)))
      ($opp       (eval (getAppraisalDim opportunity)))
      ($novelty   (eval (getAppraisalDim novelty)))
      ($progress  (eval (getAppraisalDim progress)))
      ($uncertainty (eval (getAppraisalDim uncertainty)))
      ;; Check for specific positive signal
      ($hasSuccess (let $s (collapse (match &signal-space (signal verified-success $_) yes))
                      (if (== $s ()) False True)))
      ;; Per-goal proposal logic
      ($delta (case $name (
         ;; Stability goal: strengthen when risk is high
         ((gInd_over)
          (* $risk 0.12))

         ;; Transcendence goal: strengthen with opportunity, weaken with high risk
         ((gTrans_over)
          (- (* $opp 0.10) (* $risk 0.05)))

         ;; Help user: reward with success signal, penalise with risk
         ((help_user)
          (if $hasSuccess (* $progress 0.06) (* $risk -0.03)))

         ;; Learn: driven by novelty and uncertainty
         ((learn)
          (* (+ $novelty $uncertainty) 0.05))

         ;; Cooperate: rises with progress (things are working well together)
         ((cooperate)
          (* $progress 0.04))

         ;; For any unrecognised name: no change
         ($_ 0.0)
      )))
   )
   (clamp (+ $current $delta))))



;; Applies proposedGoalValue + α-blending to every GoalSpec goal.
(= (evolveGoalState)
   (let* (
      ($_ (println! ("Running goal evolution...")))
      ($updates (collapse
         (let (GoalSpec $name $_b)
              (match &self (GoalSpec $name $_b) (GoalSpec $name $_b))
           (evolveGoal $name (proposedGoalValue $name)))))
      ($_ (println! (eval (py-str ("Goal updates: " (repr $updates))))))
   )
   $updates))
