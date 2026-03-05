#!/bin/sh
set -e
# Remove source .md files from build output (they've been converted to .html)

[ -n "$_BUILDDIR" ] || { printf '[03-removemd] ERROR: _BUILDDIR not set\n' >&2; exit 1; }
[ -d "$_BUILDDIR" ] || { printf '[03-removemd] ERROR: _BUILDDIR does not exist: %s\n' "$_BUILDDIR" >&2; exit 1; }

_count="$(find "$_BUILDDIR" -iname '*.md' | wc -l)"
find "$_BUILDDIR" -iname '*.md' -exec rm -f {} +
