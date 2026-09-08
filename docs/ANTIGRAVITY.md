# Antigravity integration

AI_MEMORY separates Antigravity IDE and Antigravity CLI skill locations because the two runtimes use different global skill directories.

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
Antigravity IDE -> ~/.gemini/config/skills/<skill-name>/
Antigravity CLI -> ~/.gemini/antigravity-cli/skills/<skill-name>/
```

The Antigravity IDE path follows the current Agent Skills documentation. Real directory copies are used instead of junctions so Windows runtime discovery does not depend on whether the client follows filesystem reparse points.

After setup, fully restart Antigravity or open a new conversation. `agent-memory` should then appear in Global Skills.

## Migration cleanup

An earlier AI_MEMORY revision briefly copied Antigravity IDE skills to:

```text
~/.gemini/antigravity/skills/<skill-name>/
```

That path is not used by the current Antigravity IDE Agent Skills documentation. `setup.ps1` removes stale AI_MEMORY-owned copies from that location when the skill identity can be verified.

Older AI_MEMORY versions also used a junction at the correct IDE path:

```text
~/.gemini/config/skills/<skill-name>/
```

Current setup replaces an AI_MEMORY-owned junction there with a real directory copy.

A duplicate rule file may also exist at:

```text
~/.gemini/config/AGENTS.md
```

Current AI_MEMORY global rules are supplied through `~/.gemini/GEMINI.md`. If the old `AGENTS.md` contains an AI_MEMORY managed block, setup removes it. If it is not clearly AI_MEMORY-owned, setup leaves it untouched and prints a warning so the user can decide whether it is a duplicate.

`doctor.ps1` checks the current IDE/CLI skill copies, the managed `GEMINI.md` block, stale skill paths, and duplicate Antigravity rule files.
