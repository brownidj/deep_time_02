#!/bin/zsh

set -euo pipefail

TARGET_FILE="${1:-data/time_divisions.yaml}"

if [[ ! -f "$TARGET_FILE" ]]; then
  echo "ERROR: file not found: $TARGET_FILE"
  exit 1
fi

BACKUP_FILE="${TARGET_FILE}.bak.$(date +%Y%m%d_%H%M%S)"
cp "$TARGET_FILE" "$BACKUP_FILE"

echo "Backup created:"
echo "  $BACKUP_FILE"

python3 - "$TARGET_FILE" <<'PY'
from pathlib import Path
import re
import sys

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")
lines = text.splitlines()

paragraph_starters = (
    "Stratigraphically,",
    "Geologically,",
    "Biologically,",
    "Paleontologically,",
    "Etymologically,",
    "Paleoenvironmentally,",
    "Chronostratigraphically,",
    "Lithostratigraphically,",
    "From a stratigraphic perspective,",
    "From a paleontological perspective,",
    "From a paleoenvironmental perspective,",
    "From a geochronological perspective,",
    "In terms of temporal scale,",
    "At the scale",
    "Of particular stratigraphic importance",
    "The name",
    "The term",
    "The nomenclature",
    "The etymology",
    "The stage",
    "The epoch",
    "The period",
    "The era",
    "The eon",
    "This stage",
    "This epoch",
    "This period",
    "This era",
    "This eon",
    "This interval",
    "This boundary",
    "This nomenclature",
    "This subdivision",
    "This chronostratigraphic unit",
    "The significance",
    "The importance",
    "Understanding",
    "Consequently,",
    "Additionally,",
    "Its significance",
    "Its stratigraphic",
    "Its paleontological",
    "Its lower boundary",
    "Its upper boundary",
    "Its formalization",
    "The formalization",
    "The base",
    "The upper boundary",
    "The lower boundary",
)

def split_sentences(text):
    pattern = r"(?<=[.!?])\s+(?=[A-Z0-9])"
    return re.split(pattern, text.strip())

def paragraphise_block(block_lines, content_indent):
    raw = "\n".join(
        line[content_indent:] if len(line) >= content_indent else ""
        for line in block_lines
    )

    raw = re.sub(r"[ \t]{2,}", " ", raw)
    raw = re.sub(r"\n\s*\n+", "\n\n", raw)

    words_as_lines = []
    current = []

    for physical_line in raw.splitlines():
        stripped = physical_line.strip()
        if not stripped:
            if current:
                words_as_lines.append(" ".join(current).strip())
                current = []
            words_as_lines.append("")
        else:
            current.append(stripped)

    if current:
        words_as_lines.append(" ".join(current).strip())

    compact = "\n\n".join(
        part for part in words_as_lines if part != ""
    )

    sentences = split_sentences(compact)

    paragraphs = []
    current_paragraph = []

    for sentence in sentences:
        sentence = sentence.strip()
        if not sentence:
            continue

        starts_new = sentence.startswith(paragraph_starters)

        if starts_new and current_paragraph:
            paragraphs.append(" ".join(current_paragraph).strip())
            current_paragraph = [sentence]
        else:
            current_paragraph.append(sentence)

    if current_paragraph:
        paragraphs.append(" ".join(current_paragraph).strip())

    wrapped_lines = []
    indent_text = " " * content_indent
    width = 88 - content_indent

    for p_index, paragraph in enumerate(paragraphs):
        if p_index > 0:
            wrapped_lines.append("")

        words = paragraph.split()
        line = ""

        for word in words:
            candidate = word if not line else line + " " + word
            if len(candidate) <= width:
                line = candidate
            else:
                wrapped_lines.append(indent_text + line)
                line = word

        if line:
            wrapped_lines.append(indent_text + line)

    return wrapped_lines

out = []
i = 0
changed_blocks = 0

while i < len(lines):
    line = lines[i]
    out.append(line)

    if re.match(r"^\s*explanation:\s*\|\s*$", line):
        key_indent = len(line) - len(line.lstrip(" "))
        content_indent = key_indent + 2
        block = []
        i += 1

        while i < len(lines):
            next_line = lines[i]

            if next_line.strip() == "":
                block.append(next_line)
                i += 1
                continue

            next_indent = len(next_line) - len(next_line.lstrip(" "))

            if next_indent <= key_indent:
                break

            block.append(next_line)
            i += 1

        if block:
            out.extend(paragraphise_block(block, content_indent))
            changed_blocks += 1

        continue

    i += 1

path.write_text("\n".join(out) + "\n", encoding="utf-8")

print("Formatted explanation blocks:", changed_blocks)
print("Updated:", path)
PY

echo
echo "Now run:"
echo "  flutter test"