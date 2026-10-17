#!/bin/sh
# standup.sh — prepare a new workspace for its first Claude Code session.
#
# Run it from the workspace folder you made by hand (~/Projects/<x>-workspace/),
# which must already hold nethub/ and an empty nethub/nexus/ and nothing else.
# It installs node and Claude Code if they are missing, writes the new AIR's
# instructions to nethub/nexus/CLAUDE.local.md from the template, prints the
# launch line and stops. It clones nothing, asks for no secret, makes no relay
# call, and never overwrites a CLAUDE.local.md that is already there.
# The seat's repositories are cloned by the new AIR as its last standup step,
# each a subject clone at the workspace root beside nethub/; the script looks
# only inside nethub/ and never touches them, so a repository that already
# carries content is the same case as an empty one.
#
# One-line usage:
#   curl -fsSL https://raw.githubusercontent.com/2ndcortex-labs/workspace-standup/main/standup.sh | sh -s -- "<the workspace's name>"
#   curl -fsSL https://raw.githubusercontent.com/2ndcortex-labs/workspace-standup/main/standup.sh | sh
#     (the launch line then carries a placeholder)
#
# Exit codes:
#   0  done — the instructions are written and the launch line is printed
#   1  the folders are wrong (missing nethub/, missing or non-empty nexus/,
#      or something other than nexus/ inside nethub/), or the name is unusable
#      (it holds ", `, $ or \, or comes as more than one argument)
#   2  nethub/nexus/CLAUDE.local.md already exists — nothing was touched
#   3  an install or the template fetch failed

set -u

# --- the name: the optional argument, carried by the launch line -----------

if [ $# -gt 1 ]; then
	echo "standup: give the workspace's name as one argument, in quotes - nothing was changed" >&2
	exit 1
fi
name="${1-}"
case $name in
*[\"\`\$\\]*)
	echo "standup: the name may not hold \", \`, \$ or \\ - nothing was changed" >&2
	exit 1
	;;
esac

MIRROR_RAW="${STANDUP_MIRROR_RAW:-https://raw.githubusercontent.com/2ndcortex-labs/workspace-standup/main}"

# entries of a folder, ignoring .DS_Store
entries() {
	ls -A "$1" 2>/dev/null | grep -v '^\.DS_Store$'
}

# --- the folders are the Operator's: check, never make ---------------------

if [ ! -d nethub ]; then
	echo "standup: no nethub/ here - run this from your workspace folder, which must already hold nethub/nexus/" >&2
	exit 1
fi

if [ ! -d nethub/nexus ]; then
	echo "standup: no nethub/nexus/ - make it by hand and run this again" >&2
	exit 1
fi

if [ -n "$(entries nethub | grep -v '^nexus$')" ]; then
	echo "standup: nethub/ must hold nothing but nexus/ - found other entries" >&2
	exit 1
fi

if [ -e nethub/nexus/CLAUDE.local.md ]; then
	echo "standup: nethub/nexus/CLAUDE.local.md already exists - nothing was changed" >&2
	exit 2
fi

if [ -n "$(entries nethub/nexus)" ]; then
	echo "standup: nethub/nexus/ must be empty" >&2
	exit 1
fi

# --- node and Claude Code, installed only when missing ---------------------

if ! command -v node >/dev/null 2>&1; then
	if ! command -v brew >/dev/null 2>&1; then
		echo "standup: node is missing and Homebrew is not here - install Homebrew first, then run this again" >&2
		exit 3
	fi
	brew install node || {
		echo "standup: brew install node failed" >&2
		exit 3
	}
fi

if ! command -v claude >/dev/null 2>&1; then
	npm install -g @anthropic-ai/claude-code || {
		echo "standup: npm install -g @anthropic-ai/claude-code failed" >&2
		exit 3
	}
fi

# --- the instructions ------------------------------------------------------

template=""
if [ -n "${STANDUP_TEMPLATE-}" ]; then
	if [ ! -r "${STANDUP_TEMPLATE}" ]; then
		echo "standup: STANDUP_TEMPLATE is set but cannot be read" >&2
		exit 3
	fi
	template="${STANDUP_TEMPLATE}"
elif [ -r "$(dirname "$0")/CLAUDE.local.md.template" ]; then
	template="$(dirname "$0")/CLAUDE.local.md.template"
fi

if [ -n "$template" ]; then
	cp "$template" nethub/nexus/CLAUDE.local.md || {
		echo "standup: could not write nethub/nexus/CLAUDE.local.md" >&2
		exit 3
	}
else
	curl -fsSL "${MIRROR_RAW}/CLAUDE.local.md.template" >nethub/nexus/CLAUDE.local.md || {
		rm -f nethub/nexus/CLAUDE.local.md
		echo "standup: could not fetch CLAUDE.local.md.template from the mirror" >&2
		exit 3
	}
fi

if [ -n "$name" ]; then
	echo "cd nethub/nexus && claude --name \"$name\""
else
	echo "standup: put your workspace's name in place of <the workspace's name> before you run the line" >&2
	echo "cd nethub/nexus && claude --name \"<the workspace's name>\""
fi
exit 0
