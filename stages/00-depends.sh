#!/bin/sh
set -e

err() { printf "[00-depends] ERROR: %s\n" "$*" >&2; }

[ -n "$_UTILDIR" ]  || { err "_UTILDIR not set"; exit 1; }
[ -n "$_BUILDDIR" ] || { err "_BUILDDIR not set"; exit 1; }
[ -n "$_SITEDIR" ]  || { err "_SITEDIR not set"; exit 1; }

if [ ! -f "$_UTILDIR/minify" ]; then
	if ! command -v minify >/dev/null 2>&1; then
		err "minify not found (checked $_UTILDIR/minify and PATH)"
		exit 2
	fi
fi

if [ ! -f "$_UTILDIR/mdtohtml" ]; then
	if ! command -v mdtohtml >/dev/null 2>&1; then
		err "mdtohtml not found (checked $_UTILDIR/mdtohtml and PATH)"
		exit 2
	fi
fi

if [ ! -d "$_SITEDIR" ]; then
	err "site directory missing: $_SITEDIR"
	exit 2
fi

if [ ! -d "$_BUILDDIR" ]; then
	err "build directory missing: $_BUILDDIR"
	exit 2
fi
