#!/usr/bin/env bash
# install.sh — vendor the universal agent guide into the current repo, or update it.
#
# Copies AGENTS.md, CHANGELOG.md, LICENSE, docs/, templates/ and scripts/ from a release of
# Gamaroff/agent-standards into <repo>/.agents/standards/, and records the release in VERSION there.
# Also, only where missing: adds the import block to the repo's AGENTS.md (or creates it from the
# template), creates CHANGELOG.md from the template, and adds the .gitignore entries the guide requires.
# Re-running it is the update: the vendored copy is replaced, everything else is left alone.
#
# Usage (from anywhere inside the consumer repo):
#   bash .agents/standards/scripts/install.sh                 # install or update to the latest v* tag
#   bash .agents/standards/scripts/install.sh --ref v0.2.0    # a specific tag (or branch)
#   bash .agents/standards/scripts/install.sh --dry-run       # print actions, write nothing
#   curl -fsSL https://raw.githubusercontent.com/Gamaroff/agent-standards/main/scripts/install.sh | bash
#
# Options:
#   --ref <ref>        tag or branch to install (default: the latest v* tag)
#   --source <url|dir> where to fetch from (default: $AGENT_STANDARDS_SOURCE, else the source recorded
#                      in .agents/standards/VERSION, else the GitHub repo)
#   --force            replace a vendored copy that has local edits
#   --dry-run          print what would change, write nothing
#
# Requires: git. Documented in: docs/development/agents/agent-files.md § 3.

set -euo pipefail

DEFAULT_SOURCE="https://github.com/Gamaroff/agent-standards.git"
DEST_REL=".agents/standards"
IMPORT_LINE="@.agents/standards/AGENTS.md"
GITIGNORE_LINES=(".worktrees/" "CLAUDE.md" ".claude/skills")

die()  { echo "✗ $*" >&2; exit 1; }
info() { echo "→ $*"; }

# Everything runs inside main, so bash has parsed the whole script before the vendored copy (which may
# be this file) is replaced.
main() {
  local ref="" source="${AGENT_STANDARDS_SOURCE:-}" force=false dry=false
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --ref)     ref="${2:?--ref needs a value}"; shift 2 ;;
      --source)  source="${2:?--source needs a value}"; shift 2 ;;
      --force)   force=true; shift ;;
      --dry-run) dry=true; shift ;;
      -h|--help) sed -n '2,24p' "${BASH_SOURCE[0]}" 2>/dev/null || echo "See scripts/install.sh"; exit 0 ;;
      *)         die "unknown option: $1" ;;
    esac
  done

  command -v git >/dev/null || die "git is required"
  local root
  root="$(git rev-parse --show-toplevel 2>/dev/null)" || die "run this inside a git repo"
  cd "$root"
  local dest="$root/$DEST_REL"

  # No --source or env: reuse the source the last install recorded, so an update from a mirror stays
  # on the mirror. A recorded local path that does not exist here (another machine) is skipped.
  if [[ -z "$source" && -f "$dest/VERSION" ]]; then
    local recorded
    recorded="$(sed -n 3p "$dest/VERSION")"
    if [[ -n "$recorded" && ( "$recorded" != /* || -d "$recorded" ) ]]; then
      source="$recorded"
    fi
  fi
  source="${source:-$DEFAULT_SOURCE}"

  # A local directory is cloned through file:// so --depth applies.
  [[ -d "$source" ]] && source="file://$(cd "$source" && pwd)"

  if [[ -z "$ref" ]]; then
    ref="$(git ls-remote --tags --refs "$source" 'v*' | sed 's#.*refs/tags/##' | sort -V | tail -n1)" \
      || die "cannot list tags at $source"
    [[ -n "$ref" ]] || die "no v* tag at $source; pass --ref <branch>"
  fi

  # Local edits to the vendored copy would be lost. Fix the guide upstream instead.
  if [[ -d "$dest" ]] && git rev-parse -q --verify HEAD >/dev/null \
     && ! git diff --quiet HEAD -- "$DEST_REL"; then
    $force || die "$DEST_REL has local edits; commit or discard them, or pass --force"
  fi

  tmp="$(mktemp -d)"   # global: the EXIT trap runs after main returns
  trap 'rm -rf "$tmp"' EXIT
  # init + fetch rather than clone --branch: a shallow clone of an annotated tag warns "is not a commit".
  git init -q "$tmp/src"
  git -C "$tmp/src" fetch -q --depth 1 "$source" "$ref" || die "cannot fetch $ref from $source"
  git -C "$tmp/src" -c advice.detachedHead=false checkout -q FETCH_HEAD
  local sha
  sha="$(git -C "$tmp/src" rev-parse HEAD)"
  local item
  for item in AGENTS.md CHANGELOG.md docs templates scripts; do
    [[ -e "$tmp/src/$item" ]] || die "$ref has no $item; is $source the agent-standards repo?"
  done

  local old=""
  [[ -f "$dest/VERSION" ]] && old="$(head -n1 "$dest/VERSION")"
  info "$DEST_REL: ${old:-not installed} → $ref ($sha) from ${source#file://}"

  if $dry; then
    info "dry run: would replace $DEST_REL"
  else
    rm -rf "$dest"
    mkdir -p "$dest"
    cp -R "$tmp/src/AGENTS.md" "$tmp/src/CHANGELOG.md" "$tmp/src/docs" "$tmp/src/templates" \
      "$tmp/src/scripts" "$dest/"
    # The licence travels with every copy. Releases before v0.2.0 have none.
    [[ -f "$tmp/src/LICENSE" ]] && cp "$tmp/src/LICENSE" "$dest/"
    printf '%s\n%s\n%s\n' "$ref" "$sha" "${source#file://}" > "$dest/VERSION"
  fi

  # The repo's AGENTS.md imports the guide on its first lines.
  if [[ ! -e AGENTS.md ]]; then
    info "AGENTS.md: create from the template"
    $dry || cp "$tmp/src/templates/AGENTS.repo.md" AGENTS.md
  elif ! grep -qxF "$IMPORT_LINE" AGENTS.md; then
    info "AGENTS.md: add the import block at the top"
    if ! $dry; then
      # The template's lines before its first heading are the import block.
      { sed '/^# /,$d' "$tmp/src/templates/AGENTS.repo.md"; cat AGENTS.md; } > "$tmp/AGENTS.md"
      cat "$tmp/AGENTS.md" > AGENTS.md
    fi
  fi

  if [[ ! -e CHANGELOG.md ]]; then
    info "CHANGELOG.md: create from the template"
    $dry || cp "$tmp/src/templates/CHANGELOG.md" CHANGELOG.md
  fi

  local line missing=()
  for line in "${GITIGNORE_LINES[@]}"; do
    grep -qxF "$line" .gitignore 2>/dev/null || missing+=("$line")
  done
  if [[ ${#missing[@]} -gt 0 ]]; then
    info ".gitignore: add ${missing[*]}"
    if ! $dry; then
      [[ -s .gitignore && -n "$(tail -c1 .gitignore)" ]] && echo >> .gitignore
      { echo "# Agent standards: worktrees and local agent links ($DEST_REL/docs/development/agents/agent-files.md)"
        printf '%s\n' "${missing[@]}"; } >> .gitignore
    fi
  fi

  $dry && return 0
  echo "✓ Installed $ref. Review with git status, then commit:"
  if [[ -n "$old" ]]; then echo "    chore(standards): update to $ref"
  else echo "    chore(standards): install $ref"; fi
  [[ -e CLAUDE.md ]] || echo "  Claude Code users: ln -s AGENTS.md CLAUDE.md (local, gitignored)"
}

main "$@"
