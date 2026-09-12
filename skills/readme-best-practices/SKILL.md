---
name: readme-best-practices
description: Best practices for writing and maintaining a README file. Use this skill whenever creating or significantly revising a README — any language, any project type. Activate for tasks like "write a README", "improve the README", "what should the README contain", "update README", or when reviewing a README for completeness. Includes general structure, plus targeted guidance for Python packages, CLI tools, libraries, and the command matrix required for multi-entry-point projects (pipelines, ETL jobs, scrapers — anything whose README must answer "two commands write the same table, which do I run?").
---

# README Best Practices — Operating Guide

Apply every section below when authoring or reviewing a README. Skip a section only when the project type explicitly doesn't need it (e.g. a pure library has no "Commands" section).

---

## 1. Core Principles

- **Answer four questions immediately:** What is it? Who is it for? Why does it exist? How do I start?
- **Scannable over exhaustive.** Headings, tables, bullets — never long prose paragraphs.
- **Show, don't tell.** One realistic code example beats three paragraphs of description.
- **Copy-pasteable by default.** Every command must run as-is in a fresh environment. Test them.
- **Link out, don't embed.** Detailed tutorials, API docs, changelogs → links. README = entry point, not encyclopedia.
- **No phase markers, internal jargon, or roadmap leakage.** User-facing docs describe what exists now.

---

## 2. Universal Section Order

| # | Section | Required? | Notes |
|---|---|---|---|
| 1 | Project name (H1) | Always | Match repo name and published package name. |
| 2 | Badges | Situational | See §7. Max 6. Placed directly under H1. |
| 3 | Tagline + description | Always | 1 sentence tagline. 2–3 sentence description. Plain language. |
| 4 | Table of Contents | Optional | See §10. Add when README exceeds ~3 scrolls or has 6+ H2 sections. |
| 5 | Demo | Strongly recommended | Screenshot, GIF, or terminal recording. Highest-impact section. |
| 6 | Installation | Always | Exact command(s), no omissions. State prerequisites. |
| 7 | Quick start | Always | Minimum invocation → useful result. Show expected output. |
| 8 | Usage / Commands | Situational | Required for CLIs. Optional for libraries (link to API docs instead). A project with many entry points uses the command matrix (§5) instead of a flat list. |
| 9 | Configuration | Situational | Env vars, config files, precedence. Required if non-trivial. |
| 10 | How it works | Optional | One short paragraph + optional diagram. Link to deeper docs. |
| 11 | Troubleshooting / FAQ | Recommended | Top 3–5 errors with remediation. See §10 for Python-specific pitfalls. |
| 12 | Development | Always | Clone → install → test → lint. 5–10 lines max. |
| 13 | Contributing | Recommended | Link to CONTRIBUTING.md or inline if tiny. |
| 14 | Support and Feedback | Optional | See §10. Add when the project has active users or an issue tracker. |
| 15 | License | Always | One-line statement + link to LICENSE file. |
| 16 | Citation / Acknowledgements | Situational | Research tools, OSS that wraps another project. |

---

## 3. Writing Style Rules

- **Tagline:** imperative or noun phrase. One sentence. No period needed.
  - Good: `Centralize and evolve LLM config files across projects using semantic analysis.`
  - Bad: `Axiom is a tool that can be used to centralize and evolve LLM configuration files.`
- **Description:** 2–3 sentences. Answer who benefits and the core mechanism. No marketing superlatives.
- **First heading after description** must be Installation — a new user's first instinct.
- **Code blocks:** always fenced with language tag (` ```bash `, ` ```python `). Never use `$` prompt inside the block. Show expected output directly below as a comment or separate block.
- **Links:** use descriptive text, not bare URLs. Bad: `See https://example.com`. Good: `See the [API reference](https://example.com)`.

---

## 4. Python-Specific Guidance

### Installation Section

Always include, in this order:

```bash
# End-users (published package)
pip install axiom

# End-users (isolated, recommended for CLI tools)
pipx install axiom

# Contributors
git clone https://github.com/org/axiom
pip install -e .[dev]
```

- State the minimum Python version: `Requires Python 3.11+`.
- If extra `[groups]` exist, list them and what they unlock.
- If the package is not yet on PyPI, say so and link to the install-from-source instructions only.

### pyproject.toml alignment

The README on PyPI is served from the `readme = "README.md"` field. Ensure:
- `readme = "README.md"` is set in `[project]`.
- No relative image paths — PyPI will not resolve them. Use absolute GitHub raw URLs.
- No raw HTML that PyPI strips (e.g. `<details>`, `<img align="right">`).
- Verify with `twine check dist/*` after `python -m build`.

### Versioning and Changelog

- Link to `CHANGELOG.md` or GitHub Releases.
- Do not embed the changelog in the README.

---

## 5. CLI-Specific Guidance

CLIs have unique README needs because users arrive wanting to run a command immediately.

### Demo section (mandatory for CLIs)

Place immediately after the description. Options in order of preference:
1. **Animated terminal recording** — use `vhs`, `asciinema`, or `termtosvg`. Embed as animated SVG or GIF.
2. **Static screenshot** of a representative command + output.
3. A fenced block with realistic output shown as comments.

### Quick Start

Must be a single, copy-pasteable invocation that produces visible, useful output in under 30 seconds.

```bash
axiom scan ~/projects/myapp
```

```
Found 3 project instruction files (`AGENTS.md` / `CLAUDE.md`) → 14 chunks extracted
```

### Commands / Usage Section

For each command:
- **Synopsis:** `axiom <command> [OPTIONS] [ARGS]`
- **Description:** one line.
- **Key flags:** table with flag, type, default, description.
- **Example:** one realistic invocation with expected output.

Do **not** paste raw `--help` output — it goes stale and is verbose. Link to it instead:

```bash
axiom --help
axiom scan --help
```

### Exit codes

Document them if the CLI is used in scripts or CI:

| Code | Meaning |
|---|---|
| 0 | Success |
| 1 | General error |
| 2 | Configuration / environment error |

### Shell completion

If supported (Typer and Click both expose this), document it:

```bash
axiom --install-completion bash
```

### The command matrix (mandatory for multi-entry-point projects)

A project with more than a handful of runnable entry points — a data pipeline, an ETL job, a scraper, anything with `make` targets plus `python -m` modules — cannot be documented one command at a time. Readers do not arrive asking "what does flag X do"; they arrive asking **"two commands write the same table, which one do I run?"** and **"which of these destroys data?"**. A flat list answers neither.

Document those projects as **one table per thing the project produces**, not one table per script. Within a table, order rows **chronologically — first-used to last-used**, so the normal path reads top to bottom and repair paths sit at the bottom.

**Required columns, in this exact order:**

| Column | Content | Why it earns a column |
|---|---|---|
| `#` | Row number, used for cross-references (`see Step commands row 4`) | Lets other rows and prose point at a command without repeating it |
| `Command` | The `make` target **and** the underlying module invocation, one above the other | Readers know one form or the other, never reliably both |
| `When to use it` | 1–2 sentences: the situation that calls for this command, and what distinguishes it from its neighbours | The only column that resolves "these two write the same table" |
| `Reads` | Input source, named: an API, a live page, a specific stored artifact | Shows whether a run needs network or credentials |
| `Writes` | Output, **always labelled with its layer** — raw/Bronze, database (name the tables and columns), or filesystem | The single most consulted cell; "writes to the DB" without columns is useless |
| `Browser` | yes/no, plus headless vs visible | Separates cheap offline runs from slow, rate-limited, detectable ones |
| `Selection flags` | Flags choosing *what* is processed, plus the default when none is given | The default selection is what surprises people |
| `Other flags` | Everything else: dry-run, concurrency, and destructive flags marked ⚠️ | Keeps the dangerous ones out of the same cell as routine ones |

**Rules:**

- **Every `Writes` cell names its layer.** Not "saves the page" — "**Bronze** `raw_responses.quiz_html`". Not "updates the row" — "**DB** `quiz_questions.answer_verified`".
- **⚠️ marks every destructive flag, in the cell that carries it.** A flag that deletes rows or overwrites stored raw data gets the marker plus one clause naming exactly what is lost and what must be re-run afterwards.
- **A command appearing in several tables is repeated, not cross-referenced away.** If the main extraction command produces steps, quizzes and assets, it is row 1 of all three tables, with `When to use it` and `Writes` narrowed to that table's subject and a `*(Step commands row 1)*` pointer for its flags.
- **Same-named flags that differ get called out below the table.** If `--force` deletes rows in one command and merely redoes work in another, say so explicitly — a table cannot carry that comparison.
- **Group by output, not by module path.** `scraper.ops.reparse_quiz_html` and `scraper.quiz_utils --reparse` live in different packages and both belong in the quiz table.
- **One-off scripts stay out.** A script with a hardcoded ID list, or one written for a bug that is now fixed, is not a standing command — leave it to the exploration/spike section.
- **Read the argument parser before writing a row.** Never infer a flag name from the module name or from memory; flags drift, and a wrong flag in a README is worse than no README.

**Placement:** these tables *are* the Commands section (§2 row 8). Conceptual sections such as "How it works" keep the narrative and link to the matrix instead of repeating flags. When a matrix is added, delete the older per-command list it replaces — two descriptions of one command drift apart within a release.

**Worked shape:**

```markdown
#### Quiz commands

Rows 1–4 are the normal path, in the order they run. Rows 5–7 are repairs.

| # | Command | When to use it | Reads | Writes | Browser | Selection flags | Other flags |
|---|---|---|---|---|---|---|---|
| 1 | `make scrape-content`<br>`python -m pkg.pipeline.scrape_content` | The default way quizzes enter the database — walks whole trainings. | live platform | **Bronze** `raw_responses.quiz_html`, then **DB** `quiz_questions` (`correct_answer=NULL`) | yes, headless | `--training-id N`, `--limit N`<br>default: trainings not marked complete | `--no-headless` · `--rescrape` ⚠️ (row 5) |
| 2 | `python -m pkg.backfill_quizzes` | Only when row 1 visited the step but produced **zero** questions. | live quiz page → **Bronze** `quiz_html` | **DB** `quiz_questions` — inserts the missing structure rows | yes, visible | `--step-id N`, `--limit N`<br>default: steps with zero questions | `--force` ⚠️ DELETEs the step's rows first, discarding collected answers |
```

### Troubleshooting section (mandatory for CLIs with external deps)

For each external dependency (Ollama, Docker, a database), provide the canonical remediation block. Format:

**Error:** `ConnectionError: Ollama is not reachable at http://localhost:11434`

**Fix:**
```bash
ollama serve
ollama pull qwen2.5:7b-instruct
```

Keep remediation blocks self-contained — no cross-references the user must follow.

**Python-specific pitfalls to always cover:**

- **`command not found` after `pip install`** — the Python user bin directory is not on `PATH`. Provide the exact fix for each OS:
  ```bash
  # macOS / Linux: add to ~/.zshrc or ~/.bashrc
  export PATH="$HOME/.local/bin:$PATH"

  # Windows (PowerShell)
  $env:PATH += ";$env:APPDATA\Python\Python3x\Scripts"
  ```
  Recommend `pipx install` as the prevention — it handles PATH automatically.
- **Wrong Python / `python` vs `python3`** — explicitly state which interpreter the tool requires and how to verify: `python --version`.
- **Virtual environment not activated** — if the tool must run inside a venv, say so explicitly. Do not assume users know the activation command.

---

## 6. Library-Specific Guidance

- Replace "Commands" with "API Overview" — show 3–5 representative code snippets.
- Link to hosted API docs (ReadTheDocs, MkDocs, Sphinx).
- Include type signatures in code examples.
- Show both the happy path and one common error handling pattern.

---

## 7. Badges

Use badges from [shields.io](https://shields.io). Max 6. Priority order:

1. PyPI version (if published)
2. Supported Python versions
3. CI / test status (GitHub Actions)
4. License
5. Code style / linter (ruff, black)
6. Test coverage (codecov)

**Avoid:** build-passing badges that are always green, download counts (vanity), badges for tools the project doesn't actively use.

---

## 8. Optional Sections

### Table of Contents

**When to add:** README exceeds ~3 scrolls, or has 6 or more H2 sections. Mandatory for CLIs with many subcommands — users scan for a specific flag and do not want to read linearly.

**Placement:** immediately after the tagline/description block, before Demo.

**Format:** a nested Markdown link list mirroring the heading hierarchy. Do not manually maintain it — automate it:

- **GitHub Actions:** use `tj-actions/markdown-toc` or `technote-space/toc-generator` to regenerate on push.
- **VS Code / editors:** `Markdown All in One` extension regenerates on save.
- **CLI:** `doctoc README.md` (npm package, one-shot or CI step).

**Style rule:** TOC entries should match heading text exactly — no paraphrasing. If a heading is too verbose for the TOC, shorten the heading itself.

```markdown
## Table of Contents
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Commands](#commands)
  - [scan](#scan)
  - [ingest](#ingest)
- [Configuration](#configuration)
- [Troubleshooting](#troubleshooting)
- [Development](#development)
```

---

### Support and Feedback

**When to add:** the project has an active issue tracker, discussion forum, or community channel. Omit only for purely internal or single-maintainer throwaway tools.

**Placement:** after Contributing, before License.

**What to include — exactly three directives, no more:**

1. **Bugs and unexpected behavior** → GitHub Issues. Link directly to the new-issue URL with a pre-filled bug-report template if one exists.
2. **Questions, ideas, and general discussion** → your preferred async channel. Pick one: GitHub Discussions, Discord, or an email address. Do not list all three — it fragments responses.
3. **Security vulnerabilities** → private disclosure path (email or GitHub private security advisory). Never ask users to open a public issue for security bugs.

**Format:**

```markdown
## Support

- **Bug reports:** [Open an issue](https://github.com/org/repo/issues/new?template=bug_report.md)
- **Questions and feature requests:** [GitHub Discussions](https://github.com/org/repo/discussions)
- **Security vulnerabilities:** email security@example.com — do not open a public issue
```

**Tone rule:** tell users *exactly* what to do. "Feel free to reach out" is not actionable. "Open an issue at [link]" is.

---

## 9. Maintenance Rules

- **On every new command or flag:** update the Commands section and Quick Start. In a command matrix, add the row to every table whose artifact the command writes — not just the most obvious one.
- **On every breaking change:** update Installation, Quick Start, and Configuration.
- **On Python version bump:** update the Requirements line.
- **On external dependency change** (new model, new service): update Troubleshooting.
- **Phase/roadmap markers** (`"Phase 4"`, `"coming soon"`) must be removed before merge — they are internal, not user-facing.

---

## 10. Gap-Analysis Checklist

Run this against any README before marking it done:

- [ ] H1 title matches repo name and package name
- [ ] Tagline: one sentence, plain language
- [ ] Description: 2–3 sentences, no internal jargon
- [ ] TOC present if README has 6+ H2 sections or exceeds ~3 scrolls; generated automatically (not hand-maintained)
- [ ] Demo section exists (screenshot, GIF, or terminal recording)
- [ ] Installation: exact command(s), Python version stated, external deps listed
- [ ] Quick start: one copy-pasteable command, expected output shown
- [ ] All code blocks: fenced + language tag, no `$` prefix, no placeholders
- [ ] CLI: Commands section with synopsis, key flags, example per command
- [ ] Multi-entry-point project: command matrix present — one table per produced artifact, rows in first-used-to-last-used order, columns `# · Command · When to use it · Reads · Writes · Browser · Selection flags · Other flags`, every `Writes` cell naming its layer and every destructive flag marked ⚠️
- [ ] Configuration: all env vars documented with type, default, effect
- [ ] Troubleshooting: top errors covered with self-contained remediation; Python PATH pitfall addressed for CLI tools
- [ ] Development: clone → install → test → lint, all commands verified
- [ ] Support section present if project has an issue tracker; directs bugs → Issues, questions → one async channel, security → private path
- [ ] License: stated and linked
- [ ] No phase markers, internal roadmap refs, or "coming soon" copy
- [ ] No relative image paths (use absolute URLs for PyPI compatibility)
- [ ] `twine check dist/*` passes (Python packages)
- [ ] Every command in the README runs successfully in a clean environment
