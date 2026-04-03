# Spec-to-Ship Metrics

> Every workflow run produces a scorecard. This document defines the formula for each metric and the composite score.

## Indicators

### Timing
| Metric | Definition | Unit |
|--------|-----------|------|
| `total_duration_ms` | Wall clock from intake to completion | ms |
| `planning_ms` | Time in strategic + tactical planning phases | ms |
| `implementation_ms` | Time in implementation phase (all tasks) | ms |
| `review_ms` | Time in code review phase (all cycles) | ms |

### Quality
| Metric | Definition | Better |
|--------|-----------|--------|
| `review_cycles_avg` | Average review iterations per PR | Lower |
| `retries_total` | Total implementation retries across all tasks | Lower |
| `security_findings.critical` | Critical security findings caught in review | Lower = cleaner code, but 0 on risky changes is suspect |
| `scope_violations` | Times an agent modified files outside declared scope | 0 = perfect |
| `scope_churn_ratio` | Files changed outside scope / total files changed | 0.0 = perfect |
| `escaped_defects` | Defects found post-merge (updated retroactively) | 0 = ideal |
| `post_merge_regressions` | Regressions after merge (updated retroactively) | 0 = ideal |
| `lessons_generated` | New lessons extracted from this run | More = pipeline is learning |

### Efficiency (optional, when token data available)
| Metric | Definition |
|--------|-----------|
| `tokens.total` | Total input + output tokens |
| `tokens.planning` | Tokens used in planning phases |
| `tokens.implementation` | Tokens used in implementation |
| `tokens.review` | Tokens used in review |

## Composite Score Formula

```
score = 100
  - (review_cycles_avg - 1) * 10    # penalty for re-reviews (1 cycle = perfect)
  - retries_total * 5                # penalty for implementation retries
  - security_findings.critical * 20  # heavy penalty for critical findings
  - security_findings.important * 5  # moderate penalty
  - scope_violations * 15            # heavy penalty for scope drift
  - escaped_defects * 25             # heaviest penalty — caught too late
  - post_merge_regressions * 25      # heaviest penalty
  + lessons_generated * 2            # bonus for learning

score = max(0, min(100, score))      # clamp to 0-100
```

## Interpretation

| Score | Rating | Meaning |
|-------|--------|---------|
| 90-100 | Excellent | Clean delivery, minimal friction |
| 75-89 | Good | Some review cycles or minor issues |
| 60-74 | Acceptable | Multiple retries or important findings |
| 40-59 | Needs improvement | Critical findings or scope violations |
| 0-39 | Poor | Escaped defects or repeated failures |

## Comparison

Scorecards are stored in `.factory/scorecards/` as JSON files named `{session_id}.json`.

Compare across:
- **Features**: Which types of features have lower scores?
- **Time**: Is the pipeline improving over time?
- **Pipeline versions**: Did a template change improve or degrade quality?
- **Projects**: Which project has the healthiest delivery pipeline?
