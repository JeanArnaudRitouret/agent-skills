---
name: add-agent-skill
description: Add or update a shared personal agent skill in canonical agent-skills, including reference discovery, host links, manifest, and README maintenance. Use when a skill needs shared Claude and Codex availability.
---

# Add Agent Skill

## Canonical source

Create or update only `skills/<skill-name>/` in this repository. Do not create
duplicate skill content under `~/.claude/skills`, `~/.agents/skills`, or legacy
`~/.codex/skills`.

Keep `name` equal to folder name. Give `description` a concise trigger and
boundary. Use portable instructions and relative supporting-file references.

## Integration audit

Before installation, inspect each consumer for `<skill-name>` and record result:

| Consumer | Required action |
|---|---|
| `skills.manifest` | Always add, rename, or remove exactly one sorted entry. |
| `README.md` | Always add or revise matching skill summary. |
| `~/.claude/skills` and `~/.agents/skills` | Install both links only after explicit approval. |
| Forced-eval hooks | Dynamic root scans need no per-skill edit unless behavior changes. |
| Project skills or configuration | Change only when task specifically requires integration. |

Record every required reference, explicit no-change result, or host exception.

## Documentation and validation

For every manifest entry, README has exactly one `### \`<skill-name>\`` section
with two to four accurate bullets. Summaries describe trigger, key workflow, and
material limit; they never replace `SKILL.md` instructions.

Run skill validation, inspect repository diff, and run link installer dry run.
Commit canonical skill, manifest, README, and approved integration changes
together before explicit installer `--apply`.

## Rename or removal

Update canonical folder, manifest, README, and every required reference before
removing a link. Preserve installer migration backup until verification passes.
