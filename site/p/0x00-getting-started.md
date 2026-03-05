//META:title Getting Started with Rollout
//META:description A guide to setting up and using Rollout to build a static site
//META:date 2026-03-05

Getting Started with Rollout
============================

This post walks through setting up Rollout from scratch — cloning the repo, understanding the structure, writing your first page, and running a build.

## Prerequisites

You need two utilities in the `util/` directory:

- **mdtohtml** — Converts markdown to HTML (<a href="https://github.com/gomarkdown/mdtohtml" target="_blank">gomarkdown/mdtohtml</a>)
- **minify** — Minifies HTML output (<a href="https://github.com/tdewolff/minify" target="_blank">tdewolff/minify</a>)

You also need **Go** installed to run `rollout.go`.

## Clone and Build

```
git clone https://github.com/d-a-s-h-o/rollout.git
cd rollout
go run rollout.go
```

The generated site will be at `build/latest`.

## Project Layout

```
site/       — Your markdown source files and assets
stages/     — Numbered shell scripts that form the build pipeline
tmpl/       — HTML templates (header, footer, meta, style)
util/       — Build tools (mdtohtml, minify)
build/      — Output directory (created automatically)
```

The only directories required by Rollout are `site/`, `stages/`, and `util/`.

## The Build Pipeline

Rollout copies `site/` into a new timestamped directory under `build/`, then runs every executable in `stages/` in sorted order:

| Stage | Script | Purpose |
|-------|--------|---------|
| 00 | `00-depends.sh` | Verify required tools exist |
| 01 | `01-posts.sh` | Collect posts and expand `{{#posts}}` blocks |
| 01 | `01-projects.sh` | Collect projects from `~/` |
| 02 | `02-http.sh` | Convert `.md` to full HTML pages with templates |
| 03 | `03-removemd.sh` | Remove leftover `.md` files from the build |
| 04 | `04-minify.sh` | Minify HTML output |
| 05 | `05-rss.sh` | Generate the RSS feed |

Each stage receives environment variables like `_BUILDDIR`, `_SITEDIR`, `_UTILDIR`, and `_ROOT` so it knows where everything is.

## Writing a Page

Create a `.md` file in `site/`. Start it with META directives:

```
//META:title My Page
//META:description A short summary
```

Then write your content in standard markdown below. The `02-http` stage strips the META lines, converts the markdown to HTML, and wraps it in the header/footer templates.

## Writing a Post

Posts live in `site/p/`. The filename determines sort order — posts are listed newest-first by reverse filename sort.

```
site/p/0x00-getting-started.md
site/p/0x01-another-post.md
```

Posts support additional META fields:

```
//META:title Post Title
//META:description A short description shown on post cards
//META:date 2026-03-05
//META:updated 2026-03-06
```

The **date** field enables a meta bar on the page showing the publication date, update date, and estimated reading time.

Any page with a `{{#posts}}...{{/posts}}` block will have it expanded with the post list. Available template fields:

- `{{post_href}}` — URL to the post
- `{{post_id}}` — Filename-based identifier
- `{{post_title}}` — Title from META
- `{{post_desc}}` — Description from META

## Templates

Templates live in `tmpl/` and use `{{placeholder}}` syntax:

- **meta.html** — The `<head>` section (`{{title}}`, `{{description}}`, `{{style}}`)
- **header.html** — Site header and navigation (`{{nav-home}}`, `{{nav-about}}`, `{{nav-projects}}`, `{{breadcrumbs}}`)
- **footer.html** — Page footer
- **style.css** — Copied into every build as `/style.css`

## Adding a Stage

To extend the pipeline, create a new script in `stages/` with an appropriate number prefix:

```
stages/06-deploy.sh
```

Make it executable (`chmod +x`) and it will run automatically on the next build. The script has access to all the standard environment variables.

## Cleaning Up

Old builds accumulate in `build/`. Use the clean script to remove them:

```
sh stages/scripts/clean.sh
```

That's it. Rollout stays out of your way — write markdown, run the build, and ship.
