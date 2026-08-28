#!/bin/sh
# Install the elephant-goldfish skill into one or more agent harnesses.
#
# The same skill directory works in all of them: it is plain markdown with
# standard `name`/`description` frontmatter and hard-codes no project commands,
# so there is nothing to specialise per harness.
#
# Usage:  ./install.sh --claude --codex --gemini
#         ./install.sh --all
#         ./install.sh --claude --dry-run
#
# Existing installs are never overwritten without --force.

set -eu

SRC_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)/skills/elephant-goldfish
SKILL_NAME=elephant-goldfish

do_claude=0
do_codex=0
do_gemini=0
force=0
dry_run=0

usage() {
	cat <<'EOF'
Install the elephant-goldfish skill.

Targets:
  --claude    ~/.claude/skills/            (Claude Code, all projects)
  --codex     ${CODEX_HOME:-~/.codex}/skills/   (Codex, all projects)
  --gemini    ./.gemini/skills/            (Gemini CLI, this project only)
  --all       all three

Options:
  --force     overwrite an existing install
  --dry-run   print what would happen, change nothing
  -h, --help  this message

Claude Code users can instead install the plugin, which self-updates:
  claude plugin marketplace add donchummar/elephant-goldfish-skill
  claude plugin install elephant-goldfish@elephant-goldfish
EOF
}

while [ $# -gt 0 ]; do
	case "$1" in
	--claude) do_claude=1 ;;
	--codex) do_codex=1 ;;
	--gemini) do_gemini=1 ;;
	--all)
		do_claude=1
		do_codex=1
		do_gemini=1
		;;
	--force) force=1 ;;
	--dry-run) dry_run=1 ;;
	-h | --help)
		usage
		exit 0
		;;
	*)
		echo "unknown option: $1" >&2
		usage >&2
		exit 2
		;;
	esac
	shift
done

if [ "$do_claude" -eq 0 ] && [ "$do_codex" -eq 0 ] && [ "$do_gemini" -eq 0 ]; then
	echo "No target selected." >&2
	usage >&2
	exit 2
fi

if [ ! -f "$SRC_DIR/SKILL.md" ]; then
	echo "Cannot find $SRC_DIR/SKILL.md — run this from a clone of the repo." >&2
	exit 1
fi

install_to() {
	skills_root=$1
	label=$2
	dest="$skills_root/$SKILL_NAME"

	if [ -e "$dest" ] && [ "$force" -eq 0 ]; then
		echo "SKIP  $label: $dest already exists (use --force to overwrite)"
		return 0
	fi

	if [ "$dry_run" -eq 1 ]; then
		echo "DRY   $label: would install to $dest"
		return 0
	fi

	mkdir -p "$skills_root"
	rm -rf "$dest"
	cp -R "$SRC_DIR" "$dest"
	echo "OK    $label: $dest"
}

[ "$do_claude" -eq 1 ] && install_to "$HOME/.claude/skills" "Claude Code"
[ "$do_codex" -eq 1 ] && install_to "${CODEX_HOME:-$HOME/.codex}/skills" "Codex"
[ "$do_gemini" -eq 1 ] && install_to "$PWD/.gemini/skills" "Gemini CLI"

if [ "$dry_run" -eq 0 ]; then
	echo
	echo "Restart the agent session to pick up the skill."
	echo "Gemini CLI: run /skills reload instead of restarting."
fi
