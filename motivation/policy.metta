
(= (decisionScore $name $value)
   (let* (
      ;; Collect all modulator contributions for this motive
      ($contributions (collapse
         (let (ScoreWeight $name $modName $sign)
              (match &self (ScoreWeight $name $modName $sign)
                 (ScoreWeight $name $modName $sign))
           (let $modVal (fetchModulatorValue $modName)
              (if (< $sign 0.0)
                  (- 0.0 (* (- 0.0 $sign) $modVal))
                  (* $sign $modVal))))))
      ($modSum (sumList $contributions 0.0))
   )
   (+ $value $modSum)))


;; Sum a list of numbers
(= (sumList () $acc) $acc)
(= (sumList $lst $acc)
   (let* (
      (($head $tail) (decons-atom $lst))
   )
   (sumList $tail (+ $acc $head))))


;; Find the dominant motive — highest decision score among all registered motives
(= (dominantMotive)
   (let* (
      ($allMotives (collapse (match &motivation-space (motive $name $value)
                      (motive $name $value))))
   )
   (bestMotive (cdr-atom $allMotives) (car-atom $allMotives))))

(= (bestMotive $rest $best)
   (if (== $rest ())
       $best
       (let* (
          (($head $tail) (decons-atom $rest))
          ((motive $headName $headVal) $head)
          ((motive $bestName $bestVal) $best)
          ($headScore (decisionScore $headName $headVal))
          ($bestScore (decisionScore $bestName $bestVal))
       )
       (if (> $headScore $bestScore)
           (bestMotive $tail $head)
           (bestMotive $tail $best)))))


;; Select the decision based on dominant motive and DecisionMap registry
(= (selectDecision)
   (let* (
      ((motive $name $value) (dominantMotive))
      ($score (decisionScore $name $value))
      ;; Look up the decision mapping from registry
      ($mapping (collapse (match &self (DecisionMap $name $mode $directive)
                    (DecisionMap $name $mode $directive))))
      ($decision (if (== $mapping ())
                     ;; Fallback if no mapping registered
                     (decision $name orient inspect $score)
                     (let (DecisionMap $n $mode $directive) (car-atom $mapping)
                        (decision $name $mode $directive $score))))
   )
   $decision))


;; Directive guidance — fetched from DirectiveText registry atoms
(= (directiveGuidance $directive)
   (let $texts (collapse (match &self (DirectiveText $directive $text)
                   $text))
      (if (== $texts ())
          "Work normally while respecting current motivation state."
          (car-atom $texts))))
