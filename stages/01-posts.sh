#!/bin/sh
set -e
# Auto-generate post listings by expanding {{#posts}}...{{/posts}} blocks
# Runs BEFORE 02-http.sh so the markdown+HTML mix gets converted properly
#
# In any .md file, content between {{#posts}} and {{/posts}} is treated as a
# per-post template. Available fields: {{post_href}} {{post_id}} {{post_title}} {{post_desc}}
# Posts are listed newest-first (reverse filename sort).

err() { printf "[01-posts] ERROR: %s\n" "$*" >&2; }

POSTDIR="$_BUILDDIR/p"
if [ ! -d "$POSTDIR" ]; then
    # No posts directory — not an error, just nothing to do
    exit 0
fi

# --- Build list of post files (newest first) ---
POST_FILES="$(find "$POSTDIR" -maxdepth 1 -name '*.md' ! -name 'index.md' -print | sort -r)"
if [ -z "$POST_FILES" ]; then
    exit 0
fi

# --- Expand {{#posts}}...{{/posts}} blocks in a target file ---
expand_posts() {
    _target="$1"
    if [ ! -f "$_target" ]; then
        err "Target file not found: $_target"
        return 1
    fi

    # Extract the template between {{#posts}} and {{/posts}}
    _tmpl="$(sed -n '/{{#posts}}/,/{{\/posts}}/{//!p;}' "$_target")"
    if [ -z "$_tmpl" ]; then
        return 0  # No template block — nothing to expand
    fi

    # Build expanded output into a temp file
    _expanded="${_target}.expanded.tmp"
    : > "$_expanded"

    _count=0
    for file in $POST_FILES; do
        slug="$(basename "$file" .md)"

        post_id="$(echo "$slug" | sed -n 's/^\(0x[0-9a-fA-F]*\).*/\1/p')"
        [ -z "$post_id" ] && post_id="$slug"

        post_title="$(grep '//META:title' "$file" | sed 's/^\/\/META:title //' | head -1 || true)"
        [ -z "$post_title" ] && post_title="$slug"

        post_desc="$(grep '//META:description' "$file" | sed 's/^\/\/META:description //' | head -1 || true)"
        [ -z "$post_desc" ] && post_desc=""

        post_href="/p/${slug}.html"

        printf '%s\n' "$_tmpl" | \
            sed -e "s|{{post_href}}|${post_href}|g" \
                -e "s|{{post_id}}|${post_id}|g" \
                -e "s|{{post_title}}|${post_title}|g" \
                -e "s|{{post_desc}}|${post_desc}|g" \
            >> "$_expanded"
        _count=$((_count + 1))
    done

    # Replace the block in the target file
    _INSERT_FILE="$_expanded"
    export _INSERT_FILE
    awk '
        /\{\{#posts\}\}/ { skip=1; next }
        /\{\{\/posts\}\}/ {
            while ((getline line < ENVIRON["_INSERT_FILE"]) > 0)
                print line
            close(ENVIRON["_INSERT_FILE"])
            skip=0; next
        }
        !skip { print }
    ' "$_target" > "${_target}.tmp" || { err "awk failed expanding posts in $_target"; rm -f "$_expanded"; return 1; }
    mv "${_target}.tmp" "$_target"
    rm -f "$_expanded"
}

expand_posts "$_BUILDDIR/index.md"
expand_posts "$POSTDIR/index.md"
