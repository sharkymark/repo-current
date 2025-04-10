#!/bin/bash
# --- Configuration ---
DIRECTORIES_FILE="directories.txt" # File containing the list of top-level directories
SKIP_CLEAN_CHECK=false             # Set to true to skip checking for local changes
STASHED=false                      # Default value for stashing changes
debug_mode=false                   # Default value for debug mode

# Add a heading at the start of the program
echo "================================"
echo "Git Pull All Repositories Script"
echo "================================"
echo "This script scans directories for Git repositories and pulls updates."
echo

# --- Parse Command-Line Arguments ---
while [[ $# -gt 0 ]]; do
  case $1 in
    --stash)
      STASHED=true
      shift
      ;;
    --debug)
      debug_mode=true
      shift
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# --- Functions ---

# Function to perform git pull in a given directory
git_pull_directory() {
  local dir="$1"

  if [[ -d "$dir" && -d "$dir/.git" ]]; then
    echo
    echo "Processing Git repository: $dir"
    echo "--------------------------"
    cd "$dir" || return 1

    # Check for local changes
    if [[ "$SKIP_CLEAN_CHECK" == "false" ]]; then
      if ! git diff --quiet; then
        echo "  Warning: Local changes exist in $dir. Git pull may fail."
        echo "  Consider committing or stashing your changes."
        cd - > /dev/null || return 1
        return 1
      fi
    fi

    echo "  Performing git pull..."
    if git pull; then
      echo "  Successfully pulled changes in $dir."
      if [[ "$STASHED" == "true" ]]; then
        echo "  Applying stashed changes in $dir..."
        git stash pop --index --quiet
      fi
    else
      echo "  Error: Failed to pull changes in $dir. Check for local changes, network issues, or conflicts."
      cd - > /dev/null || return 1
      return 1
    fi

    echo
    cd - > /dev/null || return 1
    return 0
  else
    echo "Error: '$dir' is not a valid Git repository."
    return 1
  fi
}

# --- Main Script ---

# Initialize counters
repos_processed=0
repos_with_problems=0

# Check if the directories file exists
if [[ ! -f "$DIRECTORIES_FILE" ]]; then
  echo "Warning: The directories file '$DIRECTORIES_FILE' does not exist."
  echo "Creating an empty '$DIRECTORIES_FILE' file. Please add directories to this file."
  touch "$DIRECTORIES_FILE"
  exit 1
fi

# Read the list of top-level directories from the file
while IFS= read -r raw_directory; do

  # Trim leading and trailing whitespace
  top_level_dir=$(echo "$raw_directory" | xargs)

  if [[ "$debug_mode" == "true" ]]; then
    echo "DEBUG (raw): raw_directory is: '$raw_directory'"
    echo "DEBUG (trimmed): top_level_dir before expansion is: '$top_level_dir'"
  fi

  # Explicitly expand $HOME
  expanded_dir=$(eval echo "$top_level_dir")

  if [[ "$debug_mode" == "true" ]]; then
    echo "DEBUG (expanded): expanded_dir is: '$expanded_dir'"
  fi

  # Skip empty lines and comments
  if [[ -n "$expanded_dir" && ! "$expanded_dir" =~ ^# ]]; then
    echo "Scanning directory: $expanded_dir for Git repositories..."
    while IFS= read -r -d $'\0' git_dir; do
      repo_dir=$(dirname "$git_dir")
      if git_pull_directory "$repo_dir"; then
        repos_processed=$((repos_processed + 1))
      else
        repos_processed=$((repos_processed + 1))
        repos_with_problems=$((repos_with_problems + 1))
      fi
    done < <(find "$expanded_dir" -type d -name ".git" -print0)
  fi

done < "$DIRECTORIES_FILE"

# Final output
echo "Finished processing directories."
echo "Total repositories processed: $repos_processed"
echo "Total repositories with problems: $repos_with_problems"

exit 0