#!/bin/sh
set -e
# Minify CSS and HTML in the build output

err() { printf '[04-minify] ERROR: %s\n' "$*" >&2; }

[ -n "$_BUILDDIR" ] || { err '_BUILDDIR not set'; exit 1; }
[ -n "$_UTILDIR" ]  || { err '_UTILDIR not set'; exit 1; }
[ -d "$_BUILDDIR" ] || { err "_BUILDDIR does not exist: $_BUILDDIR"; exit 1; }

# Minify CSS (from the already-written build copy, not source)
if [ -f "$_BUILDDIR/style.css" ]; then
    "$_UTILDIR"/minify --type css < "$_BUILDDIR/style.css" > "$_BUILDDIR/style.css.tmp" || { err 'CSS minification failed'; exit 1; }
    mv "$_BUILDDIR/style.css.tmp" "$_BUILDDIR/style.css"
fi

# Minify HTML files
_fail=0
find "$_BUILDDIR" -type f -name '*.html' | while IFS= read -r f; do
    if ! "$_UTILDIR"/minify --type html < "$f" > "${f}.tmp" 2>/dev/null; then
        printf '[04-minify] WARN: failed to minify %s\n' "$f" >&2
        rm -f "${f}.tmp"
        continue
    fi
    mv "${f}.tmp" "$f"
done
