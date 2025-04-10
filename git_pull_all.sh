#!/bin/bash
# --- Configuration ---
DIRECTORIES_FILE="directories.txt" # File containing the list of top-level directories
SKIP_CLEAN_CHECK=false             # Set to true to skip checking for local changes
                                  # before attempting git pull (use with caution)

# --- Functions ---

# Function to perform git pull in a given directory
    git_pull_directory() {
      local dir="$1"
      local STASHED=false

      if [[ -d "$dir" && -d "$dir/.git" ]]; then
        echo "Processing Git repository: $dir"
        cd "$dir" || return 1

        # Check for local changes
        if [[ "$SKIP_CLEAN_CHECK" == "false" ]]; then
          if ! git diff --quiet; then
            echo "  Warning: Local changes exist in $dir. Git pull may fail."
            echo "  Consider committing or stashing your changes."
            cd - > /dev/null || return 1
            return 0
          fi
        fi

        echo "  Performing git pull..."
        if git pull; then
          echo "  Successfully pulled changes in $dir."
          if [[ "$STASHED" == "true" ]]; then
            echo "  Applying stashed changes in $dir..."
            git stash pop --index --quiet
            unset STASHED
          fi
        else
          if ! git rev-parse --abbrev-ref --symbolic-full-name @{u} > /dev/null 2>&1; then
            echo "  Warning: No tracking information for the current branch in $(basename "$dir")."
            echo "  Git pull might not have fetched from a remote. Consider setting an upstream branch."
          else
            echo "  Error: Failed to pull changes in $dir. Check for local changes, network issues, or conflicts."
          fi
        fi

        cd - > /dev/null || return 1
      else
        echo "Error: '$dir' is not a valid Git repository."
      fi
    }

# --- Main Script ---

# Check if the directories file exists
if [[ ! -f "$DIRECTORIES_FILE" ]]; then
  echo "Error: The directories file '$DIRECTORIES_FILE' does not exist."
  echo "Please create this file and list the top-level directories you want to scan, one per line."
  exit 1
fi

# Read the list of top-level directories from the file
while IFS= read -r raw_directory; do

  # Trim leading and trailing whitespace
  top_level_dir=$(echo "$raw_directory" | xargs)

  echo "DEBUG (raw): raw_directory is: '$raw_directory'"
  echo "DEBUG (trimmed): top_level_dir before expansion is: '$top_level_dir'"

  # Explicitly expand $HOME
  expanded_dir=$(eval echo "$top_level_dir")

  echo "DEBUG (expanded): expanded_dir is: '$expanded_dir'"

  # Skip empty lines and comments
  if [[ -n "$expanded_dir" && ! "$expanded_dir" =~ ^# ]]; then
    echo "Scanning directory: $expanded_dir for Git repositories..."
    find "$expanded_dir" -type d -name ".git" -print0 | while IFS= read -r -d $'\0' git_dir; do
      repo_dir=$(dirname "$git_dir")
      git_pull_directory "$repo_dir"
    done
  fi
done < "$DIRECTORIES_FILE"

echo "Finished processing directories."

exit 0