//META:title About
//META:description About Rollout — a pipeline-based static site generator
About
=====

## What is Rollout?

Rollout is a simple, pipeline-based static site generator. It converts a directory of markdown files into a fully built website using a series of shell script stages. There is no framework, no config DSL, and no magic — just files, scripts, and a defined build order.

The source code is available at <a href="https://github.com/d-a-s-h-o/rollout" target="_blank">d-a-s-h-o/rollout</a>.

## How It Works

The build process runs numbered **stage scripts** in order. Each stage transforms the build directory in place:

1. **00-depends.sh** — Checks that required tools exist
2. **01-posts.sh** — Collects blog posts and generates post listings
3. **01-projects.sh** — Collects projects from the `~/` directory (if you're showcasing projects) and generates project listings
4. **02-http.sh** — Converts `.md` files to full HTML pages using templates
5. **03-removemd.sh** — Removes leftover `.md` files from the build
6. **04-minify.sh** — Minifies the HTML output
7. **05-rss.sh** — Generates the RSS feed

Each build gets a timestamped directory under `build/`, with `build/latest` always pointing to the most recent.

## Project Structure

- **site/** — Source markdown files and assets
- **stages/** — Numbered pipeline scripts executed in order
- **tmpl/** — HTML templates (header, footer, meta)
- **util/** — Build utilities (`mdtohtml`, `minify`)
- **build/** — Output directory for generated sites

## Markdown Features

Everything below is written in plain markdown processed by Rollout. It serves as both documentation and a live demonstration.

### Text Formatting

This is **bold text**, this is *italic text*, and this is ***bold and italic***. You can also use ~~strikethrough~~ to indicate deleted content.

### Links

An inline link looks like this: [Rollout on GitHub](https://github.com/d-a-s-h-o/rollout).

### Lists

Unordered:

- First item
- Second item
  - Nested item
  - Another nested item
- Third item

Ordered:

1. Clone the repo
2. Ensure `mdtohtml` and `minify` are in `util/`
3. Run `go run rollout.go`
4. Check `build/latest`

### Blockquotes

> The idea behind Rollout is that your build pipeline is just a series of scripts.
> No plugins, no themes, no dependency trees — just shell.

### Code

Inline code: `go run rollout.go`

A fenced code block:

```
#!/bin/sh
set -e
find "$_BUILDDIR" -name '*.md' | while IFS= read -r file; do
    "$_UTILDIR"/mdtohtml < "$file" > "${file%.md}.html"
done
```

### Headings

Headings from `#` through `######` are supported. This page uses `##` for sections and `###` for subsections.

### Horizontal Rules

---

### Images

Images use standard markdown syntax. For example, the site favicon:

![favicon](/i/favicon.png)

### Tables

| Variable | Purpose |
|----------|---------|
| `_BUILDDIR` | Current build output directory |
| `_SITEDIR` | Source site files |
| `_STAGEDIR` | Pipeline stage scripts |
| `_UTILDIR` | Build utilities |

### META Directives

Rollout uses special `//META:` comments at the top of each markdown file to set page metadata:

```
//META:title Page Title
//META:description A short description for the page
//META:date 2026-01-01
//META:updated 2026-01-02
```

These are stripped from the output and injected into the HTML templates during the `02-http` stage.
