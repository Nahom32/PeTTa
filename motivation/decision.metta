;; Motivational Decision Layer D
;;
;; Scores every candidate operation using the full formula:
;;
;;   score(c) = goal_alignment(c)
;;            × modulator_effects(c)
;;            × (1 + transcendence_bonus(c))
;;            − stability_penalty(c)
;;            − risk_penalty(c)
;;
;; where:
;;   goal_alignment(c)       = Σ CandidateGoalAlignment(c,g,w) × goalValue(g)
;;   modulator_effects(c)    = Σ CandidateTypeModulator(type,m,s) × modulatorValue(m)
;;   transcendence_bonus(c)  = gTrans_over × 0.30  (only for growth-type candidates)
;;   stability_penalty(c)    = gInd_over × securing × CandidateRiskFactor(c)
;;   risk_penalty(c)         = threshold × CandidateRiskFactor(c)
;;
;; The winning candidate determines the behavioral mode and directive
;; injected into the LLM prompt.  LLM reasoning generates options/
;; explanations; the motivational state determines which option is pursued.



;; Floor helper (avoids zero-product collapse)
(= (floor01 $x)
   (if (< $x 0.01) 0.01 $x))


;; goal_alignment: dot product of candidate's goal-contribution vector with G∪M.
(= (computeGoalAlignment $cand)
   (let $contributions (collapse
         (let (CandidateGoalAlignment $cand $goal $weight)
              (match &self (CandidateGoalAlignment $cand $goal $weight)
                           (CandidateGoalAlignment $cand $goal $weight))
           (* $weight (fetchGoalOrMotiveValue $goal))))
   (sumList $contributions 0.0)))

;; modulator_effects: weighted sum of modulator values for the candidate's type.
(= (computeModulatorEffects $cand)
   (let* (
      ;; Look up the candidate's type from registry
      ($typeList (collapse (match &self (CandidateSpec $cand $t) $t)))
      ($type (if (== $typeList ()) execution (car-atom $typeList)))
      
      ($contributions (collapse
         (let (CandidateTypeModulator $type $mod $sign)
              (match &self (CandidateTypeModulator $type $mod $sign)
                           (CandidateTypeModulator $type $mod $sign))
           (let $modVal (fetchModulatorValue $mod)
              (if (< $sign 0.0)
                  (- 0.0 (* (- 0.0 $sign) $modVal))
                  (* $sign $modVal))))))
   )
   (eval (sumList $contributions 0.0))))

;; transcendence_bonus: gTrans_over reward for growth-type candidates.
(= (computeTranscendenceBonus $cand)
   (let* (
      ($typeList (collapse (match &self (CandidateSpec $cand $t) $t)))
      ($type     (if (== $typeList ()) execution (car-atom $typeList)))
   )
   (if (== $type growth)
       (* (fetchGoalValue gTrans_over) 0.30)
       0.0)))

;; stability_penalty: gInd_over × securing × risk factor.
;; High when the agent values stability AND securing is raised AND candidate is risky.
(= (computeStabilityPenalty $cand)
   (let* (
      ($rfList (collapse (match &self (CandidateRiskFactor $cand $r) $r)))
      ($rf     (if (== $rfList ()) 0.0 (car-atom $rfList)))
      ($gInd   (fetchGoalValue gInd_over))
      ($sec    (fetchModulatorValue securing))
   )
   (* $rf (* $gInd $sec))))

;; risk_penalty: threshold × risk factor.
;; Discourages risky candidates when the agent is in a conservative state.
(= (computeRiskPenalty $cand)
   (let* (
      ($rfList (collapse (match &self (CandidateRiskFactor $cand $r) $r)))
      ($rf     (if (== $rfList ()) 0.0 (car-atom $rfList)))
      ($thr    (fetchModulatorValue threshold))
   )
   (* $rf $thr)))



;; scoreCandidate — returns (scored-candidate <name> <score>)
(= (scoreCandidate $cand)
   (let* (
      ($ga   (computeGoalAlignment $cand))
      ($me   (computeModulatorEffects $cand))
      ($tb   (computeTranscendenceBonus $cand))
      ($sp   (computeStabilityPenalty $cand))
      ($rp   (computeRiskPenalty $cand))
      
      ($pos  (* (floor01 $ga) (* (floor01 $me) (+ 1.0 $tb))))
      ($score (clamp (- $pos (+ $sp $rp))))
   )
   (scored-candidate $cand $score)))



;; Compare two scored candidates; return the higher-scoring one.
(= (betterCandidate $a $b)
   (let* (
      ((scored-candidate $na $sa) $a)
      ((scored-candidate $nb $sb) $b)
   )
   (if (> $sa $sb) $a $b)))

;; Recursively find the best-scoring candidate from a list.
(= (selectBestCandidate $candidates)
   (if (== $candidates ())
       ;; Fallback: always safe to respond
       (scoreCandidate respond)
       (bestFromList (cdr-atom $candidates)
                     (scoreCandidate (car-atom $candidates)))))

(= (bestFromList $rest $best)
   (if (== $rest ())
       $best
       (let* (
          (($head $tail) (decons-atom $rest))
          ($scored (scoreCandidate $head))
       )
       (bestFromList $tail (betterCandidate $best $scored)))))



;; Returns a list of (scored-candidate name score) for every CandidateSpec,
;; regardless of whether they were generated this cycle.
(= (scoreAllCandidates)
   (collapse (let (CandidateSpec $cand $_type)
                  (match &self (CandidateSpec $cand $_type)
                               (CandidateSpec $cand $_type))
               (scoreCandidate $cand))))


;; motivationalDecision
;;   1. Generates the candidate set.
;;   2. Scores each candidate with the full formula.
;;   3. Selects the winner.
;;   4. Looks up its mode + directive from CandidateDecisionMap.
;;   5. Updates &last-motivation-decision and replaces the mode.
;;   6. Returns (motivational-result decision all-scores).

(= (motivationalDecision)
   (let* (
      ($candidates  (generateCandidates))
      ($best        (selectBestCandidate $candidates))
      ($allScores   (scoreAllCandidates))
      ((scored-candidate $name $score) $best)

      ;; Look up mode + directive from registry
      ($mapList (collapse (match &self (CandidateDecisionMap $name $mode $directive)
                              (CandidateDecisionMap $name $mode $directive))))
      ($mode    (if (== $mapList ())
                    orient
                    (let (CandidateDecisionMap $_ $m $_) (car-atom $mapList) $m)))
      ($dir     (if (== $mapList ())
                    inspect
                    (let (CandidateDecisionMap $_ $_ $d) (car-atom $mapList) $d)))

      ;; Build decision atom (compatible with existing bridge format)
      ($decision (decision $name $mode $dir $score))

      ;; Persist decision and update mode
      ($_ (change-state! &last-motivation-decision $decision))
      ($_ (replaceMode $mode))

      ($_ (println! (eval (py-str ("Motivational decision: " (repr $decision))))))
   )
   (motivational-result $decision $allScores)))
