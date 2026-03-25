---
name: meow-experiments
description: "Manage Meow protocol experiments: codebook training, agent communication tasks, information density measurement, and cross-model compatibility testing. Use when: (1) Training/evaluating VQ-VAE codebooks, (2) Running multi-agent communication experiments, (3) Measuring Meow vs. natural language baselines, (4) Testing cross-model compatibility. Logs all experiments to experiments/ with reproducible configs."
metadata:
  version: 0.1.0
  project: meow
  category: research
---

# Meow Experiments Skill

Automate, track, and reproduce Meow protocol experiments. Every experiment is logged with config, results, and artifacts for scientific rigor.

## Quick Reference

| Task | Command | Output |
|------|---------|--------|
| Train codebook | `python train_codebook.py --config experiments/configs/codebook-v1.yaml` | `experiments/artifacts/codebook-YYYYMMDD-XXX/` |
| Run agent task | `python run_task.py --task cooperative_coding --agents 2` | `experiments/results/task-YYYYMMDD-XXX.json` |
| Measure density | `python measure_density.py --codebook <path> --baseline natural_language` | `experiments/metrics/density-YYYYMMDD-XXX.csv` |
| Cross-model test | `python test_cross_model.py --models claude,gpt,gemini` | `experiments/cross_model/YYYYMMDD-XXX/` |

---

## Directory Structure

```
experiments/
├── configs/              # Experiment configurations (YAML)
│   ├── codebook-v1.yaml
│   ├── task-coding.yaml
│   └── baseline.yaml
├── artifacts/            # Trained models, codebooks
│   └── codebook-20260320-001/
│       ├── codebook.pkl
│       ├── encoder.pth
│       ├── decoder.pth
│       └── metadata.json
├── results/              # Experiment results (JSON/CSV)
│   ├── task-20260320-001.json
│   └── metrics-20260320-001.csv
├── logs/                 # Training/experiment logs
│   └── train-20260320-001.log
├── cross_model/          # Cross-model compatibility tests
│   └── 20260320-001/
│       ├── claude_to_gpt.json
│       └── compatibility_matrix.csv
└── notebooks/            # Jupyter notebooks for analysis
    └── density_analysis.ipynb
```

---

## Codebook Training

### Configuration Template

Create `experiments/configs/codebook-v1.yaml`:

```yaml
experiment:
  name: "codebook-v1-baseline"
  description: "Initial VQ-VAE codebook, 512 symbols"
  timestamp: "2026-03-20T09:00:00Z"
  
codebook:
  size: 512                    # Number of discrete symbols
  embedding_dim: 768           # Dimension of each symbol
  commitment_cost: 0.25        # VQ-VAE commitment loss weight
  
training:
  dataset: "agent_embeddings_v1"  # Path or dataset name
  num_epochs: 100
  batch_size: 64
  learning_rate: 0.0001
  optimizer: "adam"
  
validation:
  split: 0.2
  metrics:
    - reconstruction_loss
    - codebook_usage          # How many symbols are actively used
    - perplexity              # Effective codebook size
    
artifacts:
  save_path: "experiments/artifacts/codebook-20260320-001"
  checkpoint_interval: 10     # Save every N epochs
```

### Training Command

```bash
python scripts/train_codebook.py \
  --config experiments/configs/codebook-v1.yaml \
  --resume experiments/artifacts/codebook-20260320-001/checkpoint_50.pth  # optional
```

### Monitoring

Training logs metrics to:
- `experiments/logs/train-<timestamp>.log`
- TensorBoard: `tensorboard --logdir experiments/logs/tensorboard/`

**Key metrics to watch:**
- Reconstruction loss ↓ (how well embeddings are reconstructed)
- Codebook usage ↑ (unused symbols = wasted capacity)
- Perplexity ≈ codebook size (all symbols equally likely = ideal)

---

## Agent Communication Tasks

### Task Types

| Task | Description | Metrics |
|------|-------------|---------|
| `cooperative_coding` | 2+ agents refactor code collaboratively | Code quality, communication cost |
| `distributed_reasoning` | Agents solve logic puzzles with partial info | Success rate, message count |
| `20_questions` | One agent guesses, others give hints | Guess accuracy, questions used |
| `parallel_hypotheses` | Agents share reasoning states | Convergence time, information overlap |

### Running a Task

```bash
python scripts/run_task.py \
  --task cooperative_coding \
  --agents 2 \
  --codebook experiments/artifacts/codebook-20260320-001/codebook.pkl \
  --communication_budget 100  # Max tokens per agent per round \
  --output experiments/results/task-20260320-001.json
```

### Task Configuration

Create `experiments/configs/task-coding.yaml`:

```yaml
task:
  type: "cooperative_coding"
  description: "Refactor auth module with 2 agents"
  
scenario:
  codebase: "tests/fixtures/auth_module/"
  objective: "Refactor session handling to use Redis"
  constraints:
    - "All tests must pass"
    - "API signatures unchanged"
    
agents:
  count: 2
  roles:
    - "architect"   # Plans changes
    - "implementer" # Writes code
    
communication:
  protocol: "meow"
  budget_per_round: 100       # tokens (Meow or natural language)
  max_rounds: 20
  baseline: "natural_language" # For comparison
  
evaluation:
  metrics:
    - task_success             # Did tests pass?
    - code_quality_delta       # Linting score change
    - communication_cost       # Total tokens used
    - time_to_completion       # Wall-clock time
```

---

## Baseline Comparison

### Natural Language Baseline

Run same task with natural language:

```bash
python scripts/run_task.py \
  --task cooperative_coding \
  --agents 2 \
  --communication_protocol natural_language \
  --output experiments/results/baseline-20260320-001.json
```

### Metrics Comparison

```bash
python scripts/compare_metrics.py \
  --meow experiments/results/task-20260320-001.json \
  --baseline experiments/results/baseline-20260320-001.json \
  --output experiments/metrics/comparison-20260320-001.csv
```

**Expected outputs:**
- Information density (bits per token)
- Communication overhead (token count)
- Task success rate
- Latency per round

---

## Cross-Model Compatibility

### Test Protocol

1. Train shared codebook on mixed embeddings (Claude + GPT + Gemini)
2. Each model trains its own encoder/decoder
3. Test agent-to-agent communication across models

### Running Cross-Model Test

```bash
python scripts/test_cross_model.py \
  --codebook experiments/artifacts/codebook-20260320-001/codebook.pkl \
  --models claude-sonnet-4,gpt-4o,gemini-2.0-flash \
  --task 20_questions \
  --output experiments/cross_model/20260320-001/
```

### Compatibility Matrix

Output: `experiments/cross_model/20260320-001/compatibility_matrix.csv`

```csv
Sender,Receiver,Message_Count,Decode_Success_Rate,Task_Success_Rate
claude,gpt,50,0.92,0.85
claude,gemini,50,0.88,0.80
gpt,claude,50,0.90,0.83
gpt,gemini,50,0.86,0.78
gemini,claude,50,0.89,0.82
gemini,gpt,50,0.87,0.79
```

**Goals:**
- Decode success rate > 85% (agent understands message)
- Task success rate > 75% (agents complete task together)

---

## Evolution Experiments

### Multi-Generation Training

Let agent communication evolve over generations:

```yaml
evolution:
  generations: 10
  population_size: 100         # Agents per generation
  selection: "top_20_percent"  # Keep best performers
  mutation_rate: 0.1           # Vary codebook usage
  
fitness_function:
  task_success: 0.6            # 60% weight
  communication_cost: 0.3      # 30% weight (lower = better)
  cross_model_compat: 0.1      # 10% weight
```

```bash
python scripts/evolve_protocol.py \
  --config experiments/configs/evolution-v1.yaml \
  --output experiments/evolution/gen-{generation}/
```

### Tracking Evolution

Metrics to monitor:
- **Codebook drift**: Do symbols' meanings change over generations?
- **Convergence**: Are all agents using similar patterns?
- **Diversity**: Do different agent pairs develop different "dialects"?

---

## Safety Audits

### Automatic Audit Triggers

After every experiment, run safety check:

```bash
python scripts/audit_experiment.py \
  --experiment experiments/results/task-20260320-001.json \
  --decode_samples 20 \
  --output experiments/audits/audit-20260320-001.json
```

**Audit checks:**
1. **Decodability**: Can all Meow messages be decoded to human language?
2. **Alignment**: Do decoded messages match agent actions?
3. **Deception detection**: Are agents saying one thing, doing another?

See `meow-safety` skill for detailed audit procedures.

---

## Logging Format

### Experiment Results

`experiments/results/task-YYYYMMDD-XXX.json`:

```json
{
  "experiment_id": "task-20260320-001",
  "timestamp": "2026-03-20T09:15:00Z",
  "config": {
    "task": "cooperative_coding",
    "agents": 2,
    "communication_protocol": "meow",
    "codebook": "experiments/artifacts/codebook-20260320-001"
  },
  "results": {
    "task_success": true,
    "code_quality_delta": +12,
    "communication": {
      "total_messages": 47,
      "total_tokens": 2834,
      "avg_tokens_per_message": 60.3,
      "information_density_bits_per_token": 3.2
    },
    "time": {
      "wall_clock_seconds": 185,
      "avg_round_latency_ms": 420
    }
  },
  "baseline_comparison": {
    "protocol": "natural_language",
    "total_tokens": 8952,
    "density_improvement": "2.16x",
    "latency_reduction": "38%"
  },
  "artifacts": {
    "communication_log": "experiments/artifacts/task-20260320-001-messages.jsonl",
    "final_codebase": "experiments/artifacts/task-20260320-001-output/"
  }
}
```

---

## Reproducibility

### Requirements

Create `experiments/requirements.txt`:

```
torch>=2.0.0
transformers>=4.30.0
numpy>=1.24.0
pyyaml>=6.0
tensorboard>=2.13.0
jupyter>=1.0.0
```

### Environment Setup

```bash
python -m venv venv
source venv/bin/activate
pip install -r experiments/requirements.txt
```

### Reproduce Experiment

```bash
# Load exact config from past experiment
python scripts/reproduce_experiment.py \
  --experiment_id task-20260320-001 \
  --seed 42  # For deterministic results
```

---

## Integration with Self-Improvement

When experiments fail or reveal insights:

1. **Log to `.learnings/`** using self-improvement skill format
2. **Promote** recurring patterns to `MEMORY.md` or skill updates
3. **Extract** new skills if a technique proves broadly useful

Example learning entry:

```markdown
## [LRN-20260320-001] codebook_usage

**Logged**: 2026-03-20T09:30:00Z
**Priority**: high
**Status**: pending
**Area**: research

### Summary
Codebook usage drops below 40% after 50 epochs — many symbols unused.

### Details
VQ-VAE training converges, but only 205/512 symbols are actively used.
This wastes capacity and reduces effective information density.

### Suggested Action
- Add codebook usage regularization (entropy bonus)
- Try smaller codebook (256 symbols) and measure performance
- Investigate why certain symbols are never chosen

### Metadata
- Source: experiment
- Related Files: scripts/train_codebook.py
- Experiment ID: task-20260320-001
- Pattern-Key: codebook.underutilization

---
```

---

## References

**VQ-VAE fundamentals:**
- van den Oord et al. (2017). "Neural Discrete Representation Learning." NeurIPS.

**Emergent communication:**
- Mordatch & Abbeel (2018). "Emergence of Grounded Compositional Language in Multi-Agent Populations." ICLR.
- Lazaridou et al. (2020). "Multi-agent Communication meets Natural Language." ICLR.

**Multi-agent RL:**
- Foerster et al. (2016). "Learning to Communicate with Deep Multi-Agent Reinforcement Learning." NeurIPS.
- Das et al. (2019). "TarMAC: Targeted Multi-Agent Communication." ICML.

**Recent work:**
- Chen et al. (2026). "The Five Ws of Multi-Agent Communication." arXiv:2602.xxxxx.
- Seo et al. (2026). "Reasoning-Native Agentic Communication for 6G." arXiv:2602.xxxxx.

---

## Status

**Current**: Skill template created, no experiments run yet.

**Next steps**:
1. Implement `train_codebook.py` with VQ-VAE
2. Create agent task harness (`run_task.py`)
3. Run baseline experiments (natural language vs. Meow)
4. Measure information density and latency

**Long-term**:
- Cross-model testing with OpenAI/Google/Anthropic APIs
- Evolution experiments (multi-generation training)
- Production SDK for agent frameworks
