#!/bin/sh
set -e
# Auto-generate project listings by expanding {{#projects}}...{{/projects}} blocks
# Runs BEFORE 02-http.sh so the markdown+HTML mix gets converted properly
#
# In any .md file, content between {{#projects}} and {{/projects}} is treated as a
# per-project template. Available fields: {{project_href}} {{project_id}} {{project_title}} {{project_desc}}
# Projects are listed alphabetically by filename.

err() { printf "[01-projects] ERROR: %s\n" "$*" >&2; }

PROJDIR="$_BUILDDIR/~"
if [ ! -d "$PROJDIR" ]; then
    # No projects directory — not an error, just nothing to do
    exit 0
fi

# --- Build list of project files (alphabetical) ---
PROJ_FILES="$(find "$PROJDIR" -maxdepth 1 -name '*.md' ! -name 'index.md' -print | sort)"
if [ -z "$PROJ_FILES" ]; then
    exit 0
fi

# --- Expand {{#projects}}...{{/projects}} blocks in a target file ---
expand_projects() {
    _target="$1"
    if [ ! -f "$_target" ]; then
        err "Target file not found: $_target"
        return 1
    fi

    # Extract the template between {{#projects}} and {{/projects}}
    _tmpl="$(sed -n '/{{#projects}}/,/{{\/projects}}/{//!p;}' "$_target")"
    if [ -z "$_tmpl" ]; then
        return 0  # No template block — nothing to expand
    fi

    # Build expanded output into a temp file
    _expanded="${_target}.expanded.tmp"
    : > "$_expanded"

    _count=0
    for file in $PROJ_FILES; do
        slug="$(basename "$file" .md)"

        project_id="$slug"

        project_title="$(grep '//META:title' "$file" | sed 's/^\/\/META:title //' | head -1 || true)"
        [ -z "$project_title" ] && project_title="$slug"

        project_desc="$(grep '//META:description' "$file" | sed 's/^\/\/META:description //' | head -1 || true)"
        [ -z "$project_desc" ] && project_desc=""

        project_href="/~/${slug}.html"

        printf '%s\n' "$_tmpl" | \
            sed -e "s|{{project_href}}|${project_href}|g" \
                -e "s|{{project_id}}|${project_id}|g" \
                -e "s|{{project_title}}|${project_title}|g" \
                -e "s|{{project_desc}}|${project_desc}|g" \
            >> "$_expanded"
        _count=$((_count + 1))
    done

    # Replace the block in the target file
    _INSERT_FILE="$_expanded"
    export _INSERT_FILE
    awk '
        /\{\{#projects\}\}/ { skip=1; next }
        /\{\{\/projects\}\}/ {
            while ((getline line < ENVIRON["_INSERT_FILE"]) > 0)
                print line
            close(ENVIRON["_INSERT_FILE"])
            skip=0; next
        }
        !skip { print }
    ' "$_target" > "${_target}.tmp" || { err "awk failed expanding projects in $_target"; rm -f "$_expanded"; return 1; }
    mv "${_target}.tmp" "$_target"
    rm -f "$_expanded"
}

expand_projects "$PROJDIR/index.md"
