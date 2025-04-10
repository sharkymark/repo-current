# Project Overview

This repository contains a bash script (`git_pull_all.sh`) that automates the process of pulling updates from remote Git repositories. It scans a list of top-level directories (specified in `directories.txt`) for Git repositories and performs a `git pull` operation in each repository.

## Features
- Reads a list of directories from a configuration file (`directories.txt`).
- Recursively scans directories for Git repositories.
- Checks for local changes before pulling updates (can be skipped with a configuration flag).
- Provides warnings for untracked branches or local changes.
- Handles errors gracefully and provides detailed logs.
- Optionally stashes and applies local changes using the `--stash` argument.
- Automatically creates an empty `directories.txt` file if it is missing and warns the user.
- Tallies the total number of repositories processed and those with problems, displaying the counts as the final output.
- `--stash`: Stash and apply changes during git pull.
- `--debug`: Enable debug output for troubleshooting.

## Sample `directories.txt` Entry
```
$HOME/documents/src
```

## Usage

Run the script without stashing local changes:
```
./git_pull_all.sh
```

Run the script with the `--stash` argument to stash and apply local changes:
```
./git_pull_all.sh --stash
```

## Final Output
At the end of the script execution, the following summary is displayed:
- Total repositories processed.
- Total repositories with problems (e.g., failed pulls or local changes).

## License

This project is licensed under the MIT License. See the LICENSE file for details.