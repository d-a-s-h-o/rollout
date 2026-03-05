//META:title Rollout
//META:description A pipeline-based static site generator written in shell

Rollout
=======

A simple static site generator that turns markdown files into a website using a pipeline of shell scripts.

## Overview

Rollout doesn't try to be a framework. It copies your `site/` directory into a timestamped build folder and runs numbered stage scripts against it in order. Each stage does one thing — convert markdown, apply templates, minify output, generate RSS. The result is a fully static site in `build/latest`.

## Stack

- **Shell** — POSIX sh stages, runnable anywhere
- **Go** — Build orchestrator (`rollout.go`)
- **mdtohtml** — Markdown to HTML conversion
- **minify** — HTML minification

## Features

- Numbered pipeline stages executed in sort order
- Mustache-style template expansion for posts and projects
- META directives for per-page title, description, date
- Navigation with active tab detection and breadcrumbs
- Reading time estimation
- RSS feed generation
- Versioned builds with `latest` symlink

## Links

- Source: <a href="https://github.com/d-a-s-h-o/rollout" target="_blank">d-a-s-h-o/rollout</a>
