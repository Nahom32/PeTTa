;; MotivOS integration into OmegaClaw's loop.

;; Full pipeline (run once per cycle, inside getContext):
;;
;;   1. refreshSignals        — extract signals from OmegaClaw state
;;   2. runAppraisal          — 6-dim appraisal → update M
;;   3. runMotivationUpdate   — decay all G/M toward baselines + apply signal effects
;;   4. decayGoalState        — decay G toward baselines (same homeostatic law)
;;   5. runHomeostasis        — safety circuit-breaker on M and G
;;   6. motivationalDecision  — score candidates, select winner
;;   7. evolveGoalState       — α-blend G toward appraisal-driven proposals
;;   8. updateSelfModel       — update S from cycle outcome
;;   9. saveMotivationalState — persist X to long-term memory
;;  10. Build context block   — inject into LLM prompt



;; motivationContextBlock
;; Run the full motivation cycle and produce a text block for the LLM prompt.
(= (motivationContextBlock)
   (let* (
      ($signals (refreshSignals))
      ($appraisalRec (runAppraisal))

      ($_ (runMotivationUpdate))
      ($_ (decayGoalState))

      ($homeoFired (runHomeostasis))
      ($motResult (motivationalDecision))
      ((motivational-result $decision $allScores) $motResult)
      ((decision $selectedCand $mode $directive $score) $decision)

      ($_ (evolveGoalState))

      ($hasError   (> (eval (string_length (eval (string-safe (repr (get-state &error)))))) 4))
      ($hasResults (hasContent (get-state &lastresults)))
      ($_ (updateSelfModel $hasError $hasResults))

      ($_ (saveMotivationalState))

      ($signalsStr    (eval (string-safe (repr $signals))))
      ($appraisalStr  (eval (string-safe (repr $appraisalRec))))
      ($goalStr       (eval (string-safe (repr (getGoals)))))
      ($antiGoalStr   (eval (string-safe (repr (getAntiGoals)))))
      ($modulatorStr  (eval (string-safe (repr (getModulators)))))
      ($selfModelStr  (eval (string-safe (repr (getSelfModel)))))
      ($scoresStr     (eval (string-safe (repr $allScores))))
      ($decisionStr   (eval (string-safe (repr $decision))))
      ($guidance      (directiveGuidance $directive))
   )
   (eval (py-str (
      " MOTIVATION_SIGNALS: "   $signalsStr
      " APPRAISAL: "            $appraisalStr
      " GOAL_STATE: "           $goalStr
      " ANTI_GOALS: "           $antiGoalStr
      " MODULATOR_STATE: "      $modulatorStr
      " SELF_MODEL: "           $selfModelStr
      " CANDIDATE_SCORES: "     $scoresStr
      " MOTIVATION_DECISION: "  $decisionStr
      " STEP_POLICY: "          $guidance)))))



;; Extends OmegaClaw's standard context with the full Motive sys block.
;; LLM sees the scored candidates and selected action; it generates
(= (getContext)
   (let* (
      ($motivationText (motivationContextBlock))
   )
   (eval (string-safe
      (eval (py-str (
         "PROMPT: "                  (eval (getPrompt))
         " SKILLS: "                 (eval (getSkills))
         " OUTPUT_FORMAT: Output up to 5 raw lines. NO parentheses. NO quotes around arguments. NO conversational text."
         " Example format:"          (newline)
         " skillName1 arg1"          (newline)
         " skillName2 arg2"
         " LAST_SKILL_USE_RESULTS: " (eval (last_chars (get-state &lastresults) (maxFeedback)))
         " HISTORY: "                (eval (getHistory))
         " TIME: "                   (eval (get_time_as_string))
         " MOTIVATION: "             $motivationText
         )))))))


;; Entry point: initialize motivation, then start OmegaClaw's loop
(= (motivatedOmegaclaw)
   (let* (
      ($_ (initMotivationState))
      ($_ (initGoalState))
      ($_ (initSelfModel))
      ($_ (collapse (clearSignals)))
      
      ; ($_ (tryRestoreOrInit))
   )
   (eval (omegaclaw))))