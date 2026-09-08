# Antigravity integration

AI_MEMORY uses the current Antigravity global customization locations instead of the older `~/.gemini/config/skills` layout.

## Global rules

Shared global instructions and rules are deployed into:

```text
~/.gemini/GEMINI.md
```

`setup.ps1` only manages the block between:

```text
<!-- AI_MEMORY_MANAGED_START -->
...
<!-- AI_MEMORY_MANAGED_END -->
```

In Antigravity IDE this should appear as one global `user_global` rule. The DB, Git, engineering, and memory/tool instructions are intentionally aggregated into that one global rule for Gemini/Antigravity.

## Global skills

Canonical skill sources live under:

```text
AI_MEMORY/skills/<skill-name>/
```

`setup.ps1` copies them as real files to the agent-specific global skill locations:

```text
Gemini CLI      -> ~/.gemini/skills/<skill-name>/
Antigravity IDE -> ~/.gemini/antigravity/skills/<skill-name>/
Antigravity CLI -> ~/.gemini/antigravity-cli/skills/<skill-name>/
```

Real directory copies are used for Gemini/Antigravity rather than junctions so runtime discovery does not depend on whether the client follows filesystem reparse points.

After setup, restart or reload Antigravity. `agent-memory` should then appear in Global Skills.

## Legacy cleanup

Older AI_MEMORY versions used:

```text
~/.gemini/config/skills/<skill-name>/
```

`setup.ps1` removes an old junction there only when it can prove that the link points back to the current AI_MEMORY skill source. Unrelated files are not deleted.

A legacy file may also exist at:

```text
~/.gemini/config/AGENTS.md
```

Current AI_MEMORY global rules are supplied through `~/.gemini/GEMINI.md`. If the old `AGENTS.md` contains an AI_MEMORY managed block, setup removes it. If it is not clearly AI_MEMORY-owned, setup leaves it untouched and prints a warning so the user can decide whether it is a duplicate.

`doctor.ps1` checks the current skill copies, the managed `GEMINI.md` block, and leftover legacy Antigravity paths.
