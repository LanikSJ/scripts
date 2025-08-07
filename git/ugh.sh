#!/usr/bin/env bash
# 🧹🔄 Update all GitHub repos in a directory, delete old branches, and pull latest

set -euo pipefail

# 📁 Variables
GITHUB="${HOME}/GitHub/LanikSJ"
repolist=()

# 🗂️ Build repo list
for dir in "$GITHUB"/*; do
  [[ -d "$dir/.git" ]] && repolist+=("$(basename "$dir")")
done

# 🛠️ Update function
git_update() {
  local repo="$1"
  local branch="$2"
  echo -e "\n🔄 Updating $repo on branch $branch"
  git checkout "$branch"
  git pull
  
  # Prune remote tracking branches that no longer exist on remote
  echo "🧹 Pruning remote tracking branches..."
  git remote prune origin || true
  
  # Delete all local branches except the primary/default branch
  echo "🗑️ Deleting non-default local branches..."
  for b in $(git branch | grep -v " $branch\$" | grep -v "^\*" | awk '{print $NF}'); do
    echo "  🗑️ Deleting local branch: $b"
    git branch -D "$b" || true
  done
  
  # Delete remote tracking branches except the primary/default branch
  echo "🗑️ Deleting non-default remote tracking branches..."
  for b in $(git branch -r | grep -v "origin/$branch\$" | grep -v "origin/HEAD" | awk '{print $NF}'); do
    echo "  🗑️ Deleting remote tracking branch: $b"
    git branch -dr "$b" || true
  done
}

echo -e "\n🚀 Updating all LanikSJ Repos in $GITHUB"

# 🧵 Parallel update (default: 1 job)
JOBS=1
pids=()
for repo in "${repolist[@]}"; do
  (
    cd "$GITHUB/$repo"
    # Detect primary branch
    if git show-ref --verify --quiet refs/heads/develop; then
      branch="develop"
    elif git show-ref --verify --quiet refs/heads/dev; then
      branch="dev"
    elif git show-ref --verify --quiet refs/heads/main; then
      branch="main"
    else
      branch="master"
    fi
    git_update "$repo" "$branch"
    echo "✅ $repo updated."
  ) &
  pids+=($!)
  # Limit parallel jobs
  if (( ${#pids[@]} >= JOBS )); then
    wait -n
    # Remove finished jobs from array
    for i in "${!pids[@]}"; do
      if ! kill -0 "${pids[$i]}" 2>/dev/null; then unset 'pids[i]'; fi
    done
  fi
done

# Wait for all jobs to finish
wait

echo -e "\n🎉 All repositories updated!"
