;; Candidate Generation Layer
;;
;; Enumerates the set of feasible candidate operations
;; given current motivational state, appraisal, and context.
;;
;; Always-available candidates:
;;   respond, retrieve-memory, search-knowledge, defer, ask-clarification
;;
;; Conditionally available (gated by current state):
;;   execute-skill   — when there is an active task
;;   learn           — when novelty or exploration_bias is high
;;   self-improve    — when failure rate is high AND risk is not excessive
;;
;; Outputs a list of candidate names for the Decision Layer.

!(bind! &candidateSpace (new-space))

(= (clearCandidates)
   (clearSpace &candidateSpace))

(= (addCandidate $name)
   (add-atom &candidateSpace (candidate $name)))

;; Return all candidate names as a list.
(= (getCandidates)
   (collapse (match &candidateSpace (candidate $name) $name)))

.
(= (taskIsActive)
   (hasContent (get-state &active-task)))

;; True when novelty appraisal or exploration_bias modulator is high.
(= (explorationCondition)
   (or (> (getAppraisalDim novelty) 0.50)
       (> (fetchModulatorValue exploration_bias) 0.50)))

;; True when failure rate is elevated but situation is not too risky.
(= (selfImproveCondition)
   (and (> (fetchSelfMetricValue failure_rate) 0.35)
        (< (getAppraisalDim risk) 0.65)))

;; True when uncertainty is high (ask-clarification already always present,
;; but this boosts its score from the decision layer).
(= (uncertaintyHigh)
   (> (getAppraisalDim uncertainty) 0.55))


;; Builds the candidate set for this cycle and returns it as a list.
(= (generateCandidates)
   (let* (
      ($_ (clearCandidates))

      ;; Always-available candidates
      ($_ (addCandidate respond))
      ($_ (addCandidate retrieve-memory))
      ($_ (addCandidate search-knowledge))
      ($_ (addCandidate defer))
      ($_ (addCandidate ask-clarification))


      ($_ (if (taskIsActive)
              (addCandidate execute-skill)
              _))

      ($_ (if (explorationCondition)
              (addCandidate learn)
              _))

      ($_ (if (selfImproveCondition)
              (addCandidate self-improve)
              _))
   )
   (getCandidates)))
