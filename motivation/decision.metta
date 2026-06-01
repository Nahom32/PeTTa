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

;; scoreAllCandidates (which reads CandidateSpec atoms from &self —
;; reliably available in all PeTTa evaluation contexts).
;;
;; generateCandidates is retained for auditing and context injection
;; but is NO LONGER in the critical selection path.  The scoring
;; formula already encodes situational appropriateness:
;;   • low urgency / no active task   → execution-type candidates score lower
;;   • high securing / risk           → safety-type candidates score higher
;;   • high novelty / exploration     → growth-type candidates score higher



(= (floor01 $x)
   (if (< $x 0.01) 0.01 $x))


;; --- Component scorers ---

(= (computeGoalAlignment $cand)
   (let $contributions (collapse
         (let (CandidateGoalAlignment $cand $goal $weight)
              (match &self (CandidateGoalAlignment $cand $goal $weight)
                           (CandidateGoalAlignment $cand $goal $weight))
           (* $weight (fetchGoalOrMotiveValue $goal))))
   (sumList $contributions 0.0)))

(= (computeModulatorEffects $cand)
   (let* (
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
   (sumList $contributions 0.0)))

(= (computeTranscendenceBonus $cand)
   (let* (
      ($typeList (collapse (match &self (CandidateSpec $cand $t) $t)))
      ($type     (if (== $typeList ()) execution (car-atom $typeList)))
   )
   (if (== $type growth)
       (* (fetchGoalValue gTrans_over) 0.30)
       0.0)))

(= (computeStabilityPenalty $cand)
   (let* (
      ($rfList (collapse (match &self (CandidateRiskFactor $cand $r) $r)))
      ($rf     (if (== $rfList ()) 0.0 (car-atom $rfList)))
      ($gInd   (fetchGoalValue gInd_over))
      ($sec    (fetchModulatorValue securing))
   )
   (* $rf (* $gInd $sec))))

(= (computeRiskPenalty $cand)
   (let* (
      ($rfList (collapse (match &self (CandidateRiskFactor $cand $r) $r)))
      ($rf     (if (== $rfList ()) 0.0 (car-atom $rfList)))
      ($thr    (fetchModulatorValue threshold))
   )
   (* $rf $thr)))

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


;; --- Scoring all registered candidates ---

;; scoreAllCandidates reads CandidateSpec atoms from &self (global space).
;; This is the reliable path — always works regardless of &candidate-space state.
(= (scoreAllCandidates)
   (collapse (let (CandidateSpec $cand $_type)
                  (match &self (CandidateSpec $cand $_type)
                               (CandidateSpec $cand $_type))
               (scoreCandidate $cand))))



;; foldScoredList: left-fold over a scored-candidate list, keeping highest score.
(= (foldScoredList () $best) $best)
(= (foldScoredList $lst $best)
   (let* (
      (($head $tail) (decons-atom $lst))
      ((scored-candidate $hn $hs) $head)
      ((scored-candidate $bn $bs) $best)
      ($nextBest (if (> $hs $bs) $head $best))
   )
   (foldScoredList $tail $nextBest)))


;; --- Top-level motivational decision (v3) ---

;; motivationalDecision
;;   1. Scores ALL registered candidates via scoreAllCandidates (reads &self).
;;   2. Folds to find the winner with the highest score.
;;   3. Calls generateCandidates for auditing / context injection only.
;;   4. Looks up mode + directive from CandidateDecisionMap.
;;   5. Updates &last-motivation-decision and replaces mode.
;;   6. Returns (motivational-result decision all-scores).
(= (motivationalDecision)
   (let* (
      ;; Step 1: score all registered candidates (reliable path via &self)
      ($allScores (scoreAllCandidates))

      ;; Step 2: find the best-scoring candidate
      ($initBest  (scored-candidate respond 0.0))
      ($best      (foldScoredList $allScores $initBest))
      ((scored-candidate $name $score) $best)

      ;; Step 3: generate candidate set for auditing / context injection
      ;; (side-effect only; does not affect selection above)
      ($_ (generateCandidates))

      ;; Step 4: look up mode + directive from registry
      ($mapList (collapse (match &self (CandidateDecisionMap $name $mode $directive)
                              (CandidateDecisionMap $name $mode $directive))))
      ($mode    (if (== $mapList ())
                    orient
                    (let (CandidateDecisionMap $_ $m $_d) (car-atom $mapList) $m)))
      ($dir     (if (== $mapList ())
                    inspect
                    (let (CandidateDecisionMap $_ $_m $d) (car-atom $mapList) $d)))

      ($decision (decision $name $mode $dir $score))

      ($_ (change-state! &last-motivation-decision $decision))
      ($_ (replaceMode $mode))

      ($_ (println! (eval (py-str ("Motivational decision: " (repr $decision))))))
   )
   (motivational-result $decision $allScores)))
