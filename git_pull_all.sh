#!/bin/bash
# --- Configuration ---
DIRECTORIES_FILE="directories.txt" # File containing the list of top-level directories
SKIP_CLEAN_CHECK=false             # Set to true to skip checking for local changes
STASHED=false                      # Default value for stashing changes
debug_mode=false                   # Default value for debug mode
convert_ssh_to_https=false         # Default value for converting SSH to HTTPS
show_details=true                  # Default value for showing repository details

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
    --no-detail)
      show_details=false
      shift
      ;;
    --summary-only)
      show_details=false
      shift
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# --- Functions ---

# Arrays to store repositories by status
declare -a actually_pulled_repos=()
declare -a already_up_to_date_repos=()
declare -a local_changes_repos=()
declare -a no_branch_repos=()
declare -a repo_not_found_repos=()
declare -a other_problems_repos=()

# Function to add repo to the appropriate array with its message
add_to_status_array() {
  local repo="$1"
  local status="$2"
  local message="$3"
  
  case "$status" in
    "pulled")
      actually_pulled_repos+=("$repo: $message")
      ;;
    "up-to-date")
      already_up_to_date_repos+=("$repo: $message")
      ;;
    "local-changes")
      local_changes_repos+=("$repo: $message")
      ;;
    "no-branch")
      no_branch_repos+=("$repo: $message")
      ;;
    "repo-not-found")
      repo_not_found_repos+=("$repo: $message")
      ;;
    "other-problem")
      other_problems_repos+=("$repo: $message")
      ;;
  esac
}

# Function to perform git pull in a given directory
git_pull_directory() {
  local dir="$1"
  local pull_status=0
  local details=""
  local repo_status_message=""

  if [[ -d "$dir" && -d "$dir/.git" ]]; then
    details+="Processing Git repository: $dir\n"
    details+="--------------------------\n"
    
    if [[ "$show_details" == "true" ]]; then
      echo
      echo "Processing Git repository: $dir"
      echo "--------------------------"
    fi
    
    cd "$dir" || return 1

    # Extract GitHub URL
    github_url=$(git remote get-url origin 2>/dev/null)
    if [[ -n "$github_url" ]]; then
      details+="GitHub URL: $github_url\n"
      repo_status_message="[GitHub URL: $github_url]"
      
      if [[ "$show_details" == "true" ]]; then
        echo "GitHub URL: $github_url"
      fi

      # Convert SSH to HTTPS if the flag is set
      if [[ "$convert_ssh_to_https" == "true" && "$github_url" =~ ^git@github.com:(.*) ]]; then
        https_url="https://github.com/${BASH_REMATCH[1]}"
        git remote set-url origin "$https_url"
        details+="  Converted remote URL from SSH to HTTPS: $https_url\n"
        
        if [[ "$show_details" == "true" ]]; then
          echo "  Converted remote URL from SSH to HTTPS: $https_url"
        fi
      fi
    else
      details+="No GitHub URL found for this repository.\n"
      repo_status_message="[No GitHub URL found]"
      
      if [[ "$show_details" == "true" ]]; then
        echo "No GitHub URL found for this repository."
      fi
    fi

    # Check if the repository has a branch
    current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    if [[ -z "$current_branch" || "$current_branch" == "HEAD" ]]; then
      details+="  No branch found, so skipping\n"
      
      if [[ "$show_details" == "true" ]]; then
        echo "  No branch found, so skipping"
      fi
      
      cd - > /dev/null || return 1
      add_to_status_array "$dir" "no-branch" "$repo_status_message - No branch found"
      return 3  # Return code for no branch
    fi

    # Check for local changes
    if [[ "$SKIP_CLEAN_CHECK" == "false" ]]; then
      if ! git diff --quiet; then
        details+="  Warning: Local changes exist in $dir. Git pull may fail.\n"
        details+="  Consider committing or stashing your changes.\n"
        
        if [[ "$show_details" == "true" ]]; then
          echo "  Warning: Local changes exist in $dir. Git pull may fail."
          echo "  Consider committing or stashing your changes."
        fi
        
        cd - > /dev/null || return 1
        add_to_status_array "$dir" "local-changes" "$repo_status_message - Local changes exist"
        return 4  # Return code for local changes
      fi
    fi

    details+="  Performing git pull...\n"
    
    if [[ "$show_details" == "true" ]]; then
      echo "  Performing git pull..."
    fi
    
    # Update logic to track actual pull status
    pull_output=$(git pull 2>&1)
    pull_exit_code=$?
    
    if echo "$pull_output" | grep -q "There is no tracking information for the current branch."; then
      details+="  Error: Untracked branch detected in $dir. Skipping.\n"
      
      if [[ "$show_details" == "true" ]]; then
        echo "  Error: Untracked branch detected in $dir. Skipping."
      fi
      
      cd - > /dev/null || return 1
      add_to_status_array "$dir" "no-branch" "$repo_status_message - Untracked branch"
      return 3  # Return code for no branch
    elif echo "$pull_output" | grep -q -E "remote: Repository not found|fatal: repository.*not found"; then
      details+="  Error: Repository not found: $github_url\n"
      details+="  $pull_output\n"
      
      if [[ "$show_details" == "true" ]]; then
        echo "  Error: Repository not found: $github_url"
        echo "  $pull_output"
      fi
      
      cd - > /dev/null || return 1
      add_to_status_array "$dir" "repo-not-found" "$repo_status_message - Repository not found"
      return 5  # Return code for repository not found
    elif echo "$pull_output" | grep -q "Already up to date."; then
      details+="  Repository is already up to date.\n"
      
      if [[ "$show_details" == "true" ]]; then
        echo "  Repository is already up to date."
      fi
      
      cd - > /dev/null || return 1
      add_to_status_array "$dir" "up-to-date" "$repo_status_message - Already up to date"
      return 0
    elif [ $pull_exit_code -ne 0 ]; then
      details+="  Error while pulling repository $dir.\n"
      details+="  $pull_output\n"
      
      if [[ "$show_details" == "true" ]]; then
        echo "  Error while pulling repository $dir."
        echo "  $pull_output"
      fi
      
      cd - > /dev/null || return 1
      add_to_status_array "$dir" "other-problem" "$repo_status_message - Error: $pull_output"
      return 1
    else
      details+="  Successfully pulled changes in $dir.\n"
      
      if [[ "$show_details" == "true" ]]; then
        echo "  Successfully pulled changes in $dir."
      fi
      
      if [[ "$STASHED" == "true" ]]; then
        details+="  Applying stashed changes in $dir...\n"
        
        if [[ "$show_details" == "true" ]]; then
          echo "  Applying stashed changes in $dir..."
        fi
        
        git stash pop --index --quiet
      fi
      
      cd - > /dev/null || return 1
      add_to_status_array "$dir" "pulled" "$repo_status_message - Successfully pulled changes"
      return 2  # Special code for actual changes pulled
    fi

    if [[ "$show_details" == "true" ]]; then
      echo
    fi
  else
    details+="Error: '$dir' is not a valid Git repository.\n"
    
    if [[ "$show_details" == "true" ]]; then
      echo "Error: '$dir' is not a valid Git repository."
    fi
    
    add_to_status_array "$dir" "other-problem" "Not a valid Git repository"
    return 1
  fi
}

# --- Main Script ---

# Fix repository counting logic
repos_processed=0
repos_with_problems=0
repos_already_up_to_date=0
repos_actually_pulled=0
repos_local_changes=0
repos_no_branch=0
repos_not_found=0
repos_other_problems=0

# Store repo paths to process them outside the find subshell
declare -a repo_dirs

# Check if the directories file exists and is not empty
if [[ ! -f "$DIRECTORIES_FILE" ]]; then
  echo "Warning: The directories file '$DIRECTORIES_FILE' does not exist."
  echo "Creating an empty '$DIRECTORIES_FILE' file. Please add directories to this file."
  touch "$DIRECTORIES_FILE"
  exit 1
elif [[ ! -s "$DIRECTORIES_FILE" ]]; then
  echo "Warning: The directories file '$DIRECTORIES_FILE' is empty."
  echo "Please add directories to this file."
  exit 1
fi

# Add debug log to confirm the script is reading the directories file
if [[ "$debug_mode" == "true" ]]; then
  echo "DEBUG: Reading directories file: $DIRECTORIES_FILE"
  cat "$DIRECTORIES_FILE"
fi

# Add debug log to confirm the content of the directories file
if [[ "$debug_mode" == "true" ]]; then
  echo "DEBUG: Content of directories file:"
  cat "$DIRECTORIES_FILE"
fi

# Add debug log to confirm the loop starts
if [[ "$debug_mode" == "true" ]]; then
  echo "DEBUG: Starting to process directories from $DIRECTORIES_FILE"
fi

# Ensure each line is trimmed and expanded correctly
while IFS= read -r raw_directory; do
  # Expand $HOME and other variables
  expanded_dir=$(eval echo "$raw_directory")

  if [[ "$debug_mode" == "true" ]]; then
    echo "DEBUG: Expanded directory: '$expanded_dir'"
  fi

  # Skip empty lines and comments
  if [[ -n "$expanded_dir" && ! "$expanded_dir" =~ ^# ]]; then
    echo "Scanning directory: $expanded_dir for Git repositories..."

    # Add debug log to confirm the find command is executed
    if [[ "$debug_mode" == "true" ]]; then
      echo "DEBUG: Executing find command in directory: '$expanded_dir'"
    fi

    # Ensure the find command output is processed correctly
    while IFS= read -r -d $'\0' git_dir; do
      if [[ "$debug_mode" == "true" ]]; then
        echo "DEBUG: Found .git directory at $git_dir"
      fi
      repo_dir=$(dirname "$git_dir")
      if [[ -d "$repo_dir" ]]; then
        if [[ "$debug_mode" == "true" ]]; then
          echo "DEBUG: Adding repository directory to process: $repo_dir"
        fi
        # Store repo paths instead of processing immediately
        repo_dirs+=("$repo_dir")
      else
        if [[ "$debug_mode" == "true" ]]; then
          echo "DEBUG: Skipping invalid directory: $repo_dir"
        fi
      fi
    done < <(find "$expanded_dir" -type d -name ".git" -print0)

    # Add debug log if no .git directories are found
    if [[ "$debug_mode" == "true" ]]; then
      git_dirs_count=$(find "$expanded_dir" -type d -name ".git" | wc -l)
      if [[ $git_dirs_count -eq 0 ]]; then
        echo "DEBUG: No .git directories found in $expanded_dir"
      else
        echo "DEBUG: Total .git directories found: $git_dirs_count"
      fi
    fi
  fi

done < "$DIRECTORIES_FILE"

# Process all repositories outside the subshell
if [[ "$debug_mode" == "true" ]]; then
  echo "DEBUG: Processing ${#repo_dirs[@]} repositories"
fi

for repo_dir in "${repo_dirs[@]}"; do
  repos_processed=$((repos_processed + 1))
  git_pull_directory "$repo_dir"
  pull_status=$?
  
  case $pull_status in
    0)
      # Repository already up to date
      repos_already_up_to_date=$((repos_already_up_to_date + 1))
      ;;
    1)
      # Problem with pull (other errors)
      repos_with_problems=$((repos_with_problems + 1))
      repos_other_problems=$((repos_other_problems + 1))
      ;;
    2)
      # Actual changes were pulled
      repos_actually_pulled=$((repos_actually_pulled + 1))
      ;;
    3)
      # No branch or untracked branch
      repos_with_problems=$((repos_with_problems + 1))
      repos_no_branch=$((repos_no_branch + 1))
      ;;
    4)
      # Local changes
      repos_with_problems=$((repos_with_problems + 1))
      repos_local_changes=$((repos_local_changes + 1))
      ;;
    5)
      # Repository not found
      repos_with_problems=$((repos_with_problems + 1))
      repos_not_found=$((repos_not_found + 1))
      ;;
  esac
done

# Add debug log to confirm the loop has finished
if [[ "$debug_mode" == "true" ]]; then
  echo "DEBUG: Finished processing directories from $DIRECTORIES_FILE"
fi

# Add two blank lines after processing the last repository for better readability
echo
echo

# Print sorted repository lists if details should be shown
if [[ "$show_details" == "true" ]]; then
  echo "=== REPOSITORIES SUMMARY BY STATUS ==="
  echo
  
  if [[ ${#actually_pulled_repos[@]} -gt 0 ]]; then
    echo "Successfully pulled changes (${#actually_pulled_repos[@]} repositories):"
    for repo in "${actually_pulled_repos[@]}"; do
      echo "  - $repo"
    done
    echo
  fi
  
  if [[ ${#already_up_to_date_repos[@]} -gt 0 ]]; then
    echo "Already up to date (${#already_up_to_date_repos[@]} repositories):"
    for repo in "${already_up_to_date_repos[@]}"; do
      echo "  - $repo"
    done
    echo
  fi
  
  if [[ ${#local_changes_repos[@]} -gt 0 ]]; then
    echo "Repositories with local changes (${#local_changes_repos[@]}):"
    for repo in "${local_changes_repos[@]}"; do
      echo "  - $repo"
    done
    echo
  fi
  
  if [[ ${#no_branch_repos[@]} -gt 0 ]]; then
    echo "Repositories with no branch or untracked branch (${#no_branch_repos[@]}):"
    for repo in "${no_branch_repos[@]}"; do
      echo "  - $repo"
    done
    echo
  fi
  
  if [[ ${#repo_not_found_repos[@]} -gt 0 ]]; then
    echo "Repositories not found (${#repo_not_found_repos[@]}):"
    for repo in "${repo_not_found_repos[@]}"; do
      echo "  - $repo"
    done
    echo
  fi
  
  if [[ ${#other_problems_repos[@]} -gt 0 ]]; then
    echo "Repositories with other problems (${#other_problems_repos[@]}):"
    for repo in "${other_problems_repos[@]}"; do
      echo "  - $repo"
    done
    echo
  fi
fi

# Final output
echo "Finished processing directories."
echo "Total repositories processed: $repos_processed"
echo "Total repositories with actual changes pulled: $repos_actually_pulled"
echo "Total repositories with problems: $repos_with_problems"
echo "  - Total repositories with local changes: $repos_local_changes"
echo "  - Total repositories with no branch: $repos_no_branch"
echo "  - Total repositories not found: $repos_not_found"
echo "  - Total repositories with other problems: $repos_other_problems"
echo "Total repositories already up to date: $repos_already_up_to_date"

# Show details at the end if requested
if [[ "$show_details" == "false" && ${#repo_dirs[@]} -gt 0 ]]; then
  echo 
  echo "Repository processing details can be shown with: ./$(basename "$0")"
  echo "Hide details with: ./$(basename "$0") --no-detail"
fi

exit 0