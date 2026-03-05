#!/bin/sh
set -e
# Generate RSS 2.0 feed from post metadata
# Reads source .md files from $_SITEDIR/p/ (unmodified originals)

err() { printf '[05-rss] ERROR: %s\n' "$*" >&2; }

[ -n "$_SITEDIR" ]  || { err '_SITEDIR not set'; exit 1; }
[ -n "$_BUILDDIR" ] || { err '_BUILDDIR not set'; exit 1; }

SITE_URL="https://dasho.dev"
FEED_TITLE=".dasho"
FEED_DESC="Dasho's personal blog, funhouse, and digital junkyard. A mix of technical deep-dives, personal essays, and general weirdness."

POSTDIR="$_SITEDIR/p"
OUTFILE="$_BUILDDIR/rss.xml"

if [ ! -d "$POSTDIR" ]; then
    # No posts directory — skip RSS generation
    exit 0
fi

# Escape XML special characters in text content
xml_escape() {
    printf '%s' "$1" | sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g' -e "s/'/\&apos;/g" -e 's/"/\&quot;/g'
}

# RFC-822 date (required by RSS)
rfc822_now="$(date -u '+%a, %d %b %Y %H:%M:%S +0000')"

# Write to temp file first, move on success
TMPFILE="${OUTFILE}.tmp"

# --- Header ---
cat > "$TMPFILE" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom">
<channel>
<title>${FEED_TITLE}</title>
<link>${SITE_URL}</link>
<description>${FEED_DESC}</description>
<language>en-us</language>
<lastBuildDate>${rfc822_now}</lastBuildDate>
<atom:link href="${SITE_URL}/rss.xml" rel="self" type="application/rss+xml"/>
EOF

# --- Items (newest first) ---
_item_count=0
for file in $(find "$POSTDIR" -maxdepth 1 -name '*.md' ! -name 'index.md' -print | sort -r); do
    slug="$(basename "$file" .md)"

    post_title="$(grep '//META:title' "$file" | sed 's/^\/\/META:title //' | head -1 || true)"
    [ -z "$post_title" ] && post_title="$slug"

    post_desc="$(grep '//META:description' "$file" | sed 's/^\/\/META:description //' | head -1 || true)"
    [ -z "$post_desc" ] && post_desc=""

    # Escape for XML
    post_title_esc="$(xml_escape "$post_title")"
    post_desc_esc="$(xml_escape "$post_desc")"

    post_href="${SITE_URL}/p/${slug}.html"

    # Use file modification time as pub date
    if stat --version >/dev/null 2>&1; then
        # GNU stat
        pub_date="$(date -u -d "@$(stat -c '%Y' "$file")" '+%a, %d %b %Y %H:%M:%S +0000')"
    else
        # BSD stat
        pub_date="$(date -u -r "$(stat -f '%m' "$file")" '+%a, %d %b %Y %H:%M:%S +0000')"
    fi

    cat >> "$TMPFILE" <<EOF
<item>
<title>${post_title_esc}</title>
<link>${post_href}</link>
<guid>${post_href}</guid>
<pubDate>${pub_date}</pubDate>
<description>${post_desc_esc}</description>
</item>
EOF
    _item_count=$((_item_count + 1))
done

# --- Footer ---
cat >> "$TMPFILE" <<EOF
</channel>
</rss>
EOF

# Atomic write
mv "$TMPFILE" "$OUTFILE" || { err "Failed to write $OUTFILE"; rm -f "$TMPFILE"; exit 1; }
