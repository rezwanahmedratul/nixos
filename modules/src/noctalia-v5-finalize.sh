#!/usr/bin/env bash

##########################################
# ZaneyOS Noctalia v5 Migration Finalize Script
# Merges the prepared test branch back to the original branch and
# optionally restores any stash created during prep.
##########################################

# Define colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Defaults
STATE_FILE=".git/noctalia-v5-migration.state"
MERGE_MODE="merge" # merge | ff-only
RESTORE_STASH=true
DROP_TEST_BRANCH=false

print_header() {
  echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${BLUE}║ ${1}${NC}"
  echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════════════╝${NC}"
}

print_error() {
  echo -e "${RED}❌ Error: ${1}${NC}" >&2
}

print_warning() {
  echo -e "${YELLOW}⚠️  Warning: ${1}${NC}"
}

print_success() {
  echo -e "${GREEN}✅ ${1}${NC}"
}

print_info() {
  echo -e "${CYAN}ℹ️  ${1}${NC}"
}

show_usage() {
  cat <<'USAGE'
Usage: ./modules/src/noctalia-v5-finalize.sh [options]

Options:
      --state-file <path>   State file path (default: .git/noctalia-v5-migration.state)
      --ff-only             Use fast-forward only merge instead of a normal merge commit
      --no-restore-stash    Skip stash restore even if prep created one
      --drop-test-branch    Delete local test branch after successful merge
  -h, --help                Show this help message
USAGE
}

find_stash_ref_by_oid() {
  local oid="$1"
  git stash list --format='%H %gd' | awk -v target="$oid" '$1 == target { print $2; exit }'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --state-file)
      STATE_FILE="$2"
      shift 2
      ;;
    --ff-only)
      MERGE_MODE="ff-only"
      shift
      ;;
    --no-restore-stash)
      RESTORE_STASH=false
      shift
      ;;
    --drop-test-branch)
      DROP_TEST_BRANCH=true
      shift
      ;;
    -h|--help)
      show_usage
      exit 0
      ;;
    *)
      print_error "Unknown option: $1"
      show_usage
      exit 1
      ;;
  esac
done

print_header "ZaneyOS Noctalia v5 Migration Finalize"

if ! command -v git >/dev/null 2>&1; then
  print_error "git is required but not found in PATH."
  exit 1
fi

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  print_error "Current directory is not inside a git repository."
  exit 1
fi

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT" || exit 1

if [ ! -f "$STATE_FILE" ]; then
  print_error "State file not found: $STATE_FILE"
  print_error "Run ./modules/src/noctalia-v5-prepare.sh first."
  exit 1
fi

# shellcheck disable=SC1090
source "$STATE_FILE"

if [ -z "${ORIGINAL_BRANCH:-}" ] || [ -z "${TEST_BRANCH:-}" ]; then
  print_error "State file is missing required values (ORIGINAL_BRANCH/TEST_BRANCH)."
  exit 1
fi

if [ -f ".git/MERGE_HEAD" ]; then
  print_error "Merge in progress. Resolve or abort it before running this script."
  exit 1
fi

if [ -d ".git/rebase-apply" ] || [ -d ".git/rebase-merge" ]; then
  print_error "Rebase in progress. Resolve or abort it before running this script."
  exit 1
fi

if [ -n "$(git status --porcelain)" ]; then
  print_error "Working tree is not clean. Commit/stash your changes before finalizing."
  exit 1
fi

if ! git show-ref --verify --quiet "refs/heads/$ORIGINAL_BRANCH"; then
  print_error "Original branch not found locally: $ORIGINAL_BRANCH"
  exit 1
fi

if ! git show-ref --verify --quiet "refs/heads/$TEST_BRANCH"; then
  print_error "Test branch not found locally: $TEST_BRANCH"
  exit 1
fi

print_info "Switching to original branch: $ORIGINAL_BRANCH"
if ! git switch "$ORIGINAL_BRANCH"; then
  print_error "Failed to switch to original branch: $ORIGINAL_BRANCH"
  exit 1
fi

if [ "$MERGE_MODE" = "ff-only" ]; then
  print_info "Merging $TEST_BRANCH into $ORIGINAL_BRANCH with --ff-only"
  if ! git merge --ff-only "$TEST_BRANCH"; then
    print_error "Fast-forward merge failed."
    print_error "Retry without --ff-only to allow a merge commit."
    exit 1
  fi
else
  print_info "Merging $TEST_BRANCH into $ORIGINAL_BRANCH"
  if ! git merge --no-ff --no-edit "$TEST_BRANCH"; then
    print_error "Merge failed due to conflicts."
    print_error "Resolve conflicts, complete/abort merge, then rerun finalize if needed."
    exit 1
  fi
fi

print_success "Merged $TEST_BRANCH into $ORIGINAL_BRANCH."

STASH_RESTORE_OK=true
if [ "$RESTORE_STASH" = true ] && [ -n "${STASH_OID:-}" ]; then
  STASH_REF="$(find_stash_ref_by_oid "$STASH_OID")"
  if [ -n "$STASH_REF" ]; then
    print_info "Restoring stashed changes from $STASH_REF ..."
    if git stash apply "$STASH_REF"; then
      git stash drop "$STASH_REF" >/dev/null 2>&1 || true
      print_success "Stash restored and dropped: $STASH_REF"
    else
      STASH_RESTORE_OK=false
      print_warning "Stash apply reported conflicts. The stash entry was kept."
      print_warning "Resolve conflicts manually and re-apply/drop stash when ready."
    fi
  else
    STASH_RESTORE_OK=false
    print_warning "Could not locate the prep stash by object ID: $STASH_OID"
    print_warning "Use 'git stash list' and apply manually if needed."
  fi
elif [ "$RESTORE_STASH" = false ]; then
  print_info "Skipping stash restore (--no-restore-stash)."
else
  print_info "No prep stash to restore."
fi

if [ "$DROP_TEST_BRANCH" = true ]; then
  if git branch -d "$TEST_BRANCH" >/dev/null 2>&1; then
    print_success "Deleted local test branch: $TEST_BRANCH"
  else
    print_warning "Could not delete test branch '$TEST_BRANCH' (it may still be checked out elsewhere)."
  fi
fi

if [ "$STASH_RESTORE_OK" = true ]; then
  rm -f "$STATE_FILE"
  print_success "Removed state file: $STATE_FILE"
else
  print_warning "State file kept at $STATE_FILE because stash restore needs attention."
fi

echo ""
print_success "Finalize step complete."
