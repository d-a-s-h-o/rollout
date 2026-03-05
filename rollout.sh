#!/bin/sh
set -e

log()  { printf "[rollout] %s\n" "$*"; }
err()  { printf "[rollout] ERROR: %s\n" "$*" >&2; }
die()  { err "$@"; exit 1; }

export _ORIGIN
export _ROOT

_ORIGIN="$(pwd)"
_ROOT=$(dirname "$(readlink -f "$0")")

export _STAGEDIR="$_ROOT/stages"
export _SCRIPTDIR="$_ROOT/stages/scripts"
export _BUILDROOT="$_ROOT/build"
export _UTILDIR="$_ROOT/util"
export _PRODDIR="$_ROOT/prod"
export _SITEDIR="$_ROOT/site"
export _BUILDID=""
export _BUILDDIR=""
export _DEPLOY=0
_BUILDID="$(date +%s)"
_BUILDDIR="$_BUILDROOT/$_BUILDID"

# Validate critical paths exist
[ -d "$_STAGEDIR" ] || die "stages directory not found: $_STAGEDIR"
[ -d "$_SITEDIR" ]  || die "site directory not found: $_SITEDIR"
[ -d "$_UTILDIR" ]  || die "util directory not found: $_UTILDIR"

HELPDIAG="[-p]\\n   -p: tag and stage for deployment\\n   -s [script]: list scripts with no arguments, or run a script"

runscript() {
	if [ -z "$1" ]; then
		find "$_SCRIPTDIR" -type f -name '*.sh' -print | while IFS= read -r f; do
			basename "$f" .sh
		done
		exit 0
	fi
	COMM="$(printf "%s/%s.sh" "$_SCRIPTDIR" "$1")"
	if [ ! -f "$COMM" ]; then
		die "Script command '$1' not found"
	fi
	sh "$COMM"
}

while :; do
        case $1 in
                -h|-\?|--help)
                        printf "%s %b\\n" "$0" "$HELPDIAG"
                        exit
                        ;;
		-p)
			_DEPLOY=1
			;;
		-s)
			shift
			runscript "$1"
			exit
			;;
                -?*)
                        die "Unknown option: $1"
                        ;;
                *)
                        break
        esac
	shift
done

# Clean up broken build on failure
cleanup() {
	if [ -d "$_BUILDDIR" ]; then
		err "Build failed — removing incomplete build $_BUILDID"
		rm -rf "$_BUILDDIR"
		# Restore latest symlink to previous build if possible
		PREV="$(find "$_BUILDROOT" -maxdepth 1 -type d -name '[0-9]*' 2>/dev/null | sort -n | tail -1)"
		if [ -n "$PREV" ]; then
			[ -h "$_BUILDROOT/latest" ] && rm "$_BUILDROOT/latest"
			ln -s "$PREV" "$_BUILDROOT/latest"
			log "Restored latest -> $(basename "$PREV")"
		fi
	fi
}
trap cleanup EXIT

cd "$_ROOT" || die "Cannot cd to $_ROOT"
mkdir -p "$_BUILDDIR" || die "Cannot create build dir $_BUILDDIR"
log "Build $_BUILDID starting"
cp -r "${_ROOT}"/site/* "$_BUILDDIR" || die "Failed to copy site to build dir"
[ -h "$_BUILDROOT/latest" ] && rm "$_BUILDROOT/latest"
ln -s "$_BUILDDIR" "$_BUILDROOT/latest"
cd "$_BUILDDIR" || die "Cannot cd to $_BUILDDIR"

# Run stages in order — abort on first failure
STAGE_COUNT=0
STAGE_FAIL=0
for sc in $(find "$_STAGEDIR/" -type f -name '[0-9]*-*.sh' -print | sort -n); do
	STAGE_NAME="$(basename "$sc")"
	log "Running stage: $STAGE_NAME"
	if sh "$sc"; then
		STAGE_COUNT=$((STAGE_COUNT + 1))
	else
		err "Stage $STAGE_NAME failed (exit $?)"
		STAGE_FAIL=1
		break
	fi
done

[ "$STAGE_FAIL" -ne 0 ] && die "Build aborted due to stage failure"

if [ "$_DEPLOY" -ne 0 ]; then
	log "Deploying build $_BUILDID"
	[ -d "$_PRODDIR" ] && rm -rf "$_PRODDIR"
	mkdir -p "$_PRODDIR" || die "Cannot create prod dir"
	cp -r "$_BUILDROOT/latest/"* "$_PRODDIR" || die "Failed to copy to prod"
	log "Deployed to $_PRODDIR"
fi

# Build succeeded — disarm cleanup trap
trap - EXIT
log "Build $_BUILDID complete ($STAGE_COUNT stages)"
cd "$_ORIGIN" || exit 0
