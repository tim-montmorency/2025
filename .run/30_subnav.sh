#!/bin/bash

EXCLUDED_DIRS=(".git" "node_modules" "__pycache__" ".vscode")

ROOT_DIR=$(pwd)

# Extracts title from the first line starting with '# ' in README.md
get_title_from_readme() {
    local readme_path="$1"
    grep -m 1 "^# " "$readme_path" | sed 's/^# //'
}

# Recursively generates a list of subdirectories that contain README.md, formatted as markdown links
generate_subnav_content() {
    local parent_dir="$1"
    local indent_level="$2"
    local content_lines=()

    parent_dir="${parent_dir%/}"

    for subdir in "$parent_dir"/*/; do
        if [[ -d "$subdir" ]]; then
            subdir="${subdir%/}"
            local base_dir
            base_dir=$(basename "$subdir")

            if [[ " ${EXCLUDED_DIRS[*]} " =~ " ${base_dir} " ]]; then
                continue
            fi

            local subdir_readme="$subdir/README.md"
            if [[ -f "$subdir_readme" ]]; then
                local subdir_title
                subdir_title=$(get_title_from_readme "$subdir_readme")
                [[ -z "$subdir_title" ]] && subdir_title="$base_dir"

                local relative_path="${subdir#$ROOT_DIR/}"
                relative_path="${relative_path#/}"
                relative_path="${relative_path%/}"

                local link
                if [[ -n "$relative_path" ]]; then
                    link="/${relative_path}/"
                else
                    link="/"
                fi

                local indent=""
                for ((i=0; i<indent_level; i++)); do
                    indent+="    "  # 4 spaces
                done
                content_lines+=("${indent}* [${subdir_title}](${link})")

                local sub_content
                sub_content=$(generate_subnav_content "$subdir" $((indent_level + 1)))
                if [[ -n "$sub_content" ]]; then
                    content_lines+=("$sub_content")
                fi
            fi
        fi
    done

    printf "%s\n" "${content_lines[@]}"
}

# Replaces content between <!-- start-replace-subnav --> and <!-- end-replace-subnav --> with new content
replace_content_between_tags() {
    local readme_path="$1"
    local subnav_content="$2"

    if grep -q "<!-- start-replace-subnav -->" "$readme_path" && grep -q "<!-- end-replace-subnav -->" "$readme_path"; then
        echo "Processing $readme_path..."

        # Find line numbers of the tags
        local start_line
        start_line=$(grep -n "<!-- start-replace-subnav -->" "$readme_path" | cut -d: -f1 | head -n 1)
        local end_line
        end_line=$(grep -n "<!-- end-replace-subnav -->" "$readme_path" | cut -d: -f1 | head -n 1)

        # If for some reason start > end, skip
        if [[ -z "$start_line" || -z "$end_line" || $start_line -gt $end_line ]]; then
            echo "Skipping $readme_path, invalid tag order."
            return
        fi

        # Construct the updated file:
        # 1. Lines before start tag
        # 2. Start tag line
        # 3. New subnav content
        # 4. End tag line
        # 5. Lines after end tag
        sed -n "1,$((start_line-1))p" "$readme_path" > "$readme_path.tmp"
        sed -n "${start_line}p" "$readme_path" >> "$readme_path.tmp"
        printf "%s\n" "$subnav_content" >> "$readme_path.tmp"
        sed -n "${end_line}p" "$readme_path" >> "$readme_path.tmp"
        sed -n "$((end_line+1)),\$p" "$readme_path" >> "$readme_path.tmp"

        mv "$readme_path.tmp" "$readme_path"

        echo "Updated $readme_path with new subnav content."
    else
        echo "Skipping $readme_path, <!-- start-replace-subnav --> or <!-- end-replace-subnav --> not found."
    fi
}

# Updates the given directory's README.md with subnavigation if README.md exists
generate_readme_in_subfolders() {
    local parent_dir="$1"
    local readme_path="$parent_dir/README.md"

    if [[ ! -f "$readme_path" ]]; then
        return
    fi

    local title
    title=$(get_title_from_readme "$readme_path")
    [[ -z "$title" ]] && title=$(basename "$parent_dir")

    local subnav_content
    subnav_content=$(generate_subnav_content "$parent_dir" 0)

    replace_content_between_tags "$readme_path" "$subnav_content"
}

# Recursively walk through directories to generate and insert subnav content
generate_subnav() {
    local dir_path="$1"
    dir_path="${dir_path%/}"

    if [[ -f "$dir_path/README.md" ]]; then
        generate_readme_in_subfolders "$dir_path"
    else
        echo "Skipped directory (no README.md): $dir_path"
    fi

    for subdir in "$dir_path"/*/; do
        if [[ -d "$subdir" ]]; then
            subdir="${subdir%/}"
            local base_dir
            base_dir=$(basename "$subdir")
            if [[ ! " ${EXCLUDED_DIRS[*]} " =~ " ${base_dir} " ]]; then
                generate_subnav "$subdir"
            fi
        fi
    done
}

# Start from the current directory
generate_subnav "$ROOT_DIR"
