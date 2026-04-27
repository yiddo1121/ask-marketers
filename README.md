# ask-marketers

Two Claude Code skills that channel **Mark Builds Brands** and **Alex Hormozi**
using their actual YouTube transcripts as the source. Ask either of them
anything and Claude pulls relevant excerpts and answers in their voice with
their frameworks.

- `/ask-mark` — Mark Builds Brands (95 videos, ~527k tokens)
- `/ask-hormozi` — Alex Hormozi (467 long-form videos, ~3.8M tokens)

Both ship with their full corpus bundled. No `yt-dlp`, no setup beyond running
the install script. Just clone, install, ask.

## Install

```bash
git clone https://github.com/YOUR_USERNAME/ask-marketers.git
cd ask-marketers
./install.sh
```

That's it. The script:
1. Copies the two skills into `~/.claude/skills/`
2. Copies the corpora into `~/.claude/corpora/`
3. Verifies retrieval works
4. Prints a CLAUDE.md routing block you can optionally paste into your
   global `~/.claude/CLAUDE.md` so any agent in any directory routes
   "ask mark" / "ask hormozi" correctly

## Use

In any Claude Code session:

```
/ask-mark how do i write a hook for an iOS app blocker
/ask-hormozi how do i price a £14.99 subscription against free competitors
/ask-mark what's wrong with my landing page approach
/ask-hormozi how should i structure a guarantee
```

Or just type `ask mark <question>` / `ask hormozi <question>` in plain
language — same thing.

## How it works

Each skill has:
- `SKILL.md` — the playbook Claude follows: workflow, the YouTuber's core
  frameworks, tone calibration
- `bin/retrieve.py` — a tiny Python TF-scoring retriever that scores each
  video by query-term frequency and returns the top N excerpts (with date
  and YouTube link) so Claude has the actual transcript to ground its
  answer in

Total corpus: ~16MB of plain-text transcripts across 562 videos.

## Update corpora

If you want fresher transcripts:

```bash
# install yt-dlp if needed: brew install yt-dlp
cd ask-marketers
./scripts/refresh-corpora.sh    # not bundled — see SKILL.md files for the exact yt-dlp command
```

Each `SKILL.md` includes the exact `yt-dlp` command for refreshing its
corpus from YouTube.

## License

MIT. Transcripts are auto-generated YouTube captions from public videos
(@MarkBuildsBrands and @AlexHormozi). All credit for the underlying ideas
belongs to Mark and Alex; this repo is just a retrieval wrapper that lets
you query their actual recorded thinking.
