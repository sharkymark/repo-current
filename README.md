# Git Pull All Repositories

This script scans directories for Git repositories and pulls updates from their remotes.

## Overview

The script reads a list of directories from a file and searches for Git repositories within them. For each repository found, it performs a `git pull` operation to update the repository with the latest changes from the remote.

While pulls run, the script always prints a compact progress line per repo (ASCII bar, `i/N` counter, basename, and short result). This works with `--summary-only` / `--no-detail`, so long multi-repo runs do not sit silent. Full per-repo `git pull` text remains behind `--verbose`.

## Setup

1. Create a file named `directories.txt` in the same directory as the script.
2. Add the directories you want to scan for Git repositories to the file, one per line.
   * You can use environment variables like `$HOME` or `~` in the paths.

Example `directories.txt`:
```
$HOME/Documents/src
$HOME/projects
~/github
```

## Usage

```bash
./git_pull_all.sh [options]
```

### Options

- `--no-detail`, `--summary-only`: Hide individual repository processing details; still show live `i/N` progress, then the affected-repos summary and counts
- `--verbose`, `--detail`: Show full per-repo processing details (old verbose default)
- `--stash`: Stash local changes before pulling and pop them after pulling
- `--convert-ssh-to-https`: Convert SSH remote URLs to HTTPS
- `--debug`: Show debug information

## Features

- Automatically detects and updates all Git repositories in the specified directories
- Always-on progress: `[####------] [ 12/47] pulling  my-service ................. up-to-date`
- Shows accurate statistics about repositories processed:
  - Total repositories processed
  - Repositories with actual changes pulled
  - Repositories with problems
    - Repositories with local changes
    - Repositories with no branch
    - Repositories not found
    - Repositories with other problems
  - Repositories already up to date
- Groups repositories by status for clearer output
- Identifies repositories with local changes, no branches, and missing remote repositories
- Handles SSH and HTTPS remote URLs

## Example Output

With default / summary-only mode (`--no-detail` or `--summary-only`):
```
Scanning directory: /Users/user/projects for Git repositories...
Pulling 3 repositories...

[###-------] [  1/3] pulling  my-repo                                  in-progress
[###-------] [  1/3] pulling  my-repo                                  updated
[######----] [  2/3] pulling  another-repo                             in-progress
[######----] [  2/3] pulling  another-repo                             up-to-date
[##########] [  3/3] pulling  local-repo                               in-progress
[##########] [  3/3] pulling  local-repo                               local-changes

=== AFFECTED REPOSITORIES ===

Successfully pulled (1):
  - my-repo  https://github.com/user/my-repo.git

Local changes - pull skipped (1):
  - local-repo  https://github.com/user/local-repo.git  (Local changes exist)

Finished processing directories.
Total repositories processed: 3
Total repositories with actual changes pulled: 1
Total repositories with problems: 1
  - Total repositories with local changes: 1
  - Total repositories with no branch: 0
  - Total repositories not found: 0
  - Total repositories with other problems: 0
Total repositories already up to date: 1
```

Progress result labels: `up-to-date`, `updated`, `local-changes`, `no-branch`, `not-found`, `error`.

When a repo ends in `error` (summary mode), one truncated reason line is printed under that progress entry (first line of the git error, capped at 80 chars). Use `--verbose` for the full pull transcript.

Each repo prints an `in-progress` line before `git pull` (so a hung pull shows which repo is stuck), then the same prefix with a result label when that pull finishes.

With verbose mode (`--verbose` / `--detail`):
```
[###-------] [  1/3] pulling  my-repo                                  in-progress
Processing Git repository: /Users/user/projects/my-repo
--------------------------
GitHub URL: https://github.com/user/my-repo.git
  Performing git pull...
  Successfully pulled changes in /Users/user/projects/my-repo.
[###-------] [  1/3] pulling  my-repo                                  updated

=== REPOSITORIES SUMMARY BY STATUS ===

Successfully pulled changes (1 repositories):
  - /Users/user/projects/my-repo: [GitHub URL: https://github.com/user/my-repo.git] - Successfully pulled changes

Finished processing directories.
...
```

## Troubleshooting

- If the script doesn't find any repositories, check that the directories in `directories.txt` exist and contain Git repositories.
- If a repository has local changes, the script will warn you and skip the pull operation. Use the `--stash` option to automatically stash and reapply changes.
- Run with `--debug` to see more detailed information about what the script is doing.
- If progress seems stuck on one repo name, that pull is still running (network/auth); the next line appears when it finishes.

## Problem Categories

The script now tracks several specific types of problems:

1. **Local Changes**: Repositories with uncommitted local changes that prevent pulling.
2. **No Branch**: Repositories with no active branch or untracked branches.
3. **Repository Not Found**: Repositories where the remote URL no longer exists.
4. **Other Problems**: Any other issues that prevent successful pulling.
