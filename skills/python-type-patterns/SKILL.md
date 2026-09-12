---
name: python-type-patterns
description: Python typing patterns for closed sets of string discriminators — Literal[...] vs StrEnum vs plain str; the Single-Definition Rule (each literal spelled once, every other site references the symbol); avoiding docstrings duplicating type annotations. TRIGGER when designing or reviewing discriminator fields like "ollama"/"deepseek"/"codex"/"claude" or similar closed string sets, AND when writing or reviewing any function that returns/assigns/compares such a value as a quoted literal (detectors, classifiers, dispatch, status fields), including literals embedded in JS/SQL strings.
---

# Python Type Patterns

Apply this skill when:
- Designing or reviewing a closed set of string discriminators (`"ollama"`, `"deepseek"`, `"codex"`, `"claude"`, `"cursor_rule"`, …)
- Deciding between `Literal[...]`, `StrEnum`, or plain `str` for a discriminator field
- Ensuring docstrings don't duplicate information already captured by type annotations
- Writing ANY function that returns, assigns, or compares a discriminator value — the Single-Definition Rule (§5) applies at every producer and consumer site, not just where the type is declared

---

## 1. `Literal` vs `Enum` — Decision Rule

**Use `Literal[...]`** when all of the following hold:
- The set of valid values is small (≤ ~6) and stable.
- The values are consumed as plain strings (dict keys, JSON fields, comparisons, user-facing output).
- No methods or computed properties need to live on the type.
- The codebase already uses `Literal` for other discriminators of the same shape.

**Use `StrEnum`** when *at least one* of the following holds:
- Typer/Click CLI auto-validation + tab-completion is a meaningful ergonomic win.
- Values need methods or computed properties (e.g. `.label`, `.api_endpoint`).
- The codebase already uses `Enum` for similar types (consistency).

**Never use plain `str`** for a field that is only valid for a fixed set of values — it defeats type checking entirely.

### Pattern: closed discriminator with `Literal`

```python
# models.py (or base.py of the relevant module)
ProviderName = Literal["ollama", "deepseek"]

# dispatch dict replaces if/elif chains
_DISPATCH: dict[ProviderName, Callable[[], LLMProvider]] = {
    "ollama":   lambda: OllamaProvider(),
    "deepseek": lambda: DeepseekProvider(),
}

def get_provider(name: ProviderName = "deepseek") -> LLMProvider:
    if name not in _DISPATCH:
        raise ValueError(f"Unknown provider: {name!r}. Valid options: {', '.join(_DISPATCH)}")
    return _DISPATCH[name]()
```

Adding a third provider = edit `ProviderName` + add one key to `_DISPATCH`. Mypy enforces exhaustiveness at every typed call site.

---

## 2. The `LLMProvider` Protocol Pattern — Self-Identifying via `name`

When a Protocol has multiple concrete implementations, add `name: ProviderName` so callers can branch on identity without holding the original string:

```python
class LLMProvider(Protocol):
    name: ProviderName
    chunker_version: str
    ...
```

Each concrete class sets `self.name: ProviderName = "deepseek"` in `__init__`. Callers use `provider.name == "deepseek"` instead of `provider_name == "deepseek"` — the provider carries its own identity, no extra variable needed.

---

## 3. Docstring Rule — Let the `Literal` speak

**Never enumerate a `Literal`'s valid values in prose.** The annotation already carries the source of truth; prose duplicates it and drifts.

```python
# WRONG — prose enumerates, drifts when Literal grows
def get_provider(name: ProviderName = "deepseek") -> LLMProvider:
    """...
    Args:
        name: Provider identifier — ``"ollama"`` or ``"deepseek"`` (default).
    """

# RIGHT — prose stays generic; Literal is the documentation
def get_provider(name: ProviderName = "deepseek") -> LLMProvider:
    """...
    Args:
        name: Provider identifier; defaults to ``"deepseek"``.
    """
```

The same rule applies to any `Literal`-typed parameter. If the caller needs to discover valid values programmatically, expose `get_args(ProviderName)` — but don't bake that into a docstring string or a `__doc__` mutation.

---

## 4. Where to define the alias

Define the `Literal` alias in the module that owns the type, not the module that uses it. For a provider abstraction:
- `llm/base.py` — owns `LLMProvider` Protocol and `ProviderName`.
- `llm/__init__.py` — imports `ProviderName` to type `get_provider`.
- `commands/scan.py` — imports `ProviderName` if it needs to type its own arg, or simply relies on the Protocol's `name` attribute.

One source of truth, imported everywhere — same as `ChunkKind`, `VaultRealm`, `Verdict`.

---

## 5. The Single-Definition Rule (spelled out)

> **Each discriminator literal is spelled exactly once in the codebase — in the `Literal[...]` alias or Enum that owns it. Every other site — producer, consumer, boundary — references the symbol, never retypes the string.**

Examples below use a generic str-mixin enum `Kind` with members `Kind.TEXT`/`Kind.UNKNOWN` (values `"text"`/`"unknown"`) — substitute whatever closed type the project at hand owns (a provider name, a question type, a verdict, a status).

"Every other site" means ALL of these, not just typed function signatures:

| Site kind | Wrong | Right |
|---|---|---|
| **Producer** (function returning the value) | `def detect(...) -> str: return 'text'` | `def detect(...) -> Kind: return Kind.TEXT` |
| **Consumer** (comparison/dispatch) | `if item.kind == "unknown":` | `if item.kind is Kind.UNKNOWN:` |
| **Assignment/init** | `kind = 'unknown'` | `kind = Kind.UNKNOWN` |
| **Log/label emission** | `labels.append("text")` | `labels.append(Kind.TEXT.value)` |
| **Cross-language boundary** (JS blob, SQL, subprocess arg — can't import the symbol) | literal retyped in the foreign string | interpolate at build time: `f"... === '{Kind.TEXT.value}'"` / SQL parameter `(Kind.TEXT.value,)` |

Why producers are the critical site: a bare literal in a producer is invisible to every checker — the string flows into storage and dispatch, and a typo (or a later rename of the canonical value) produces **silently dead branches and silently miscategorized rows**, not an error. The failure surfaces far from the cause, looking like a data bug. (Real instance of this failure: a scraper whose HTML classifiers returned bare `'fill_blank'`-style strings untyped against its `QuestionType` enum — a mismatched string in one dispatch site made that branch silently unreachable for months.)

Two enforcement layers must BOTH hold:
1. **Producers/consumers typed with the symbol** — mypy turns a typo into a static error; an str-mixin Enum member is a drop-in `str`, so DB writes, JSON, and comparisons keep working unchanged.
2. **Validation boundary armed** — the model/dataclass field is typed with the closed type ONLY. A `field: Kind | str` union ("accept both during migration") disarms validation completely: any string passes forever. Migration escape hatches must carry a removal condition and die when it's met; convert legacy strings inside a validator (`from_string` with explicit fallback), never by widening the field type.

Boundary caveat for generated foreign code (JS/SQL templates): interpolation freezes the value at build time — that is correct for constants, but it means the template must be rebuilt wherever it was cached if the canonical value changes. Prefer building the foreign snippet in one place next to the type it mirrors.

---

## 6. Anti-patterns

| Anti-pattern | Symptom | Fix |
|---|---|---|
| `if name == "ollama": ... if name == "deepseek":` chain | Adding a third provider touches N sites | Replace with `_DISPATCH` dict |
| `name: str` for a closed set | Typo at call site is a runtime error, not a mypy error | `name: ProviderName` |
| Prose enumerating valid values | `"ollama"` or `"deepseek"` duplicated in docstring | Drop enumeration; keep default only |
| `__doc__` mutation for dynamic values | `get_provider.__doc__ = get_provider.__doc__.format(...)` | Never — breaks Sphinx/IDE introspection |
| `Enum` where `Literal` suffices | No methods needed, small stable set, rest of codebase uses `Literal` | Switch to `Literal`; `Enum` is heavier than needed |
| Bare literal in a producer | `return 'text'` with `-> str` — typo/rename silently miscategorizes data | Return the symbol; annotate with the closed type (§5) |
| Disarmed validation union | `field: Kind \| str  # accept both during migration` — any string passes, forever | Field typed `Kind` only; legacy strings converted in a validator with explicit fallback |
| Literal retyped in foreign code | Same string hand-copied into a JS blob / SQL query | Interpolate `.value` at build time from the owning symbol (§5) |
