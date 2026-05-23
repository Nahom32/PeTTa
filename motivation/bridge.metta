;; bridge.metta — Integration hooks into OmegaClaw's loop.
;; This file overrides OmegaClaw's `getContext` to inject motivation data



;; motivationContextBlock
;; Run the full motivation cycle and produce a text block for the LLM prompt.
(= (motivationContextBlock)
   (let* (
      ($_ (refreshSignals))
      ($_ (runMotivationUpdate))
      ($decision (selectDecision))
      ($_ (println! ("Selected Decision: " $decision)))
      ((decision $motive $mode $directive $score) $decision)
      ($_ (change-state! &last-motivation-decision $decision))
      ($_ (replaceMode $mode))
      ($signals   (eval (string-safe (repr (getSignals)))))
      ($snapshot  (eval (string-safe (repr (motivationSnapshot)))))
      ($decisionText (eval (string-safe (repr $decision))))
      ($guidance  (directiveGuidance $directive))
   )
   (eval (py-str (
      " MOTIVATION_SIGNALS: " $signals
      " MOTIVATION_STATE: " $snapshot
      " MOTIVATION_DECISION: " $decisionText
      " STEP_POLICY: " $guidance)))))


;; getContext override 
;; extends OmegaClaw's context with motivation data
(= (getContext)
   (let* (
      ($motivationText (motivationContextBlock))
   )
   (eval (string-safe
      (eval (py-str (
               "PROMPT: " (eval (getPrompt))
               " SKILLS: " (eval (getSkills))
               " OUTPUT_FORMAT: Output up to 5 raw lines. NO parentheses. NO quotes around arguments. NO conversational text."
               " Example format:" (newline)
               " skillName1 arg1" (newline)
               " skillName2 arg2"
               " LAST_SKILL_USE_RESULTS: " (eval (last_chars (get-state &lastresults) (maxFeedback)))
               " HISTORY: " (eval (getHistory))
               " TIME: " (eval (get_time_as_string))
               " MOTIVATION: " $motivationText
               )))))))


;; Entry point: initialize motivation, then start OmegaClaw's loop
(= (motivatedOmegaclaw)
   (let* (
      ($_ (initMotivationState))
      ($_ (collapse (clearSignals)))
   )
   (eval (omegaclaw))))