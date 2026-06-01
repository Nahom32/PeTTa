;; Appraisal Layer Ψ
;;
;; Sits between signal extraction and candidate scoring.
;; Computes 6 appraisal dimensions from active signals,
;; then uses AppraisalEffect atoms to update modulators M.
;;
;; MUST NOT directly choose actions.
;;
;; Dimensions:
;;   novelty      — how unexpected / unfamiliar the situation is
;;   risk         — probability of harm or irreversibility
;;   importance   — relevance to current goal achievement
;;   uncertainty  — ambiguity in correct response
;;   opportunity  — positive potential in the situation
;;   progress     — closeness to goal completion
;;
;; All dimensions are [0,1]; negative SignalAppraisal weights
;; can produce negative contributions which clamp to 0.

!(bind! &appraisal-space (new-space))

(= (clearAppraisal)
   (clearSpace &appraisal-space))

(= (setAppraisalDim $dim $value)
   (let* (
      ($existing (collapse (match &appraisal-space (appraisal $dim $_)
                                 (appraisal $dim $_))))
      ($_ (if (!= $existing ())
              (let ((appraisal $d $oldV) (car-atom $existing))
                 (remove-atom &appraisal-space (appraisal $dim $oldV)))
              _))
      ($_ (add-atom &appraisal-space (appraisal $dim $value)))
   ) ()))

(= (getAppraisalDim $dim)
   (let $res (collapse (match &appraisal-space (appraisal $dim $v) $v))
      (if (== $res ())
          0.0
          (car-atom $res))))

(= (getAppraisal)
   (collapse (match &appraisal-space (appraisal $dim $v)
                   (appraisal $dim $v))))


;; signalDimContrib $kind $strength $dim
;; Returns the contribution of one signal to one appraisal dimension.
(= (signalDimContrib $kind $strength $dim)
   (let $weights (collapse (match &self (SignalAppraisal $kind $dim $w) $w))
      (if (== $weights ())
          0.0
          (* $strength (car-atom $weights)))))

;; sumDimFromSignals $dim $signalList $acc
;; Recursively accumulates dimension value across a list of signal atoms.
(= (sumDimFromSignals $dim () $acc) $acc)
(= (sumDimFromSignals $dim $signals $acc)
   (let* (
      (($head $tail) (decons-atom $signals))
      ((signal $kind $strength) $head)
      ($contrib (signalDimContrib $kind $strength $dim))
   )
   (sumDimFromSignals $dim $tail (+ $acc $contrib))))

;; computeDimension $dim
;; Computes the final [0,1] value for one appraisal dimension.
(= (computeDimension $dim)
   (let $signals (getSignals)
      (clamp (sumDimFromSignals $dim $signals 0.0))))


;; runAppraisal
;; 1. Clears previous appraisal.
;; 2. Computes each of the 6 dimensions from current signals.
;; 3. Applies AppraisalEffect atoms to update modulators M.
;; 4. Returns appraisal annotation record.
(= (runAppraisal)
   (let* (
      ($_ (clearAppraisal))

      ;; Step 1 — compute 6 dimensions (each is a simple parameter call, no nesting)
      ($novelty     (computeDimension novelty))
      ($risk        (computeDimension risk))
      ($importance  (computeDimension importance))
      ($uncertainty (computeDimension uncertainty))
      ($opportunity (computeDimension opportunity))
      ($progress    (computeDimension progress))

      ;; Step 2 — store dimensions
      ($_ (setAppraisalDim novelty     $novelty))
      ($_ (setAppraisalDim risk        $risk))
      ($_ (setAppraisalDim importance  $importance))
      ($_ (setAppraisalDim uncertainty $uncertainty))
      ($_ (setAppraisalDim opportunity $opportunity))
      ($_ (setAppraisalDim progress    $progress))

      ;; Step 3 — apply AppraisalEffect → update modulators M.
      ;; Iterates over AppraisalEffect registry atoms. For each:
      ;;   adjustModulator mod (dim_value × scale)
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
