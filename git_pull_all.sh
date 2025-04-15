#!/bin/bash
# --- Configuration ---
DIRECTORIES_FILE="directories.txt" # File containing the list of top-level directories
SKIP_CLEAN_CHECK=false             # Set to true to skip checking for local changes
STASHED=false                      # Default value for stashing changes
debug_mode=false                   # Default value for debug mode
convert_ssh_to_https=false         # Default value for converting SSH to HTTPS

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
    --convert-ssh-to-https)
      convert_ssh_to_https=true
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

    # Extract GitHub URL
    github_url=$(git remote get-url origin 2>/dev/null)
    if [[ -n "$github_url" ]]; then
      echo "GitHub URL: $github_url"

      # Convert SSH to HTTPS if the flag is set
      if [[ "$convert_ssh_to_https" == "true" && "$github_url" =~ ^git@github.com:(.*) ]]; then
        https_url="https://github.com/${BASH_REMATCH[1]}"
        git remote set-url origin "$https_url"
        echo "  Converted remote URL from SSH to HTTPS: $https_url"
      fi
    else
      echo "No GitHub URL found for this repository."
    fi

    # Check if the repository has a branch
    current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    if [[ -z "$current_branch" || "$current_branch" == "HEAD" ]]; then
      echo "  No branch found, so skipping"
      cd - > /dev/null || return 1
      return 0
    fi

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
    # Update logic to exclude untracked branches from successful pull count
    if git pull 2>&1 | grep -q "There is no tracking information for the current branch."; then
      echo "  Error: Untracked branch detected in $dir. Skipping."
      repos_with_problems=$((repos_with_problems + 1))
    elif git pull | grep -q "Already up to date."; then
      echo "  Repository is already up to date."
    else
      echo "  Successfully pulled changes in $dir."
      repos_successfully_pulled=$((repos_successfully_pulled + 1))
      if [[ "$STASHED" == "true" ]]; then
        echo "  Applying stashed changes in $dir..."
        git stash pop --index --quiet
      fi
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
repos_successfully_pulled=0

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

# Add two blank lines after processing the last repository for better readability
echo
echo

# Final output
echo "Finished processing directories."
echo "Total repositories processed: $repos_processed"
echo "Total repositories successfully pulled: $repos_successfully_pulled"
echo "Total repositories with problems: $repos_with_problems"

exit 0