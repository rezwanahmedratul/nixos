#!/usr/bin/env bash

##########################################
# ZaneyOS Noctalia v5 Migration Prep Script
# Safely prepares an isolated local test branch from origin/noctaliav5.
##########################################

# Define colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Defaults
REMOTE_NAME="origin"
SOURCE_BRANCH="noctaliav5"
TEST_BRANCH="local/noctalia-v5-test"
STATE_FILE=".git/noctalia-v5-migration.state"
AUTO_STASH=true
FORCE_RESET_TEST_BRANCH=false

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
Usage: ./modules/src/noctalia-v5-prepare.sh [options]

Options:
  -r, --remote <name>           Remote to fetch from (default: origin)
  -s, --source-branch <name>    Remote source branch (default: noctaliav5)
  -t, --test-branch <name>      Local test branch to create/switch (default: local/noctalia-v5-test)
      --no-stash                Refuse to continue if working tree is dirty
      --force-reset-test-branch Allow reset of an existing test branch to <remote>/<source-branch>
  -h, --help                    Show this help message
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -r|--remote)
      REMOTE_NAME="$2"
      shift 2
      ;;
    -s|--source-branch)
      SOURCE_BRANCH="$2"
      shift 2
      ;;
    -t|--test-branch)
      TEST_BRANCH="$2"
      shift 2
      ;;
    --no-stash)
      AUTO_STASH=false
      shift
      ;;
    --force-reset-test-branch)
      FORCE_RESET_TEST_BRANCH=true
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

print_header "ZaneyOS Noctalia v5 Migration Prep"

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

print_info "Repository root: $REPO_ROOT"

if [ -f ".git/MERGE_HEAD" ]; then
  print_error "Merge in progress. Resolve or abort it before running this script."
  exit 1
fi

if [ -d ".git/rebase-apply" ] || [ -d ".git/rebase-merge" ]; then
  print_error "Rebase in progress. Resolve or abort it before running this script."
  exit 1
fi

ORIGINAL_BRANCH="$(git branch --show-current)"
if [ -z "$ORIGINAL_BRANCH" ]; then
  print_error "Detached HEAD detected. Switch to your normal working branch first."
  exit 1
fi

if [ -f "$STATE_FILE" ] && [ "$FORCE_RESET_TEST_BRANCH" != true ]; then
  print_error "State file already exists at $STATE_FILE."
  print_error "Run finalize script first, or rerun with --force-reset-test-branch."
  exit 1
fi
if git show-ref --verify --quiet "refs/heads/$TEST_BRANCH" && [ "$FORCE_RESET_TEST_BRANCH" != true ]; then
  print_error "Local branch '$TEST_BRANCH' already exists."
  print_error "Use --force-reset-test-branch to reset it, or choose another --test-branch."
  exit 1
fi

print_info "Fetching $REMOTE_NAME/$SOURCE_BRANCH ..."
if ! git fetch "$REMOTE_NAME" "$SOURCE_BRANCH"; then
  print_error "Failed to fetch $REMOTE_NAME/$SOURCE_BRANCH."
  exit 1
fi

REMOTE_REF="$REMOTE_NAME/$SOURCE_BRANCH"
if ! git show-ref --verify --quiet "refs/remotes/$REMOTE_REF"; then
  print_error "Remote ref not found after fetch: $REMOTE_REF"
  exit 1
fi
if [ -n "$(git status --porcelain)" ]; then
  if [ "$AUTO_STASH" = true ]; then
    STASH_MESSAGE="noctalia-v5-migration-prep-$(date +"%Y-%m-%d_%H-%M-%S")"
    print_warning "Working tree is dirty. Stashing tracked and untracked changes."
    if ! git stash push -u -m "$STASH_MESSAGE" >/dev/null; then
      print_error "Failed to stash local changes."
      exit 1
    fi
    STASH_OID="$(git rev-parse -q --verify stash@{0} 2>/dev/null || true)"
    print_success "Created stash: $STASH_MESSAGE"
  else
    print_error "Working tree has uncommitted changes and --no-stash was set."
    print_error "Commit/stash manually or rerun without --no-stash."
    exit 1
  fi
else
  STASH_MESSAGE=""
  STASH_OID=""
  print_success "Working tree is clean."
fi

if git show-ref --verify --quiet "refs/heads/$TEST_BRANCH"; then
  if [ "$FORCE_RESET_TEST_BRANCH" = true ]; then
    print_warning "Existing local branch '$TEST_BRANCH' will be reset to $REMOTE_REF."
    if ! git switch "$TEST_BRANCH"; then
      print_error "Failed to switch to existing branch: $TEST_BRANCH"
      exit 1
    fi
    if ! git reset --hard "$REMOTE_REF" >/dev/null; then
      print_error "Failed to reset $TEST_BRANCH to $REMOTE_REF."
      exit 1
    fi
    print_success "Reset existing branch '$TEST_BRANCH' to $REMOTE_REF."
  fi
else
  if ! git switch -c "$TEST_BRANCH" --track "$REMOTE_REF"; then
    print_error "Failed to create/switch to branch '$TEST_BRANCH' from $REMOTE_REF."
    exit 1
  fi
  print_success "Created branch '$TEST_BRANCH' tracking '$REMOTE_REF'."
fi

git branch --set-upstream-to="$REMOTE_REF" "$TEST_BRANCH" >/dev/null 2>&1 || true

{
  printf 'ORIGINAL_BRANCH=%q\n' "$ORIGINAL_BRANCH"
  printf 'TEST_BRANCH=%q\n' "$TEST_BRANCH"
  printf 'REMOTE_NAME=%q\n' "$REMOTE_NAME"
  printf 'SOURCE_BRANCH=%q\n' "$SOURCE_BRANCH"
  printf 'REMOTE_REF=%q\n' "$REMOTE_REF"
  printf 'STASH_MESSAGE=%q\n' "$STASH_MESSAGE"
  printf 'STASH_OID=%q\n' "$STASH_OID"
  printf 'PREPARED_AT=%q\n' "$(date -Iseconds)"
} > "$STATE_FILE"

print_success "Saved migration state: $STATE_FILE"
echo ""
print_info "Next steps:"
echo "  1) Test build on $TEST_BRANCH (for example: zcli rebuild --dry)"
echo "  2) If the test looks good, run: ./modules/src/noctalia-v5-finalize.sh"
echo "  3) If you want a different target, rerun this script with --test-branch"
