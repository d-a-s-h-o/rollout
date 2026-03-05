//META:title Rollout
//META:description A simple pipeline-based static site generator

Rollout
=======

A simple, pipeline-based static site generator written in shell. No frameworks, no config DSLs — just markdown files, numbered shell scripts, and a build directory.

## Quick Start

```
git clone https://github.com/d-a-s-h-o/rollout.git
cd rollout
go run rollout.go
```

Your site will be in `build/latest`.

## How It Works

Write your content in markdown under `site/`. Rollout copies it into a timestamped build directory and runs each script in `stages/` in order — converting markdown to HTML, applying templates, minifying output, and generating an RSS feed.

The entire pipeline is visible and editable. Every stage is a standalone shell script you can modify, replace, or extend.

## Features

- **Markdown to HTML** — Write in plain markdown, get a complete website
- **Template system** — Header, footer, and meta templates in `tmpl/`
- **Blog posts** — Drop `.md` files in `p/` and they appear automatically
- **RSS generation** — Feed built from your posts
- **Minification** — HTML output is minified for production
- **Versioned builds** — Every build is timestamped; `build/latest` always points to the newest

## Source

The full source is on GitHub at <a href="https://github.com/d-a-s-h-o/rollout" target="_blank">d-a-s-h-o/rollout</a>. It's the same code used to generate this site.

## Posts

<ul id="posts">
{{#posts}}
<li><a href="{{post_href}}">{{post_title}}</a></li>
{{/posts}}
</ul>
