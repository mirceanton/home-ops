---
name: hyperframes-graphics
description: "Use when making a YouTube thumbnail, title card, still graphic, or short animation for a video. Renders HyperFrames HTML compositions to PNG/MP4/WebM/GIF locally in this container."
version: 1.0.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [youtube, thumbnail, graphics, animation, hyperframes, video]
---

# HyperFrames Graphics

HyperFrames renders **video and still images from HTML**: a composition is an HTML file whose DOM
declares its timing with `data-*` attributes. The whole toolchain (CLI + headless Chrome + FFmpeg)
is installed in this container and renders locally — no account, no credits, no network round-trip.

## When to use

- A thumbnail or title-card draft for a video (packaging decisions, A/B directions)
- A still image / lower third / channel graphic
- A short animation: overlay sting, animated stat, chapter bumper, GIF loop
- NOT for editing existing footage (use the editing profile), and not for publishing to YouTube
  (the youtube-assistant profile never publishes).

## Invoke it

```bash
hyperframes <command>            # already on PATH; the wrapper sets its own library path
hyperframes init <name>          # optional scaffold for a fresh project
hyperframes lint <dir>           # fast, no browser, catches structural mistakes
hyperframes check  <dir>         # lint + runtime + layout + motion + contrast gate
hyperframes snapshot <dir> --at 0 --no-end -o renders/thumbnail   # one still PNG
hyperframes render <dir> --format mp4 -q looks -o renders/clip.mp4
```

`hyperframes docs <topic>` prints the offline docs (`data-attributes`, `rendering`, `gsap`,
`compositions`, `examples`, `troubleshooting`). The upstream agent skills `hyperframes`,
`hyperframes-cli` and `media-use` are installed next to this one — load them for deep authoring
work instead of guessing attributes. `hyperframes lint`/`check` are the source of truth for whether
a composition is valid; run them before every render.

## Where the files go

Mircea's asset library and per-video folders live under `/Volumes/Projects/mirceanton` (NFS, shared
with the editing profile). Work **inside the video's own folder**, e.g.
`/Volumes/Projects/mirceanton/<video>/thumbnails/<direction>/`, keeping `index.html`, `assets/` and
`renders/` together, so the editing profile and Mircea can pick the draft up. Reuse the artwork,
logos, screenshots and footage already in the library instead of inventing placeholder assets — a
thumbnail should use the real hardware screenshot, not a drawing of one.

## Recipes

**Thumbnail / still (one PNG, 1280×720):**

```bash
hyperframes snapshot ./thumbnails/a --at 0 --no-end -o renders/thumbnail
# → renders/thumbnail/frame-00-at-0s.png  (plus contact-sheet.jpg for quick review)
```

**Animation (MP4, and WebM when it must sit over footage):**

```bash
hyperframes render ./clip --format mp4  -f 30 -q looks -o renders/clip.mp4
hyperframes render ./clip --format webm -f 30 -q looks -o renders/overlay.webm  # keeps alpha
```

GIF is best at 15 fps (`-f 15 --format gif --gif-loop 0`). `-q draft` while iterating, `-q looks`
(default) for a draft Mircea reviews, `-q delivery` for the final. A `png-sequence` render writes one
PNG per frame — useful for a frame Mircea picks, wasteful for a thumbnail.

## Composition contract (the parts that break renders)

```html
<div
  id="root"
  data-composition-id="thumb"
  data-start="0"
  data-duration="4"
  data-width="1280"
  data-height="720"
  data-no-timeline>
  <div id="title" class="clip" data-start="0" data-duration="4" data-track-index="0">…</div>
</div>
```

- Timed elements need **`class="clip"`** plus `data-start` / `data-duration` / `data-track-index`, or
  they render always-visible.
- Give every element a stable **`id`** — otherwise Studio (and future edits) cannot target it, and
  lint warns.
- Add **`data-no-timeline`** when the composition has no GSAP timeline. Without it every render waits
  out a fixed 45 s player-ready timeout.
- With GSAP, register the paused timeline under the exact composition id:
  `window.__timelines["thumb"] = tl;`.
- Reference **local** assets with relative paths (`./assets/shot.png`). Remote/expiring URLs and
  share-page links silently render blank. Never animate `width`/`height`/`top`/`left` directly on a
  `<video>` — wrap it and animate the wrapper.
- YouTube thumbnails: 1280×720 (16:9), and keep text clear of the bottom-right corner where the
  duration badge covers it.

## Verify before you hand it over

1. `hyperframes lint` — structure (fast)
2. `hyperframes snapshot --at <key times>` — then **look at the PNG** (vision) rather than assuming
3. `hyperframes render` — judge the rendered file, not the preview

## Environment notes

- Rendering is **software GL** on a shared 8 GiB pod: heavy `backdrop-filter`/shadow stacks are slow,
  and a long or effect-heavy clip can take minutes. Keep thumbnails simple; use `-q draft` while
  iterating.
- **No HeyGen account and no `HEYGEN_API_KEY` here**, so hosted voice/music and `cloud render` are
  unavailable; the local Kokoro TTS / MusicGen fallbacks are not installed either. Compose with
  typography, layout, code, charts and assets from the library — not narration. Caption/transcription
  work needs `whisper-cpp`, which is not installed.
- `/dev/shm` is 512 MiB (Chrome needs ≥256 MiB).
- Telemetry is disabled (`HYPERFRAMES_NO_TELEMETRY=1`).
- If `hyperframes` is missing, the `hyperframes-setup` init container install has not completed —
  check its log with `kubectl logs` / the pod's init containers; it retries on the next pod start.
