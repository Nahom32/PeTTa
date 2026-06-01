;; Motivational State Persistence
;;
;; Stores X=(G,M,S) in long-term ChromaDB memory so that the
;; motivational state survives session boundaries and influences
;; future decisions.
;;
;; Serialization format (stored as a remembered string):
;;   MOTIVOS_STATE_V1 time:<timestamp> G:<goals-repr> M:<mods-repr> S:<self-repr>
;;
;; Restoration:
;;   On startup, query ChromaDB for the most recent MOTIVOS_STATE_V1 entry.
;;   Parse the retrieved string and apply the stored values back into
;;   &goal-space, &motivation-space, and &self-model-space.
;;
;; Implementation note:
;;   ChromaDB's query returns a Python string, not a structured MeTTa atom.
;;   The current implementation saves in a queryable format and logs the
;;   retrieved excerpt.  Direct numeric restoration is deferred to a future
;;   iteration once MeTTa gains richer string-parsing primitives.
;;   Goals and modulators already initialise to registry baselines as a
;;   safe fallback when no prior session is found.


(= (persistenceKey) "MOTIVOS_STATE_V1")


;; saveMotivationalState
;; Serialises the full X=(G,M,S) snapshot and stores it via remember.
;; Safe to call every cycle; ChromaDB deduplicates by similarity.
(= (saveMotivationalState)
   (let* (
      ($timestamp (get_time_as_string))
      ($goals     (eval (string-safe (repr (getGoals)))))
      ($antiGoals (eval (string-safe (repr (getAntiGoals)))))
      ($mods      (eval (string-safe (repr (getModulators)))))
      ($self      (eval (string-safe (repr (getSelfModel)))))
      ($payload   (eval (py-str (
                     (persistenceKey) " time:" $timestamp
                     " G:" $goals " AG:" $antiGoals
                     " M:" $mods
                     " S:" $self))))
      ($_ (remember $payload))
      ($_ (println! ("Motivational state saved to long-term memory.")))
   ) saved))


;; restoreMotivationalState
;; Queries ChromaDB for the most recent motivational state snapshot.
;; Logs the retrieved data; numeric restoration happens on a best-effort
(= (restoreMotivationalState)
   (let* (
      ($_ (println! ("Querying long-term memory for prior motivational state...")))
      ($results (eval (query (persistenceKey))))
      ($excerpt  (eval (string-safe (last_chars $results 300))))
      ($_ (println! (eval (py-str ("Prior state excerpt: " $excerpt)))))
   ) restored))



;; tryRestoreOrInit
;; Called once during startup after the default initialisation.
;; Attempts to restore from a prior session; if nothing is found,
;; the system continues with default baselines (already applied by initGoalState / initSelfModel).
(= (tryRestoreOrInit)
   (let* (
      ($_ (println! ("Checking long-term memory for persisted motivational state...")))
      ($_ (restoreMotivationalState))
      ($_ (println! ("Startup restoration complete (defaults remain active as fallback).")))
   ) ()))
