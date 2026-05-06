# Agent Guide — The Comfy Seat

Hugo-based personal blog deployed to Netlify. This file documents the conventions, gotchas, and workflows that agents need to know.

---

## Running the site locally

The repo uses a Nix devshell. Enter it with `nix develop`, then use the helper commands:

| Command | What it does |
|---|---|
| `serve` | `hugo server --watch --buildDrafts --buildFuture` |
| `build` | `hugo --minify` (production) |
| `build-preview` | `hugo --minify --buildDrafts --buildFuture` |
| `clean` | Delete `public/` and `resources/` |
| `new-post <slug>` | Scaffold a new post bundle (`content/posts/DATE-SLUG/index.md`) |
| `add-post-image <src> [slug]` | Convert image to WebP, auto-select quality, place in post bundle |
| `cwebp -q 85 input.png -o output.webp` | Manual WebP conversion (libwebp) |
| `magick input.png -resize 1200x output.webp` | Manual resize + convert with ImageMagick |

If Hugo is not in PATH outside the devshell, invoke it as:
```
nix run nixpkgs#hugo -- <args>
```

The dev server runs at `http://localhost:1313/`.

---

## SCSS / CSS pipeline

- Source: `assets/css/` (`main.scss` imports `_theme.scss`, `_author-sidebar.scss`, `_syntax-highlighting.scss`)
- Transpiler: **libsass** (built into Hugo Extended) — **not Dart Sass**
- Use `@import`, never `@use` — `@use` is Dart Sass-only and fails silently with libsass
- If CSS looks wrong after a change, delete `resources/` to clear Hugo's asset cache

---

## Vendor / third-party assets (self-hosted)

All third-party assets are self-hosted to eliminate external CDN dependencies. Do not add new CDN links without also downloading the files locally.

| Asset | Version | CSS | JS |
|---|---|---|---|
| jQuery | 3.7.1 | — | `static/assets/js/vendor/jquery.min.js` |
| Materialize | 1.0.0 | `static/assets/css/vendor/materialize.min.css` | `static/assets/js/vendor/materialize.min.js` |
| Fancybox | 3.5.7 | `static/assets/css/vendor/jquery.fancybox.min.css` | `static/assets/js/vendor/jquery.fancybox.min.js` |
| Font Awesome | 6.7.2 | `static/assets/css/vendor/fontawesome.all.min.css` | — |
| Material Icons | v145 | `static/assets/css/vendor/material-icons.css` | — |

Font Awesome and Material Icons webfonts live in `static/assets/webfonts/`. The Font Awesome CSS references them via `../webfonts/` (relative to the CSS file location), which resolves correctly when served. The Material Icons CSS uses an absolute path (`/assets/webfonts/material-icons.woff2`).

**To update Material Icons:** fetch `https://fonts.googleapis.com/icon?family=Material+Icons` with a modern browser User-Agent to get the current woff2 URL, download it to `static/assets/webfonts/material-icons.woff2`, and update the version note here.

**To update a vendor dependency:**
1. Download the new version to the same path
2. Update the version number in this file
3. For Font Awesome: also re-download all `webfonts/` files at the new version

---

## Materialize CSS — version-specific notes

The site uses Materialize **1.0.0**. Key differences from the 0.x series that affect templates and JS:

- Side navigation attribute: `data-target` (not `data-activates`)
- Side navigation class: `sidenav` (not `side-nav`)
- JS initialization: `M.Sidenav.init(el)` (not `$(...).sideNav()`)
- `Materialize.fadeInImage()` was removed; content fade-in is handled via CSS animation in `_theme.scss`

---

## Hugo configuration (hugo.toml)

### Footer social icons

Footer links are fully config-driven. Adding a `[[params.footer.links]]` entry is all that's needed to show an icon. The SVG filename is derived from `label | lower` (e.g. `label = 'GitHub'` → `/assets/images/social-github.svg`).

Fields:
- `label` — required; determines SVG filename and display title
- `url` — full URL for the link; if absent, icon renders without a link
- `url_prefix` — combined with `username` to build the URL (e.g. `https://www.linkedin.com/in/`)
- `username` — used with `url_prefix`, and in the default title (`username on label`)
- `title` — overrides the default title/alt text

Icons with `rel="me"` (identity verification): Mastodon, Yakihonne, Primal. Update the `$me` slice in `layouts/partials/footer.html` if adding more.

### Social icon SVG style

All social icons follow the same visual style: dark circle background (`fill="#010002"`) with a white logomark. SVGs live in `static/assets/images/social-<label-lowercased>.svg`.

---

## Content

Posts live in `content/posts/` and are named `YYYY-MM-DD-slug.markdown` or `.md`.

Required front matter:
```yaml
---
title: "Post Title"
slug: "post-slug"
date: YYYY-MM-DD
author: gene
---
```

Optional:
- `draft: true` — hides post from production builds; visible with `--buildDrafts`
- `lastmod: YYYY-MM-DD` — shown as "Updated" date if different from `date`; auto-populated from git history via `enableGitInfo = true`
- `description:` — used for meta description and post preview; falls back to Hugo's auto-summary
- `image.path`, `image.alt`, `image.width`, `image.height` — header image shown at top of post and in list view

Use `<!--more-->` to control where the list-page excerpt cuts off.

---

## Author data

Authors are defined in `data/authors.yml`. Each author's content page lives in `content/authors/<short_name>.md` and must include `author: <short_name>` in front matter so the sidebar shows that author's profile.

Supported author fields: `name`, `short_name`, `avatar`, `location`, `github`, `linkedin`, `mastodon` (with `instance` + `username` sub-keys), `nostr` (npub string — links to Yakihonne profile in sidebar), `twitter`.

---

## Netlify

- Build command (production): `hugo --minify`
- Build command (previews): `hugo --minify --buildDrafts --buildFuture`
- Publish directory: `public/`
- Hugo version pinned via `HUGO_VERSION` and `HUGO_EXTENDED = "true"` in `netlify.toml`
- `.mise.toml` sets `ruby.compile = false` so Netlify's build image uses a precompiled Ruby binary instead of compiling from source (saves ~3 minutes per build)

---

## Images

### Current setup
All posts are **page bundles**: `content/posts/SLUG/index.md` with images co-located in the same directory. This lets Hugo's image processing pipeline resize header images automatically.

The templates cap displayed images to 960 px wide (the content column width) via `$.Resources.GetMatch` + `.Resize "960x q90"` — only for images that are actually wider than 960 px. Smaller images are served as-is; the OG image tag always uses the original full-resolution file.

`static/assets/images/posts/` is now empty. Do not put new post images there.

### Adding images to a post
Use the `add-post-image` devshell command — it detects dimensions, chooses q85 or q90 automatically, prints a dimension analysis, strips all EXIF metadata (GPS location, camera info, timestamps — `cwebp` drops these by default), and outputs the front matter snippet:

```bash
add-post-image source.jpg                        # prompts for target bundle
add-post-image source.jpg 2026-05-04-my-post     # targets that bundle directly
```

If you need manual control (resize before convert, etc.):
```bash
# Resize to 1200px wide first, then convert
magick source.png -resize 1200x resized.jpg
cwebp -q 85 resized.jpg -o content/posts/SLUG/output.webp

# For images < 960 px wide
cwebp -q 90 source.png -o content/posts/SLUG/output.webp
```

Reference in front matter:
```yaml
image:
  path: 'output.webp'
  alt: 'Descriptive alt text'
  width: 1200   # optional, for og:image:width
  height: 630   # optional, for og:image:height
```

Inline images in the post body use relative paths: `![alt text](output.webp)`.

### Quality guidance
- **Images ≥ 960 px wide**: use `-q 85`; Hugo downscales to 960 px for display, so the quality loss is minimal.
- **Images < 960 px wide**: use `-q 90`; the browser CSS-upscales them to fill the column, making compression artifacts more visible.
- **Screenshots and diagrams** (text-heavy): prefer lossless or very high quality (`-q 95`) — lossy encoding blurs fine text.
- **Target dimensions**: 1200×630 px covers both in-site display (downscaled to 960 px) and social share cards (OG/Twitter expect ~1200×628).

---

## Known gotchas

- **Stale CSS after transpiler changes**: delete `resources/` if Hugo serves old or empty CSS
- **`@use` breaks the build silently**: libsass doesn't support `@use`; use `@import` instead
- **Netlify installs Ruby regardless**: the new `noble-new-builds` image always installs Ruby via mise; `.mise.toml` makes this fast by using precompiled binaries
- **Fancybox 4.x requires a paid license**: stay on 3.5.7
- **Font Awesome JS vs CSS**: the site uses the CSS version; do not switch back to the JS version (`all.js`) as it causes layout shift and is heavier
