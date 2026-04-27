#!/usr/bin/env bash
# Installs ask-mark and ask-hormozi Claude Code skills + their transcript corpora.
# Usage: ./install.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"
SKILLS_DIR="$CLAUDE_DIR/skills"
CORPORA_DIR="$CLAUDE_DIR/corpora"

echo "→ installing into $CLAUDE_DIR"

if [ ! -d "$CLAUDE_DIR" ]; then
  echo "  ✗ $CLAUDE_DIR not found. Is Claude Code installed?"
  echo "    install Claude Code first: https://claude.com/claude-code"
  exit 1
fi

mkdir -p "$SKILLS_DIR" "$CORPORA_DIR"

# skills
for skill in ask-mark ask-hormozi; do
  if [ -d "$SKILLS_DIR/$skill" ]; then
    echo "  ↻ $skill already exists, overwriting"
    rm -rf "$SKILLS_DIR/$skill"
  fi
  cp -R "$SCRIPT_DIR/skills/$skill" "$SKILLS_DIR/"
  chmod +x "$SKILLS_DIR/$skill/bin/retrieve.py"
  echo "  ✓ installed skill: $skill"
done

# corpora
for corpus in mark-builds-brands.txt alex-hormozi.txt; do
  cp "$SCRIPT_DIR/corpora/$corpus" "$CORPORA_DIR/"
  size=$(du -h "$CORPORA_DIR/$corpus" | cut -f1)
  echo "  ✓ installed corpus: $corpus ($size)"
done

# verify retrieval works
echo ""
echo "→ verifying retrieval"
if "$SKILLS_DIR/ask-mark/bin/retrieve.py" "test" --titles-only --top 1 > /dev/null 2>&1; then
  echo "  ✓ ask-mark retrieval works"
else
  echo "  ✗ ask-mark retrieval failed — check Python 3 is installed"
fi
if "$SKILLS_DIR/ask-hormozi/bin/retrieve.py" "test" --titles-only --top 1 > /dev/null 2>&1; then
  echo "  ✓ ask-hormozi retrieval works"
else
  echo "  ✗ ask-hormozi retrieval failed — check Python 3 is installed"
fi

# offer to append CLAUDE.md routing block (so plain-English "ask mark" routes
# correctly from any directory). idempotent — uses a marker comment.
CLAUDE_MD="$CLAUDE_DIR/CLAUDE.md"
MARKER="# ask-mark / ask-hormozi (channelled YouTubers)"
ROUTING_BLOCK="$(cat <<'EOF'

# ask-mark / ask-hormozi (channelled YouTubers)
- **ask-mark** (`~/.claude/skills/ask-mark/SKILL.md`) - channels Mark Builds Brands. Trigger: `/ask-mark`. Corpus: `~/.claude/corpora/mark-builds-brands.txt` (95 videos).
- **ask-hormozi** (`~/.claude/skills/ask-hormozi/SKILL.md`) - channels Alex Hormozi (Acquisition.com). Trigger: `/ask-hormozi`. Corpus: `~/.claude/corpora/alex-hormozi.txt` (467 long-form videos).

These are YouTubers, NOT contacts in your lifelog/iMessage. When you type `/ask-mark`, `/ask-hormozi`, say "ask mark", "ask hormozi", or "what would [name] say", invoke the matching Skill tool before doing anything else. Do NOT search lifelog contacts.
EOF
)"

echo ""
if [ -f "$CLAUDE_MD" ] && grep -qF "$MARKER" "$CLAUDE_MD"; then
  echo "→ CLAUDE.md routing already present, skipping"
else
  # auto-append if non-interactive (curl|bash style); else prompt
  if [ -t 0 ]; then
    printf "→ Append routing block to %s? [Y/n] " "$CLAUDE_MD"
    read -r reply
    reply="${reply:-Y}"
  else
    reply="Y"
  fi
  case "$reply" in
    [Yy]*)
      printf "%s\n" "$ROUTING_BLOCK" >> "$CLAUDE_MD"
      echo "  ✓ appended routing block to $CLAUDE_MD"
      ;;
    *)
      echo "  ↷ skipped — paste this into $CLAUDE_MD manually if you want plain-English routing:"
      printf "%s\n" "$ROUTING_BLOCK"
      ;;
  esac
fi

echo ""
echo "✅ installed."
echo ""
echo "Try: /ask-mark what makes a good landing page"
echo "Try: /ask-hormozi how do i price a subscription"
