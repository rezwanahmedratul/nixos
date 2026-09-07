English | [Español](./HOWTO-create-new-git-Branch-and-tag.es.md)

# HOWTO: Create New Git Branch and Tag

This guide walks you through creating a new stable release branch and associated tag for ddubsOS releases.

## Table of Contents
- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Detailed Steps](#detailed-steps)
- [Quick Command Summary](#quick-command-summary)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)

## Overview

Creating a new stable release involves:
1. Creating a new branch from main
2. Creating an annotated tag with release notes
3. Pushing both the branch and tag to origin

This process ensures we have stable snapshots of our codebase for releases while maintaining a clean development workflow.

## Prerequisites

- Clean working directory (no uncommitted changes)
- Access to push to origin repository
- Latest main branch pulled locally
- Knowledge of semantic versioning (e.g., v2.5.5)

## Detailed Steps

### Step 1: Switch to Main Branch and Update

First, ensure you're on the main branch and have the latest changes:

```bash
git checkout main
```

**Expected output**: 
```
Already on 'main'
Your branch is up to date with 'origin/main'.
```
*OR if switching from another branch:*
```
Switched to branch 'main'
Your branch is up to date with 'origin/main'.
```

Pull the latest changes from origin:

```bash
git pull origin main
```

**Expected output**:
```
From gitlab.com:dwilliam62/ddubsos
 * branch            main       -> FETCH_HEAD
Already up to date.
```
*OR if there were updates:*
```
From gitlab.com:dwilliam62/ddubsos
 * branch            main       -> FETCH_HEAD
Updating abc1234..def5678
Fast-forward
 file.nix | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
```

**Purpose**: This ensures your local main branch matches the remote main branch exactly, so your new release branch will include all the latest merged features.

### Step 2: Create New Stable Branch

Create and switch to a new stable branch following the naming convention `Stable-v[VERSION]`:

```bash
git checkout -b Stable-v2.5.5
```

**Expected output**:
```
Switched to a new branch 'Stable-v2.5.5'
```

**Purpose**: The `-b` flag creates a new branch and immediately switches to it. The branch will be based on whatever commit you're currently on (should be the latest main).

### Step 3: Verify Branch Creation

Confirm you're on the new branch and check the working directory is clean:

```bash
git status
```

**Expected output**:
```
On branch Stable-v2.5.5
nothing to commit, working tree clean
```

Check the recent commit history to confirm you're on the right commit:

```bash
git log --oneline -3
```

**Expected output** (example):
```
8cd6bf3 (HEAD -> refs/heads/Stable-v2.5.5, refs/remotes/origin/main, refs/remotes/origin/HEAD, refs/heads/main) Merge branch 'wlogout' into 'main'
d828b43 Updated CHANGELOG  with new Spanish text on power menu with -es flag
c78b8ea Merge branch 'wlogout' into 'main'
```

**Purpose**: This confirms the branch was created successfully and shows which commit it's based on. The HEAD should point to your new branch, and you should see the same commits as main.

### Step 4: Create Annotated Tag with Release Notes

Create an annotated tag with a comprehensive release message:

```bash
git tag -a v2.5.5 -m "New QS Powermenu - English/Español

Release v2.5.5 introduces a completely rewritten power menu (qs-wlogout) with:

🔓 Compact Qt6 QML power menu implementation
  - Small, centered floating window (520x320px) 
  - Six power options: Lock, Logout, Suspend, Hibernate, Shutdown, Reboot
  - Proper Hyprland integration with hyprctl dispatch exit
  - Semi-transparent styling with rounded corners
  - Keyboard shortcuts (L, E, U, H, S, R) and Escape to close

🇪🇸 Spanish language support
  - Use -es flag or QS_WLOGOUT_SPANISH=1 environment variable
  - Complete Spanish translations: Bloquear, Cerrar Sesión, Suspender, Hibernar, Apagar, Reiniciar
  - Configurable Hyprland binding for Spanish default mode

✨ Improved user experience
  - Eliminated large shadow/blur boxes around menu area
  - Click-to-close functionality
  - 64x64 PNG icons with fallback generation
  - Qt6 QML runtime for better performance"
```

**Expected output**: *(No output on success)*

**Purpose**: The `-a` flag creates an annotated tag (recommended for releases) and `-m` provides the message. Annotated tags store the tagger's information and are treated as full objects in Git.

**Tag Message Guidelines**:
- Start with a short, descriptive title
- Include major features and improvements
- Use emojis for visual clarity
- Be specific about user-facing changes
- Mention breaking changes if any

### Step 5: Verify Tag Creation

Check that the tag was created correctly:

```bash
git tag -l -n9 v2.5.5
```

**Expected output**:
```
v2.5.5          New QS Powermenu - English/Español
    
    Release v2.5.5 introduces a completely rewritten power menu (qs-wlogout) with:
    
    🔓 Compact Qt6 QML power menu implementation
      - Small, centered floating window (520x320px)
      - Six power options: Lock, Logout, Suspend, Hibernate, Shutdown, Reboot
      - Proper Hyprland integration with hyprctl dispatch exit
      - Semi-transparent styling with rounded corners
```

**Purpose**: The `-l` flag lists tags, `-n9` shows the first 9 lines of the annotation. This confirms the tag exists and has the correct message.

### Step 6: Push Branch to Origin

Push the new branch to the remote repository:

```bash
git push origin Stable-v2.5.5
```

**Expected output**:
```
Total 0 (delta 0), reused 0 (delta 0), pack-reused 0 (from 0)
remote: 
remote: To create a merge request for Stable-v2.5.5, visit:
remote:   https://gitlab.com/dwilliam62/ddubsos/-/merge_requests/new?merge_request%5Bsource_branch%5D=Stable-v2.5.5
remote: 
To gitlab.com:dwilliam62/ddubsos
 * [new branch]      Stable-v2.5.5 -> Stable-v2.5.5
```

**Purpose**: This creates the branch on the remote repository (GitLab/GitHub). The `* [new branch]` indicates it's a new remote branch.

### Step 7: Push Tag to Origin

Push the tag to the remote repository:

```bash
git push origin v2.5.5
```

**Expected output**:
```
Enumerating objects: 1, done.
Counting objects: 100% (1/1), done.
Writing objects: 100% (1/1), 733 bytes | 733.00 KiB/s, done.
Total 1 (delta 0), reused 0 (delta 0), pack-reused 0 (from 0)
To gitlab.com:dwilliam62/ddubsos
 * [new tag]         v2.5.5 -> v2.5.5
```

**Purpose**: This creates the tag on the remote repository. The `* [new tag]` indicates it's a new remote tag. Tags must be explicitly pushed (they don't get pushed with `git push` by default).

### Step 8: Verify Remote Creation

Confirm both the branch and tag exist locally and remotely:

```bash
git branch -v
```

**Expected output**:
```
  Stable-v2.5.4 5a8e18f Refixing guestures.nix for 0.51
* Stable-v2.5.5 8cd6bf3 Merge branch 'wlogout' into 'main'
  main          8cd6bf3 Merge branch 'wlogout' into 'main'
```

The `*` indicates the current branch.

```bash
git tag --list | tail -5
```

**Expected output**:
```
v2.5.1
v2.5.2
v2.5.3
v2.5.4
v2.5.5
```

**Purpose**: This confirms both the branch and tag were created successfully and shows the version progression.

## Quick Command Summary

For experienced users, here are the essential commands for creating a new release branch and tag:

```bash
# 1. Switch to and update main
git checkout main
git pull origin main

# 2. Create and switch to new stable branch
git checkout -b Stable-v2.5.5

# 3. Create annotated tag with release notes
git tag -a v2.5.5 -m "Release Title

Detailed release notes with:
- Feature descriptions
- Improvements
- Breaking changes
- Usage examples"

# 4. Push branch and tag to origin
git push origin Stable-v2.5.5
git push origin v2.5.5

# 5. Optional: Return to main for continued development
git checkout main
```

## Best Practices

### Naming Conventions
- **Branches**: `Stable-v[MAJOR].[MINOR].[PATCH]` (e.g., `Stable-v2.5.5`)
- **Tags**: `v[MAJOR].[MINOR].[PATCH]` (e.g., `v2.5.5`)
- Follow [Semantic Versioning](https://semver.org/):
  - **MAJOR**: Incompatible API changes
  - **MINOR**: New functionality, backwards compatible
  - **PATCH**: Bug fixes, backwards compatible

### Release Notes Guidelines
- Use a clear, descriptive title
- Group changes by category (🔓 Features, 🐛 Bug Fixes, ✨ Improvements)
- Use emojis for visual organization
- Include specific examples and usage instructions
- Mention any breaking changes prominently
- Keep user-facing language (avoid technical jargon)

### Branch Management
- Always create stable branches from main
- Keep stable branches for important releases
- Don't commit directly to stable branches after creation
- Use stable branches for hotfixes if needed

### Tag Management
- Always use annotated tags for releases (`-a` flag)
- Tags are immutable - don't modify after pushing
- Include comprehensive release notes in tag messages
- Push tags explicitly (`git push origin tag-name`)

## Troubleshooting

### Common Issues and Solutions

#### "Already exists" Error
```bash
error: tag 'v2.5.5' already exists
```
**Solution**: Check existing tags and increment version:
```bash
git tag --list | grep v2.5
# Use next available version number
```

#### Branch Already Exists
```bash
fatal: A branch named 'Stable-v2.5.5' already exists.
```
**Solution**: Either use the existing branch or delete it first:
```bash
git branch -D Stable-v2.5.5  # Delete local branch
git push origin --delete Stable-v2.5.5  # Delete remote branch (if exists)
```

#### Not on Latest Main
If your main branch is behind origin/main:
```bash
git pull origin main  # Pull latest changes
# Then restart the process
```

#### Permission Denied on Push
```bash
error: failed to push some refs to 'origin'
```
**Solution**: Ensure you have write access to the repository and are authenticated correctly.

#### Accidental Push to Wrong Remote
**Prevention**: Always verify remote with:
```bash
git remote -v
```

#### Tag Points to Wrong Commit
**Solution**: Delete and recreate the tag (if not yet pushed):
```bash
git tag -d v2.5.5  # Delete local tag
git tag -a v2.5.5 -m "Correct message"  # Recreate
```

### Verification Commands

Before creating releases, verify your environment:

```bash
# Check current branch and status
git status

# Check recent commits
git log --oneline -5

# Check existing branches
git branch -a

# Check existing tags
git tag --list

# Check remote configuration
git remote -v
```

---

## Notes

- This process is designed for ddubsOS development workflow
- Adapt tag messages for your specific release content
- Consider updating CHANGELOG.ddubs.md before creating releases
- Stable branches can be used for hotfixes if needed
- Tags create immutable snapshots for easy rollback

For questions or issues with this process, refer to the ddubsOS documentation or create an issue in the repository.
