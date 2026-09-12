---
name: llm-prompt-design
description: Best practices for designing prompt templates that will be sent to an LLM (chunker prompts, verdict prompts, agent system prompts, etc.). Use this skill whenever creating or revising any text file consumed as a `system` or `user` message by a model — Ollama, Anthropic API, OpenAI, etc. Triggers on tasks like "write a prompt", "improve this prompt", "draft a system message", or work inside any `prompts/` directory.
---

# LLM Prompt Design — Operating Guide

Apply every checkpoint below when authoring or reviewing a prompt. Skipping one is allowed only when the task explicitly contradicts it.

## 1. File format

- **Use `.md`, not `.txt`.** Prompt content is Markdown-shaped (headings, bullets, fenced code). The extension should match. Editor syntax highlighting + ecosystem convention (LangChain, anthropic-cookbook) both favour `.md`. The bytes on the wire are identical, but the signal to humans matters.
- **Version every prompt.** First non-blank line is `# v1`, `# v2`, …. Bump on any semantic change. Cache keys downstream depend on this.

## 2. Structure (in order)

1. **Version marker** — `# v1`.
2. **Role priming** — `You are a [precise extractor / strict validator / …]. Your sole task is …`. One sentence. Anchors behaviour before any instruction.
3. **Output contract (first statement)** — state the response shape and "no preamble / no fences / JSON only" up front. Primacy.
4. **Task** — one paragraph naming the input source (e.g. "the document in `<document>` tags") and the expected output.
5. **Schema** — literal inline JSON example, not prose-indented field lists.
6. **Rules** — bulleted, imperative, one constraint per bullet. Bold the field name being constrained.
7. **One few-shot example** — Input/Output pair. Locks granularity and style better than three more rule bullets.
8. **Edge cases** — what to emit when input is empty / nothing matches / unparseable. Default: explicit empty value (`[]`, `{}`).
9. **Output contract (final statement)** — restate. Recency.

## 3. Input delimiters (mandatory)

- Always wrap user-supplied content in XML-style tags inside the `user` message: `<document>…</document>`, `<source>…</source>`, `<candidate>…</candidate>`. Choose one tag name per template.
- The system prompt must reference the tag explicitly: *"Extract … from the document in `<document>` tags."*
- Reasons: (a) hard boundary between instructions and content — defends against prompt-injection embedded in user input; (b) eliminates confusion when content itself contains markdown headings or JSON.

## 4. Few-shot examples

- One example, not zero, not three. The first example sets the schema; additional examples produce diminishing returns and may bias the model.
- Example must be **realistic**: the same shape and style as production input.
- Wrap example I/O in fenced blocks with explicit `Input:` / `Output:` labels.

## 5. Anti-paraphrase / verbatim tasks

- Use the exact phrase "**character-for-character**" — empirically more reliable than "verbatim" or "exactly" alone.
- Add: *"Do not summarise, reword, or normalise whitespace."*
- Add: *"The body must be a contiguous substring of the input."*
- All three together. Any one alone is not enough.

## 6. Style consistency

- When the schema includes a label/heading/title field, **specify the style**: noun phrase OR imperative OR title case — pick one and give two examples in the rules section. Inconsistent label style breaks downstream similarity / dedup.

## 7. Chain-of-thought posture

- For **extraction, classification, formatting, JSON-emission** tasks: explicitly avoid CoT invitations. Do **not** write "think step by step", "reason carefully", "explain your reasoning". CoT inflates latency 3–10× and on instruction-tuned models with `format="json"` can corrupt output.
- For **multi-step reasoning, math, planning** tasks: CoT is fine, but isolate it. Either use a model with explicit thinking blocks, or instruct the model to emit reasoning in a separate field of the JSON output.

## 8. JSON output guards

- When using `format="json"` (Ollama) or `response_format={"type": "json_object"}` (OpenAI): the API guarantees valid JSON, **not** the right shape. Validate with a Pydantic `TypeAdapter` or equivalent on the client side.
- Top-level may come back as `{"items": […]}` even when you asked for a list. Either accept and unwrap a single-key dict envelope, or be more emphatic: *"Return a JSON array directly, not wrapped in an object."*

## 9. Repetition rule

- The single most important constraint should appear **twice**: once in the role/output-contract opener, once at the end. Models weight start and end of context most heavily.
- Don't repeat everything — only the load-bearing constraint (output format, anti-paraphrase, or whatever would corrupt downstream code if violated).

## 10. What NOT to put in a prompt

- Speculative tone-setters ("be helpful", "be concise") for non-conversational tasks — wasted tokens.
- Negative-only instructions without a positive alternative ("don't X" → also say "do Y instead").
- Implementation details about the surrounding system — the model doesn't need to know which downstream function will parse its output.
- Long preambles explaining motivation. Save those for the developer reading the file (use a `# Notes` section after the prompt body if needed).

## Review checklist (paste into PR description)

- [ ] `.md` extension, `# vN` version marker on line 1
- [ ] Role priming present
- [ ] Output contract stated up front AND at the end
- [ ] Input wrapped in named XML tag, referenced in instructions
- [ ] Schema shown as literal JSON, not prose
- [ ] Exactly one few-shot example
- [ ] Edge case (empty input) handled explicitly
- [ ] If verbatim: "character-for-character" + anti-paraphrase clause + substring requirement, all three
- [ ] If schema has a label field: style (noun-phrase / imperative) specified with examples
- [ ] No CoT invitation unless task genuinely requires reasoning
- [ ] Critical constraint appears twice (primacy + recency)
