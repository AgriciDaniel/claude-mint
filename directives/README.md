# Directives

> Standard Operating Procedures (SOPs) for the Mint System Assistant

This directory contains directive files that define repeatable workflows for common system tasks. The `/mint` skill reads these directives and follows them exactly.

## Available Directives

| Directive | Trigger | Purpose |
|-----------|---------|---------|
| [security-hardening.md](security-hardening.md) | `/mint security` | Security audit and hardening |
| [system-update.md](system-update.md) | `/mint update` | Safe package updates |
| [cinnamon-customization.md](cinnamon-customization.md) | `/mint customize` | Cinnamon desktop configuration |
| [gpu-management.md](gpu-management.md) | `/mint gpu` | GPU driver and monitoring |
| [backup-recovery.md](backup-recovery.md) | `/mint backup` | Timeshift and recovery |
| [performance-tuning.md](performance-tuning.md) | `/mint performance` | CPU/GPU/IO optimization |
| [troubleshooting.md](troubleshooting.md) | `/mint troubleshoot` | Issue diagnosis |
| [development-setup.md](development-setup.md) | `/mint dev` | Development environment |

## Directive Structure

Each directive follows this format:

```markdown
# [Directive Name]

## Goal
What success looks like

## Inputs
- Required inputs
- Optional inputs with defaults

## Tools/Scripts
- execution/script.sh - description

## Process
1. Step-by-step instructions
2. Decision points with branches
3. Verification steps

## Outputs
- Expected outputs/results

## Edge Cases
- If [condition]: [action]
- If [error]: [fallback]

## Learnings
<!-- Updated by the agent when new insights are discovered -->
```

## How Directives Work

1. User invokes a command (e.g., `/mint security`)
2. Agent reads the corresponding directive
3. Agent follows the Process steps exactly
4. Agent calls execution scripts for actual work
5. Agent handles errors per Edge Cases section
6. If new insights discovered, agent updates Learnings section

## Creating New Directives

1. Copy the template structure above
2. Fill in all sections
3. Add to the table above
4. Test the workflow
