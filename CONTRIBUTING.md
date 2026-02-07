# Contributing to claude-mint

## Adding a New Directive

Directives are step-by-step SOPs in `directives/`. Each follows this structure:

```markdown
# Directive Name

> Triggered by: `/mint <command>`

## Goal
One-sentence purpose.

## Inputs
- What the directive needs to run.

## Tools/Scripts
- Referenced audit scripts and system tools.

## Process
### 1. Step One
### 2. Step Two
...

## Outputs
- What the directive produces.

## Edge Cases
- Handle missing hardware, failed commands, etc.

## Safety
- NEVER/ALWAYS rules for this workflow.

## Learnings
<!-- Updated by the agent when new insights are discovered -->
```

### Registration

After creating a directive file in `directives/`:

1. Add a route entry in `skills/mint/SKILL.md` under "Available Directives"
2. If using curl install, add the filename to the directive list in `install.sh` (line ~163)

## Adding an Audit Script

Audit scripts live in `execution/audit/` and export `AUDIT_*` variables.

Requirements:
- Use `#!/bin/bash` and `set -o pipefail`
- Export all variables with the `AUDIT_` prefix
- Handle missing tools gracefully (`command -v tool &>/dev/null`)
- Use `sudo -n` (non-interactive) to avoid password prompts
- Guard display commands behind `[ -n "$DISPLAY" ]`
- Support all GPU vendors (NVIDIA, AMD, Intel), not just one
- Always run `main` at the end so variables are populated when sourced

After creating a new audit script:
1. Source it in `execution/utils/generate-profile.sh`
2. Add its outputs to the relevant profile section

## Portability Checklist

Before submitting changes, verify:

- [ ] No hardcoded usernames, hostnames, or home paths (use `$HOME`, `$(whoami)`)
- [ ] No hardcoded device paths like `/dev/nvme0n1` (detect dynamically)
- [ ] `sudo` calls use `sudo -n` to avoid hanging on password prompts
- [ ] GPU commands check for the tool before running (`command -v nvidia-smi`)
- [ ] Works on Intel-only, AMD-only, and NVIDIA hybrid configurations
- [ ] `read` commands use `</dev/tty` for interactive input
- [ ] `grep -rn 'mint-claude' .` returns zero results (repo name is `claude-mint`)

## Testing

Mental walkthrough for three users:

1. **Intel iGPU only** (Mint 22.3) - Does `nvidia-smi` fail gracefully?
2. **NVIDIA-only desktop** (Mint 21.3) - Do PRIME commands error?
3. **AMD + NVIDIA hybrid** (Mint 22.3) - Similar to reference setup
