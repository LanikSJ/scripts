#!/bin/bash
# Script to delete all GitHub Actions workflow runs for a specific workflow in a repository

set -euo pipefail

# Function to display usage
usage() {
    echo "📖 Usage: $0 [OPTIONS] OWNER REPO WORKFLOW"
    echo ""
    echo "🗑️ Delete all GitHub Actions workflow runs for a specific workflow."
    echo ""
    echo "🔷 Arguments:"
    echo "  OWNER      GitHub repository owner"
    echo "  REPO       Repository name"
    echo "  WORKFLOW   Workflow ID (number) or workflow name"
    echo ""
    echo "⚙️ Options:"
    echo "  -h, --help     Show this help message"
    echo "  -g, --get-id   Get workflow ID by name and exit"
    echo "  -y, --yes      Skip confirmation prompt"
    echo "  -v, --verbose  Show detailed output"
    echo ""
    echo "💡 Examples:"
    echo "  $0 LanikSJ webannoyances \"CI\""
    echo "  $0 -y octocat hello-world 114706658"
    echo "  $0 -g LanikSJ webannoyances \"CI\""
    exit 1
}

# Check dependencies
check_dependencies() {
    local deps=("gh" "jq")
    local missing=()

    for dep in "${deps[@]}"; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            missing+=("$dep")
        fi
    done

    if [ ${#missing[@]} -ne 0 ]; then
        echo "❌ Error: Missing required dependencies: ${missing[*]}" >&2
        echo "🔧 Please install them and try again." >&2
        exit 1
    fi
}

# Find workflow ID by name
get_workflow_id() {
    local owner="$1"
    local repo="$2"
    local workflow_name="$3"

    # First try to match workflow ID directly
    if [[ "$workflow_name" =~ ^[0-9]+$ ]]; then
        echo "$workflow_name"
        return
    fi

    # Find workflow by name
    local workflow_id
    workflow_id=$(gh api -X GET "/repos/$owner/$repo/actions/workflows" |
                  jq -r ".workflows[] | select(.name == \"$workflow_name\" or .path == \"$workflow_name\") | .id")

    if [ -z "$workflow_id" ]; then
        echo "❌ Error: Could not find workflow '$workflow_name'. Available workflows:" >&2
        gh api -X GET "/repos/$owner/$repo/actions/workflows" | jq -r '.workflows[] | "\(.name) (\(.id))"'
        exit 1
    fi

    echo "$workflow_id"
}

# Main function
main() {
    local skip_confirm=false
    local verbose=false
    local get_id=false

    # Parse options
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                usage
                ;;
            -g|--get-id)
                get_id=true
                shift
                ;;
            -y|--yes)
                skip_confirm=true
                shift
                ;;
            -v|--verbose)
                verbose=true
                shift
                ;;
            -*)
                echo "Error: Unknown option '$1'" >&2
                usage
                ;;
            *)
                break
                ;;
        esac
    done

    # Check required arguments
    if [ $# -ne 3 ]; then
        echo "❌ Error: Missing required arguments" >&2
        usage
    fi

    local owner="$1"
    local repo="$2"
    local workflow="$3"

    check_dependencies

    # Get workflow ID
    local workflow_id
    workflow_id=$(get_workflow_id "$owner" "$repo" "$workflow")
    if [ "$get_id" = true ]; then
        echo "$workflow_id"
        exit 0
    fi
    if [ "$verbose" = true ]; then
        echo "ℹ️ Resolved workflow '$workflow' to ID: $workflow_id"
    fi

    # Get run IDs (only once)
    echo "🔄 Fetching workflow runs..."
    local run_ids
    run_ids=$(gh api -X GET "/repos/$owner/$repo/actions/workflows/$workflow_id/runs" --paginate |
              jq -r '.workflow_runs[].id')

    if [ -z "$run_ids" ]; then
        echo "ℹ️ No workflow runs found for workflow ID $workflow_id"
        exit 0
    fi

    local run_count
    run_count=$(echo "$run_ids" | wc -l)
    echo "✅ Found $run_count workflow runs to delete"

    # Show details if verbose
    if [ "$verbose" = true ]; then
        local run_list
        run_list=$(echo "$run_ids" | paste -sd ',' - | sed 's/,$//')
        echo "📋 Run IDs: $run_list"
    fi

    # Confirm deletion
    if [ "$skip_confirm" = false ]; then
        read -p "Delete $run_count workflow runs? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "❌ Operation cancelled."
            exit 0
        fi
    fi

    # Delete runs
    echo "Deleting workflow runs..."
    local deleted_count=0
    while IFS= read -r run_id; do
        if [ "$verbose" = true ]; then
            echo "🔄 Deleting run $run_id..."
        fi
        if gh api -X DELETE "/repos/$owner/$repo/actions/runs/$run_id" --silent; then
            ((deleted_count++))
            if [ "$verbose" = true ] && [ $((deleted_count % 10)) -eq 0 ]; then
                echo "✅ Deleted $deleted_count/$run_count runs..."
            fi
        else
            echo "❌ Failed to delete run $run_id" >&2
        fi
    done <<< "$run_ids"

    echo "✅ Successfully deleted $deleted_count workflow runs"
}

main "$@"
