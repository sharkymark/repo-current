# Project Overview

This repository contains a bash script (`git_pull_all.sh`) that automates the process of pulling updates from remote Git repositories. It scans a list of top-level directories (specified in `directories.txt`) for Git repositories and performs a `git pull` operation in each repository.

## Features
- Reads a list of directories from a configuration file (`directories.txt`).
- Recursively scans directories for Git repositories.
- Checks for local changes before pulling updates (can be skipped with a configuration flag).
- Provides warnings for untracked branches or local changes.
- Handles errors gracefully and provides detailed logs.
- Optionally stashes and applies local changes using the `--stash` argument.

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

## License

This project is licensed under the MIT License. See the LICENSE file for details.