# Git Pull All Repositories

This script scans directories for Git repositories and pulls updates from their remotes.

## Overview

The script reads a list of directories from a file and searches for Git repositories within them. For each repository found, it performs a `git pull` operation to update the repository with the latest changes from the remote.

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

- `--no-detail`, `--summary-only`: Hide individual repository processing details, only show final summary
- `--stash`: Stash local changes before pulling and pop them after pulling
- `--convert-ssh-to-https`: Convert SSH remote URLs to HTTPS
- `--debug`: Show debug information

## Features

- Automatically detects and updates all Git repositories in the specified directories
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

With default output (detailed):
```
Processing Git repository: /Users/user/projects/my-repo
--------------------------
GitHub URL: https://github.com/user/my-repo.git
  Performing git pull...
  Successfully pulled changes in /Users/user/projects/my-repo.

Processing Git repository: /Users/user/projects/another-repo
--------------------------
GitHub URL: https://github.com/user/another-repo.git
  Performing git pull...
  Repository is already up to date.

=== REPOSITORIES SUMMARY BY STATUS ===

Successfully pulled changes (1 repositories):
  - /Users/user/projects/my-repo: [GitHub URL: https://github.com/user/my-repo.git] - Successfully pulled changes

Already up to date (1 repositories):
  - /Users/user/projects/another-repo: [GitHub URL: https://github.com/user/another-repo.git] - Already up to date

Repositories with local changes (1):
  - /Users/user/projects/local-repo: [GitHub URL: https://github.com/user/local-repo.git] - Local changes exist

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

With summary-only mode (`--no-detail` or `--summary-only`):
```
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

## Troubleshooting

- If the script doesn't find any repositories, check that the directories in `directories.txt` exist and contain Git repositories.
- If a repository has local changes, the script will warn you and skip the pull operation. Use the `--stash` option to automatically stash and reapply changes.
- Run with `--debug` to see more detailed information about what the script is doing.

## Problem Categories

The script now tracks several specific types of problems:

1. **Local Changes**: Repositories with uncommitted local changes that prevent pulling.
2. **No Branch**: Repositories with no active branch or untracked branches.
3. **Repository Not Found**: Repositories where the remote URL no longer exists.
4. **Other Problems**: Any other issues that prevent successful pulling.