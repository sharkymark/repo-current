# Project Overview

This repository contains a bash script (`git_pull_all.sh`) that automates the process of pulling updates from remote Git repositories. It scans a list of top-level directories (specified in `directories.txt`) for Git repositories and performs a `git pull` operation in each repository.

## Features
- Reads a list of directories from a configuration file (`directories.txt`).
- Recursively scans directories for Git repositories.
- The script skips repositories with no branch, as they are likely not linked to a remote.
- Checks for local changes before pulling updates (can be skipped with a configuration flag).
- Provides warnings for untracked branches or local changes.
- Handles errors gracefully and provides detailed logs.
- Optionally stashes and applies local changes using the `--stash` argument.
- Automatically creates an empty `directories.txt` file if it is missing and warns the user.
- Tallies the total number of repositories processed and those with problems, displaying the counts as the final output.
- Extracts and displays the GitHub URL for each repository during processing.
- `--stash`: Stash and apply changes during git pull.
- `--debug`: Enable debug output for troubleshooting.
- `--convert-ssh-to-https`: Converts SSH-based Git remotes to HTTPS during processing (for stronger security using personal access tokens).
- Counts and displays the number of repositories that successfully pulled changes.


## Sample `directories.txt` Entry
```
$HOME/documents/src
```

## Usage

Before running the script, ensure it is executable:
```
chmod +x git_pull_all.sh
```

Run the script without stashing local changes:
```
./git_pull_all.sh
```

Run the script with the `--stash` argument to stash and apply local changes:
```
./git_pull_all.sh --stash
```

## Sample Output

### Successful Pull
When the script successfully pulls updates from a repository, it displays:
```
Processing Git repository: /Users/markmilligan/Documents/src/v2-templates
--------------------------
GitHub URL: https://github.com/sharkymark/v2-templates.git
  Performing git pull...
Already up to date.
  Successfully pulled changes in /Users/markmilligan/Documents/src/v2-templates.
```

### Failed Pull when local changes exist
When the script encounters local changes, it displays:
```
Processing Git repository: /Users/markmilligan/Documents/src/db
--------------------------
GitHub URL: https://github.com/sharkymark/db.git
  Warning: Local changes exist in /Users/markmilligan/Documents/src/db. Git pull may fail.
  Consider committing or stashing your changes.
```

### Failed Pull due to untracked branch
When the script encounters an untracked branch, it displays:
```
Processing Git repository: /Users/markmilligan/Documents/src/aider
--------------------------
No GitHub URL found for this repository.
  Performing git pull...
There is no tracking information for the current branch.
Please specify which branch you want to rebase against.
See git-pull(1) for details.

    git pull <remote> <branch>

If you wish to set tracking information for this branch you can do so with:

    git branch --set-upstream-to=origin/<branch> main

  Error: Failed to pull changes in /Users/markmilligan/Documents/src/aider. Check for local changes, network issues, or conflicts.
```

## Final Output
At the end of the script execution, the following summary is displayed:
- Total repositories processed.
- Total repositories with problems (e.g., failed pulls or local changes).

### Example Summary
```
Finished processing directories.
Total repositories processed: 33
Total repositories successfully pulled: 3
Total repositories with problems: 6
```

## License

This project is licensed under the MIT License. See the LICENSE file for details.