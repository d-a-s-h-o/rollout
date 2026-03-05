#!/bin/sh -e
NUM="$(find "${_BUILDROOT}"/* -type d -print0 -maxdepth 1 -prune | xargs -0 -I {} basename {} | wc -l | tr -d ' ')"
if [ $NUM -gt 5 ]; then
	#Extra because of the symlink latest
	find "${_BUILDROOT}"/* -type d -print0 -maxdepth 1 -prune | xargs -0 -I {} basename {} | sort -n -r | tail -n +6 | xargs -I {a} find "${_BUILDROOT}"/{a} -type d -maxdepth 1 -prune -exec rm -rf "{}" \;
fi
