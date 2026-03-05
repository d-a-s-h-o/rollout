#!/bin/sh
set -e
# Convert .md files to full HTML pages with templates, nav, and breadcrumbs

err()  { printf "[02-http] ERROR: %s\n" "$*" >&2; }
warn() { printf "[02-http] WARN: %s\n" "$*" >&2; }

# Validate required env/files
[ -n "$_BUILDDIR" ] || { err "_BUILDDIR not set"; exit 1; }
[ -n "$_UTILDIR" ]  || { err "_UTILDIR not set"; exit 1; }
[ -n "$_ROOT" ]     || { err "_ROOT not set"; exit 1; }

for _tmpl_file in meta.html header.html footer.html style.css; do
    [ -f "$_ROOT/tmpl/$_tmpl_file" ] || { err "Template missing: tmpl/$_tmpl_file"; exit 1; }
done

META="$(cat "$_ROOT"/tmpl/meta.html)"
HEADER="$(cat "$_ROOT"/tmpl/header.html)"
FOOTER="$(cat "$_ROOT"/tmpl/footer.html)"
CSS="$(cat "$_ROOT"/tmpl/style.css)"

# Defaults
DEF_TITLE="Rollout"
DEF_DESCR="A simple static site generator written in shell script."
DEF_STYLE="/style.css"

# Write CSS to build dir (not source!)
printf "%s\\n" "$CSS" > "$_BUILDDIR/style.css"

# Escape strings for safe sed replacement (handles &, /, \, newlines)
sed_escape() {
    printf '%s' "$1" | sed -e 's/[&/\]/\\&/g' -e "s/'/\\\\'/g"
}

_page_count=0
_page_fail=0

find "${_BUILDDIR}" -name '*.md' | while IFS= read -r file; do
    # Reset to defaults each page
    TMPL_TITLE="$DEF_TITLE"
    TMPL_DESCR="$DEF_DESCR"
    TMPL_STYLE="$DEF_STYLE"

    # Extract template meta tags
    _meta_style="$(grep '//META:style' "$file" | sed 's/^\/\/META:style //' | head -1 || true)"
    _meta_title="$(grep '//META:title' "$file" | sed 's/^\/\/META:title //' | head -1 || true)"
    _meta_descr="$(grep '//META:description' "$file" | sed 's/^\/\/META:description //' | head -1 || true)"
    [ -n "$_meta_style" ] && TMPL_STYLE="$_meta_style"
    [ -n "$_meta_title" ] && [ "$_meta_title" != "Rollout" ] && [ "$_meta_title" != "none" ] && TMPL_TITLE="$_meta_title"
    [ -n "$_meta_descr" ] && [ "$_meta_descr" != "none" ] && TMPL_DESCR="$_meta_descr"

    # Convert markdown body to HTML
    BODY="$(grep -v '//META:' "$file" | "$_UTILDIR"/mdtohtml)" || { warn "mdtohtml failed on $file"; continue; }

    # Determine active nav tab based on path
    BASENAME="$(basename "$file" .md)"
    DIRPART="$(printf '%s' "$file" | sed "s|^${_BUILDDIR}/||")"
    NAV_HOME=""
    NAV_ABOUT=""
    NAV_PROJECTS=""
    case "$DIRPART" in
        '~'/*)   NAV_PROJECTS="active" ;;
        *)
            case "$BASENAME" in
                index)   NAV_HOME="active" ;;
                about)   NAV_ABOUT="active" ;;
            esac
        ;;
    esac

    # Build breadcrumb trail from file path
    RELPATH="$(printf '%s' "$file" | sed "s|^${_BUILDDIR}/||" | sed 's/\.md$//')"
    CRUMBS=""
    if [ "$RELPATH" != "index" ] && [ "$RELPATH" != "p/index" ] && [ "$RELPATH" != "~/index" ]; then
        OIFS="$IFS"; IFS='/'; set -- $RELPATH; IFS="$OIFS"
        CRUMB_PATH=""
        LAST="$#"
        I=0
        FIRST=1
        for PART do
            I=$((I + 1))
            [ "$PART" = "index" ] && continue
            CRUMB_PATH="$CRUMB_PATH/$PART"
            if [ "$FIRST" -eq 1 ]; then
                FIRST=0
            else
                CRUMBS="$CRUMBS<span class=\"sep\">/</span>"
            fi
            if [ "$I" -eq "$LAST" ]; then
                CRUMBS="$CRUMBS$PART"
            else
                CRUMBS="$CRUMBS<a href=\"$CRUMB_PATH/\">$PART</a>"
            fi
        done
    fi

    # Extract date, updated, and compute reading time
    _meta_date="$(grep '//META:date' "$file" | sed 's/^\/\/META:date //' | head -1 || true)"
    _meta_updated="$(grep '//META:updated' "$file" | sed 's/^\/\/META:updated //' | head -1 || true)"

    # Word count for reading time (exclude META lines, ~200 wpm)
    _word_count="$(grep -v '//META:' "$file" | wc -w | tr -d ' ')"
    _read_min=$(( (_word_count + 199) / 200 ))
    [ "$_read_min" -lt 1 ] && _read_min=1

    # Build page meta bar (date, updated, reading time) — only if date is set
    PAGE_META=""
    if [ -n "$_meta_date" ]; then
        PAGE_META='<div class=\"page-meta\">'
        PAGE_META="${PAGE_META}written <span class=\"page-date\">${_meta_date}</span>"
        if [ -n "$_meta_updated" ]; then
            PAGE_META="${PAGE_META} | <span class=\"page-updated\">updated ${_meta_updated}</span>"
        fi
        PAGE_META="${PAGE_META}<br><br><span class=\"page-readtime\">${_read_min} min read</span>"
        PAGE_META="${PAGE_META}</div>"
    fi

    # Build output using awk for safe substitution (no sed delimiter issues)
    OUTFILE="$(printf '%s' "$file" | sed 's/\.md$/.html/')"
    export TMPL_TITLE TMPL_DESCR TMPL_STYLE NAV_HOME NAV_ABOUT NAV_PROJECTS CRUMBS PAGE_META
    printf '%s' "$META$HEADER$BODY$FOOTER" | awk '{
        gsub(/\{\{title\}\}/, ENVIRON["TMPL_TITLE"])
        gsub(/\{\{description\}\}/, ENVIRON["TMPL_DESCR"])
        gsub(/\{\{style\}\}/, ENVIRON["TMPL_STYLE"])
        gsub(/\{\{nav-home\}\}/, ENVIRON["NAV_HOME"])
        gsub(/\{\{nav-about\}\}/, ENVIRON["NAV_ABOUT"])
        gsub(/\{\{nav-projects\}\}/, ENVIRON["NAV_PROJECTS"])
        gsub(/\{\{breadcrumbs\}\}/, ENVIRON["CRUMBS"])
        gsub(/\{\{page-meta\}\}/, ENVIRON["PAGE_META"])
        print
    }' > "$OUTFILE" || { warn "Failed to write $OUTFILE"; _page_fail=$((_page_fail + 1)); continue; }
    _page_count=$((_page_count + 1))
done
