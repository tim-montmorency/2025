#!/bin/bash

EXCLUDED_DIRS=(".git" "node_modules" "__pycache__" ".vscode")
SIDEBAR_FILE="_sidebar.md"

# Function to extract the title from README.md
get_title_from_readme() {
    local readme_path="$1"
    local title
    title=$(grep -m 1 "^# " "$readme_path" | sed 's/^# //')
    echo "$title"
}

# Function to check if README.md contains the generate comment
contains_generate_comment() {
    local readme_path="$1"
    grep -q "<!-- generate -->" "$readme_path"
}

# Start writing to _sidebar.md
> "$SIDEBAR_FILE"  # Clear the file, but don't write a header

# Function to walk through directories and generate the sidebar
generate_sidebar() {
    local dir_path="$1"
    local indent="$2"

    # Check for README.md in the current directory
    if [[ -f "$dir_path/README.md" ]]; then
        local title
        title=$(get_title_from_readme "$dir_path/README.md")
        if [[ -z "$title" ]]; then
            title=$(basename "$dir_path")
        fi
        # Remove any double slashes from the path and add leading slash for absolute path
        local clean_path
        clean_path=$(echo "$dir_path/" | sed 's://:/:g')
        clean_path="/${clean_path}"  # Add leading slash for absolute path

        echo "$indent* [$title]($clean_path)" >> "$SIDEBAR_FILE"
        echo "Added: $clean_path with title '$title'"

        # Check if README.md contains the generate comment and has subdirectories
        if contains_generate_comment "$dir_path/README.md"; then
            generate_readme_in_subfolders "$dir_path"
        fi
    else
        echo "Skipped directory (no README.md): $dir_path"
    fi

    # Recurse into subdirectories, avoiding too deep recursion
    for subdir in "$dir_path"/*/; do
        # Ensure subdir is a directory and avoid overly deep nesting
        if [[ -d "$subdir" ]]; then
            local base_dir
            base_dir=$(basename "$subdir")
            if [[ ! " ${EXCLUDED_DIRS[*]} " =~ " ${base_dir} " ]]; then
                generate_sidebar "$subdir" "  $indent"
            fi
        fi
    done
}

# Function to generate README.md in subfolders
generate_readme_in_subfolders() {
    local parent_dir="$1"
    local readme_path="$parent_dir/README.md"
    
    # Extract title from the current README.md
    local title
    title=$(get_title_from_readme "$readme_path")
    if [[ -z "$title" ]]; then
        title=$(basename "$parent_dir")
    fi

    # Start building the new README.md content
    local new_content="# $title\n\n<!-- generate -->\n\n"

    # Iterate over subdirectories and add links to each
    for subdir in "$parent_dir"/*/; do
        if [[ -d "$subdir" ]]; then
            local base_dir
            base_dir=$(basename "$subdir")
            local subdir_readme="$subdir/README.md"
            local subdir_title

            if [[ -f "$subdir_readme" ]]; then
                subdir_title=$(get_title_from_readme "$subdir_readme")
            fi

            if [[ -z "$subdir_title" ]]; then
                subdir_title="$base_dir"
            fi

            local clean_subdir_path
            clean_subdir_path=$(echo "$subdir" | sed 's://:/:g')
            clean_subdir_path="/${clean_subdir_path}"  # Add leading slash for absolute path

            new_content+="* [$subdir_title]($clean_subdir_path)\n"
            echo "Generated link for $clean_subdir_path with title '$subdir_title'"
        fi
    done

    # Write the new content back to the README.md
    echo -e "$new_content" > "$readme_path"
}

# Start from the current directory
for dir in */; do
    if [[ -d "$dir" ]]; then
        generate_sidebar "$dir" ""
    fi
done