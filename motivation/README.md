# MotivOS — Motivational Operating System for OmegaClaw

A full MetaMo-inspired motivational operating system that sits **between appraisal and skill/action selection**. The LLM generates options and explanations; the motivational state determines which option is pursued.

---

## Architecture

```
motivation/
├── registry.metta        ← ALL declarative specs (edit here to extend)
├── state.metta           ← State spaces and CRUD for G, M, S
├── signals.metta         ← Signal extraction from OmegaClaw loop state
├── dynamics.metta        ← Decay, adjustment, self-model update
├── policy.metta          ← Legacy motive-based decision (backward compat)
├── appraisal.metta       ← Appraisal Layer Ψ (6 dimensions → M updates)
├── candidates.metta      ← Candidate Generation (feasible operations)
├── decision.metta        ← Motivational Decision Layer D (scoring)
├── homeostasis.metta     ← Homeostatic Governance (safety circuit-breaker)
├── goal_evolution.metta  ← Incremental Goal Evolution (α-blending)
├── persistence.metta     ← Session persistence via ChromaDB
└── bridge.metta          ← Full 9-step pipeline + getContext override
```

---

## State Model: X = (G, M, S)

### G — Goal State

| Category | Name | Baseline | Description |
|---|---|---|---|
| Over-arching | `gInd_over` | 0.70 | Stability / self-preservation |
| Over-arching | `gTrans_over` | 0.40 | Growth / exploration / transcendence |
| Domain | `help_user` | 0.60 | User assistance |
| Domain | `learn` | 0.45 | Knowledge acquisition |
| Domain | `cooperate` | 0.50 | Multi-agent alignment |
| Anti-goal | `risk` | 0.10 | Penalise risky candidates |
| Anti-goal | `contradiction` | 0.10 | Penalise incoherent candidates |
| Anti-goal | `unsafe` | 0.05 | Penalise unsafe candidates |

Goals **decay toward their baselines** each cycle (same homeostatic law as motives).
Goals **evolve incrementally** via `G_next = (1-α)G + αG_proposed`.

### M — Generic Modulator State

| Name | Baseline | PSI Theory Mapping |
|---|---|---|
| `urgency` | 0.50 | Time pressure / activation |
| `caution` | 0.50 | Risk aversion |
| `persistence` | 0.55 | Strategy persistence |
| `exploration_bias` | 0.40 | Novelty seeking |
| `context_depth` | 0.50 | Reasoning depth |
| `human_deference` | 0.40 | Weight on human input |
| `arousal` | 0.50 | Activation level (PSI) |
| `valence` | 0.50 | Positive/negative register |
| `threshold` | 0.40 | Selection threshold (PSI) |
| `securing` | 0.30 | Safety valence (PSI) |
| `focus` | 0.55 | Goal concentration |

### S — Self Model

| Name | Baseline | Description |
|---|---|---|
| `success_rate` | 0.50 | Rolling EMA of success rate |
| `failure_rate` | 0.10 | Rolling EMA of failure rate |
| `resource_usage` | 0.30 | Proxy from cycle count |
| `memory_confidence` | 0.70 | Approximated from success rate |
| `identity_continuity` | 0.90 | Degrades with failure streak |

---

## Pipeline (one cycle)

```
refreshSignals
    ↓
runAppraisal          — 6 dimensions (novelty, risk, importance,
    ↓                   uncertainty, opportunity, progress) → M updates
runMotivationUpdate   — decay M + apply SignalEffect atoms
    ↓
decayGoalState        — decay G toward GoalSpec baselines
    ↓
runHomeostasis        — fire HomeostaticRule atoms if triggered
    ↓
motivationalDecision  — score candidates, select winner
    ↓                   score = goal_alignment × modulator_effects
    ↓                          × (1 + transcendence_bonus)
    ↓                          − stability_penalty − risk_penalty
evolveGoalState       — G_next = (1-α)G + αG_proposed
    ↓
updateSelfModel       — update S (EMA of success/failure rates)
    ↓
saveMotivationalState — persist X to ChromaDB
    ↓
inject into LLM prompt
```

---

## Candidate Operations

| Candidate | Type | Always? | Condition |
|---|---|---|---|
| `respond` | execution | ✓ | — |
| `retrieve-memory` | knowledge | ✓ | — |
| `search-knowledge` | knowledge | ✓ | — |
| `defer` | safety | ✓ | — |
| `ask-clarification` | safety | ✓ | — |
| `execute-skill` | execution | — | Active task |
| `learn` | growth | — | Novelty > 0.50 or exploration_bias > 0.50 |
| `self-improve` | growth | — | failure_rate > 0.35 and risk < 0.65 |

---

## Homeostatic Rules

| Condition | Trigger | Action |
|---|---|---|
| `securing` > 0.75 | Excessive risk aversion | Raise `threshold`; lower `arousal`, `exploration_bias` |
| `caution` > 0.80 | Over-cautious | Lower `exploration_bias` |
| `memory_confidence` < 0.20 | Memory collapse | Raise `threshold`; lower `persistence` |
| `success_rate` < 0.15 | Persistent failure | Raise `caution`; lower `gTrans_over` |
| `identity_continuity` < 0.30 | Identity drift | Raise `gInd_over`, raise `securing` |

---

## LLM Prompt Injection

The agent's context block now contains:

```
MOTIVATION_SIGNALS:   <active signals with strengths>
APPRAISAL:            (novelty N) (risk R) (importance I) (uncertainty U) (opportunity O) (progress P)
GOAL_STATE:           <G vector with current values>
ANTI_GOALS:           <anti-goal weights>
MODULATOR_STATE:      <all 11 modulator values>
SELF_MODEL:           <S metrics>
CANDIDATE_SCORES:     <scored-candidate name score> for all candidates
MOTIVATION_DECISION:  (decision selected-action mode directive score)
STEP_POLICY:          <human-readable guidance text>
```

---

## Extending the System

All extension points are in **`motivation/registry.metta`** only.

### Add a new domain goal

```metta
(GoalSpec my_goal 0.50)
(CandidateGoalAlignment respond   my_goal 0.60)
(CandidateGoalAlignment learn     my_goal 0.80)
```

### Add a new candidate operation

```metta
(CandidateSpec my-operation execution)
(CandidateGoalAlignment my-operation help_user 0.70)
(CandidateGoalAlignment my-operation progress  0.80)
(CandidateRiskFactor    my-operation 0.20)
(CandidateTypeModulator execution my-mod 1.0)   ; reuse type
(CandidateDecisionMap   my-operation execute execute)
```

### Add a new modulator

```metta
(ModulatorSpec my_mod 0.50)
(ScoreWeight clarity my_mod 1.0)           ; link to existing motive
(CandidateTypeModulator execution my_mod 0.8)
```

### Add a homeostatic rule

```metta
(HomeostaticRule modulator-exceeds my_mod 0.85 lower-modulator arousal 0.10)
```

No other files need modification.

---

## Running

```bash
cd PeTTa
sh run.sh run.metta -s
```

---

## Design Principles

- **Data-driven**: all specs are registry atoms; engine files are generic
- **Modular**: each layer (appraisal, candidates, decision, homeostasis, goal_evolution, persistence) is an independent file
- **Explainable**: every scored candidate and appraisal dimension is logged
- **Auditable**: CANDIDATE_SCORES in the LLM prompt provides a full audit trail
- **Goal-persistent**: goals decay to baselines but evolve gradually via α-blending
- **Safe under long-term execution**: homeostasis damps goal updates when conditions are stressed
- **Open-ended**: add goals, candidates, or rules by editing registry.metta only
