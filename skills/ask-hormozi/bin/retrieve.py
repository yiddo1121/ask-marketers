#!/usr/bin/env python3
"""
Retrieves the most relevant Alex Hormozi transcript sections for a query.

Usage: retrieve.py "<question>" [--top N] [--max-words N]

Same TF scoring as ask-mark's retriever, just pointed at the Hormozi corpus.
"""

import argparse, os, re, sys
from collections import Counter

CORPUS = os.path.expanduser("~/.claude/corpora/alex-hormozi.txt")

STOP = set("""
a an and are as at be been being but by do does did for from had has have he her him his how i if in into is it its
just me my no not of on one or our ours so some such than that the their them then there these they this those to
us was we were what when where which who whom why will with would you your yours about would say think
hormozi alex video tell me thing things stuff really like would also lot
""".split())

def load_videos():
    if not os.path.exists(CORPUS):
        sys.exit(f"corpus not found at {CORPUS} - run yt-dlp + clean pipeline first")
    with open(CORPUS) as f:
        text = f.read()
    parts = re.split(r'(?m)^===== ', text)
    videos = []
    for p in parts:
        if not p.strip(): continue
        first_line, _, body = p.partition('\n')
        title = first_line.strip().rstrip('=').strip()
        m = re.match(r'(\d{8})_(.+?)\s*\[([^\]]+)\]', title)
        if m:
            date, name, vid = m.groups()
            pretty = name.replace('_', ' ').strip()
            url = f"https://youtu.be/{vid}"
            display_date = f"{date[:4]}-{date[4:6]}-{date[6:]}"
        else:
            pretty = title
            url = ""
            display_date = ""
        videos.append({
            'title': pretty,
            'date': display_date,
            'url': url,
            'text': body.strip(),
        })
    return videos

def tokenize(s):
    return [w for w in re.findall(r"[a-z']+", s.lower()) if w not in STOP and len(w) > 2]

def score(video, query_tokens):
    text_tokens = tokenize(video['text'])
    if not text_tokens: return 0
    counts = Counter(text_tokens)
    s = 0
    for q in query_tokens:
        if counts[q]:
            s += 1 + (counts[q] ** 0.5)
    title_tokens = tokenize(video['title'])
    for q in query_tokens:
        if q in title_tokens:
            s += 5
    return s

def excerpt_around_hits(text, query_tokens, max_words=2000):
    words = text.split()
    if len(words) <= max_words:
        return text
    hits = []
    for i, w in enumerate(words):
        wl = re.sub(r"[^a-z']", "", w.lower())
        if wl in query_tokens:
            hits.append(i)
    if not hits:
        return ' '.join(words[:max_words]) + ' [...truncated]'
    center = hits[len(hits) // 2]
    half = max_words // 2
    start = max(0, center - half)
    end = min(len(words), start + max_words)
    start = max(0, end - max_words)
    prefix = '[...] ' if start > 0 else ''
    suffix = ' [...]' if end < len(words) else ''
    return prefix + ' '.join(words[start:end]) + suffix

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('query')
    ap.add_argument('--top', type=int, default=3)
    ap.add_argument('--max-words', type=int, default=2000)
    ap.add_argument('--titles-only', action='store_true')
    args = ap.parse_args()

    videos = load_videos()
    qtokens = tokenize(args.query)
    if not qtokens:
        sys.exit("query has no usable tokens after stop-word removal")

    ranked = sorted(videos, key=lambda v: score(v, qtokens), reverse=True)
    top = [v for v in ranked if score(v, qtokens) > 0][:args.top]

    if not top:
        sys.exit(f"no matches found for: {args.query}")

    if args.titles_only:
        for v in top:
            print(f"[{v['date']}] {v['title']}  ({v['url']})  score={score(v, qtokens):.2f}")
        return

    print(f"# Alex Hormozi — top {len(top)} matches for: {args.query}\n")
    print(f"_(scored from {len(videos)} videos by query term frequency)_\n")
    for v in top:
        print(f"\n## [{v['date']}] {v['title']}")
        print(f"{v['url']}\n")
        print(excerpt_around_hits(v['text'], qtokens, args.max_words))
        print()

if __name__ == '__main__':
    main()
