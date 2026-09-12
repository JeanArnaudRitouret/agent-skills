---
name: python-code-modification
description: Programmatically editing, deleting, or relocating blocks of Python source code — locating function/class/method boundaries by scanning source text, bulk-refactoring multiple files, inserting import lines. TRIGGER when writing any script that rewrites .py files.
---

# Python Code Modification

Apply this skill when:
- Writing scripts that programmatically edit, delete, or relocate blocks of Python source code
- Locating function, class, or method boundaries by scanning source text
- Bulk-refactoring multiple Python files (adding imports, replacing signatures, collapsing duplicates)
- Inserting `import` or `from ... import` lines into existing Python files

---

## 1. Multi-line typed signatures — a pitfall for line-based source editing

A typed `def` with several parameters wraps onto multiple lines. PEP 8 places the closing paren at the **same indentation level as `def`** (column 0 for top-level functions), and PEP 484 puts the return-type annotation on that same closing line:

```python
def save_dataframe_to_raw(
    client: CogniteClient,
    db_name: str,
    sorting_field: str,
) -> None:                 # ← column 0, non-whitespace
    dataframe = ...        # ← function body (indented)
```

**The trap:** a script that identifies "end of function" as "first column-0 non-empty line after `def`" will terminate at `) -> None:` — treating it as the next top-level statement. The `def` header lines get deleted; the entire function body is left behind as orphaned, unparseable code. The file then fails with `SyntaxError: invalid syntax` at `) -> None:`.

This same trap applies to:
- Multi-line decorators (`@app.route(\n    "/path",\n)`)
- Multi-line class signatures with generics (`class Foo(\n    Generic[T],\n):`)
- Multi-line `if`/`while` conditions wrapped in implicit parens

### Correct approach 1 — `ast` module (preferred)

Parse the file into an AST and read exact line ranges from the node:

```python
import ast

def find_function_range(src: str, name: str) -> tuple[int, int]:
    """Return (start_line, end_line) as 0-based indices into src.splitlines()."""
    tree = ast.parse(src)
    for node in ast.walk(tree):
        if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)):
            if node.name == name:
                return node.lineno - 1, node.end_lineno  # end_lineno is inclusive
    raise ValueError(f"Function {name!r} not found")

def remove_function(src: str, name: str) -> str:
    start, end = find_function_range(src, name)
    lines = src.splitlines(keepends=True)
    # Also remove any decorator lines immediately above
    while start > 0 and lines[start - 1].lstrip().startswith("@"):
        start -= 1
    # Trim blank lines preceding the block
    while start > 0 and lines[start - 1].strip() == "":
        start -= 1
    del lines[start:end]
    return "".join(lines)
```

`ast.parse` handles all Python grammar, including multi-line signatures, decorators, nested functions, and string literals.

### Correct approach 2 — paren-balance tracking (line-based fallback)

If you must stay line-based (e.g., the file has syntax errors and `ast.parse` fails), track the paren depth manually:

```python
def find_function_end(lines: list[str], def_line_idx: int) -> int:
    """Return the index of the first line AFTER the function body."""
    depth = 0
    in_signature = True
    for i, line in enumerate(lines[def_line_idx:], start=def_line_idx):
        depth += line.count("(") - line.count(")")
        if in_signature and depth == 0:
            in_signature = False  # signature closed; body starts on next line
            continue
        if not in_signature:
            # Body ends at the first column-0 non-empty line that isn't
            # a continuation from within the body itself.
            if i > def_line_idx and line and not line[0].isspace() and line.strip():
                return i
    return len(lines)
```

The key difference from the naive heuristic: the column-0 check is only applied **after** `depth` has returned to 0 (i.e., after the closing `)` of the signature has been consumed).

---

## 2. Adding imports — paren-aware placement

When injecting `from X import Y`, two traps:

**Trap A — duplication:** always check for an existing import before inserting.

**Trap B — insertion inside a multi-line import block.** If the last `from` line before the insertion point opens a parenthesised block (`from X import (\n    A,\n    B\n)`), inserting immediately after that `from` line lands *inside* the block and produces a `SyntaxError`. The naive "find last `from`/`import` line" heuristic fires on the opening `from` of the block, not its closing `)`.

**Correct approach — track paren depth from the top:**

```python
IMPORT_LINE = "from utils_cdf_operation import save_dataframe_to_raw\n"

def add_import_if_missing(src: str) -> str:
    if IMPORT_LINE.strip() in src:
        return src
    lines = src.splitlines(keepends=True)

    # Find the last line of the import block, accounting for multi-line imports.
    depth = 0
    in_import = False
    last_import_end = 0

    for i, line in enumerate(lines):
        stripped = line.strip()
        if not stripped:
            continue
        is_col0 = not line[0].isspace()
        depth += line.count("(") - line.count(")")

        if is_col0 and (stripped.startswith("import ") or stripped.startswith("from ")):
            in_import = True

        if in_import:
            last_import_end = i
            if depth == 0:
                in_import = False
        elif is_col0 and depth == 0 and not stripped.startswith("#"):
            break  # first non-import column-0 statement — stop here

    lines.insert(last_import_end + 1, IMPORT_LINE)
    return "".join(lines)
```

This correctly places the new import after the closing `)` of any multi-line import block.

---

## 3. Verification checklist after any bulk source edit

Always run these three checks before declaring success:

```bash
# 1. Syntax validity — every touched file must parse
for f in path/to/dir/*.py; do
    python3 -m py_compile "$f" || echo "FAIL: $f"
done

# 2. Structural invariant — confirm the target def appears exactly N times
grep -rn "def target_function" path/to/dir/

# 3. Orphan check — if deleting a block, confirm no signature remnants remain
grep -rlP '^\) -> None:' path/to/dir/*.py   # expect: empty
```

Never report a bulk refactor complete without passing all three.
