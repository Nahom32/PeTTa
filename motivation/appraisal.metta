;; Appraisal Layer Ψ
;;
;; Sits between signal extraction and candidate scoring.
;; Computes 6 appraisal dimensions from active signals,
;; then uses AppraisalEffect atoms to update modulators M.

;; Dimensions:
;;   novelty      — how unexpected / unfamiliar the situation is
;;   risk         — probability of harm or irreversibility
;;   importance   — relevance to current goal achievement
;;   uncertainty  — ambiguity in correct response
;;   opportunity  — positive potential in the situation
;;   progress     — closeness to goal completion

!(bind! &appraisalSpace (new-space))

(= (clearAppraisal)
   (clearSpace &appraisalSpace))

(= (update-atom $space $oatom $natom) (let $_ (remove-atom $space $oatom) (add-atom $space $natom)))

;; Store a dimension value, replacing any existing entry.
(= (setAppraisalDim $dim $value)
   (let $_ (update-atom &appraisalSpace (appraisal $dim $value) (appraisal $dim $value)) 
   ()
))

;; Fetch a dimension value; returns 0.0 if not computed yet
(= (getAppraisalDim $dim)
   (let $res (collapse (match &appraisalSpace (appraisal $dim $v) $v))
      (if (== $res ())
          0.0
          (car-atom $res))))

;; Get full appraisal record as a list
(= (getAppraisal)
   (collapse (match &appraisalSpace (appraisal $dim $v)
                   (appraisal $dim $v))))

;; Compute one appraisal dimension by summing
;; (signal_strength × SignalAppraisal_weight) over all active signals.
(= (computeDimension $dim)
   (let* (
      ($contributions (collapse
         (let (signal $kind $strength)
              (match &signalSpace (signal $kind $strength)
                                   (signal $kind $strength))
            (let $weightRes (collapse (match &self
                              (SignalAppraisal $kind $dim $w)
                              $w))
               (if (== $weightRes ())
                   (empty)
                   (* $strength (car-atom $weightRes)))))))
   )
   (eval (clamp (sumList $contributions 0.0)))))

;; runAppraisal
;; 1. Clears previous appraisal annotations.
;; 2. Computes each of the 6 dimensions from current signals.
;; 3. Applies AppraisalEffect atoms to update modulators M.
;; 4. Returns appraisal annotation record.
(= (runAppraisal)
   (let* (
      ($_ (clearAppraisal))

      ;; compute dimensions
      ($novelty     (computeDimension novelty))
      ($risk        (computeDimension risk))
      ($importance  (computeDimension importance))
      ($uncertainty (computeDimension uncertainty))
      ($opportunity (computeDimension opportunity))
      ($progress    (computeDimension progress))

      ;; store dimensions
      ($_ (setAppraisalDim novelty     $novelty))
      ($_ (setAppraisalDim risk        $risk))
      ($_ (setAppraisalDim importance  $importance))
      ($_ (setAppraisalDim uncertainty $uncertainty))
      ($_ (setAppraisalDim opportunity $opportunity))
      ($_ (setAppraisalDim progress    $progress))

      ;; apply AppraisalEffect → update modulators M
      ;;   For each (AppraisalEffect dim mod scale): adjustModulator mod (dim_val × scale)
      ($_ (collapse
            (let (AppraisalEffect $dim $mod $scale)
                 (match &self (AppraisalEffect $dim $mod $scale)
                              (AppraisalEffect $dim $mod $scale))
               (let $dimVal (getAppraisalDim $dim)
                  (adjustModulator $mod (* $scale $dimVal))))))
   )
   
   (appraisal
      (novelty     $novelty)
      (risk        $risk)
      (importance  $importance)
      (uncertainty $uncertainty)
      (opportunity $opportunity)
      (progress    $progress))))
