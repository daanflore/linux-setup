#!/bin/bash

# Script to create a new application folder from template
# This script creates a new application folder based on the template
# and updates all necessary variables in the copied files

set -e

# Function to get input from console
get_input() {
    local prompt="$1"
    local default="$2"
    local input=""
    TEST123=2
    # Show prompt with default value if provihed
    if [ -n "$default" ]; then
        printf "%s [%s]: " "$prompt" "$default"
    else
        printf "%s: " "$prompt"
    fi
    
    # Read user input on the same line
    read -r input
    
    # If input is empty and default exists, use default
    if [ -z "$input" ] && [ -n "$default" ]; then
        echo "$default"
    else
        echo "$input"
    fi
}

# Function to create a properly sized text box based on content
create_text_box() {
    # Store the lines in an array
    local lines=(
        "NEXT STEPS"
        ""
        "1. Verify the content of the files in $APP_DIR"
        "2. Search for svg icon to put in the svg file"
        "3. Run $APP_DIR/__deploy.sh to deploy the application"
        "4. To remove later, run $APP_DIR/__undeploy.sh"
        ""
    )

    # Find the longest line to determine box width
    local max_length=0
    for line in "${lines[@]}"; do
        # Use parameter expansion to calculate visible length
        if [[ ${#line} -gt $max_length ]]; then
            max_length=${#line}
        fi
    done

    # Add padding for margins and formatting
    local box_width=$((max_length + 6))  # 2 chars on each side + 2 for '│ ' prefix

    # Create the top border with title
    printf "┌─ %s %s┐\n" "${lines[0]}" "$(printf '─%.0s' $(seq $((box_width - ${#lines[0]} - 4))))"

    # Print content lines with proper padding
    for ((i=1; i<${#lines[@]}; i++)); do
        local line="${lines[$i]}"
        local padding=$((box_width - ${#line} - 2))
        printf "│ %-${padding}s │\n" "$line"
    done

    # Create the bottom border
    printf "└%s┘\n" "$(printf '─%.0s' $(seq $((box_width))))"
}

# Get workspace directory
WORKSPACE_DIR="$(dirname "$(readlink -f "$0")")"
TEMPLATE_DIR="$WORKSPACE_DIR/template"

# Check if template directory exists
if [ ! -d "$TEMPLATE_DIR" ]; then
    echo "Error: Template directory not found: $TEMPLATE_DIR"
    exit 1
fi

# Get APP_NAME and REPO_NAME from user
echo "==== Application Setup ====="
echo "Please provide the following information:"
echo ""

printf "Enter the application name (e.g., myapp): "
read -r APP_NAME
if [ -z "$APP_NAME" ]; then
    echo "Error: Application name is required. Exiting."
    exit 1
fi
echo "✓ Application name set to: $APP_NAME"

printf "Enter the repository name (e.g., username/repo): "
read -r REPO_NAME
if [ -z "$REPO_NAME" ]; then
    echo "Error: Repository name is required. Exiting."
    exit 1
fi
echo "✓ Repository name set to: $REPO_NAME"

printf "Enter a generic description for the application (e.g., 'Text Editor'): "
read -r GENERIC_NAME
if [ -z "$GENERIC_NAME" ]; then
    echo "No generic description provided, using default."
    GENERIC_NAME="Application"
fi
echo "✓ Generic description set to: $GENERIC_NAME"
echo ""

# Create new application directory
APP_DIR="$WORKSPACE_DIR/$APP_NAME"
echo "Creating application directory: $APP_DIR"

# Check if app directory already exists
if [ -d "$APP_DIR" ]; then
    echo "Warning: Directory $APP_DIR already exists."
    echo -n "Do you want to overwrite it? [y/N]: "
    read OVERWRITE
    if [[ ! "$OVERWRITE" =~ ^[Yy](es)?$ ]]; then
        echo "Operation cancelled by user."
        exit 0
    fi
    echo "Removing existing directory..."
    rm -rf "$APP_DIR"
fi

# Create the directory
echo "Creating fresh directory for the application..."
mkdir -p "$APP_DIR"
echo "✓ Directory created: $APP_DIR"

# Copy and process files from template
echo "Creating application files for $APP_NAME..."

# Find all files in template directory
echo "Processing template files..."
find "$TEMPLATE_DIR" -type f | sort | while read -r template_file; do
    filename=$(basename "$template_file")
    echo "Handling file: $filename"
    
    # Handle special scripts that need separate processing
    if [ "$filename" = "__deploy.sh" ] || [ "$filename" = "__undeploy.sh" ]; then
        # Copy the script to the appropriate destination
        dest_file="$APP_DIR/$filename"
        echo "Processing special file: $filename -> $dest_file"
        cp "$template_file" "$dest_file"
        
        # Update variables in the script by directly writing to a temp file
        echo "  - Setting APP_NAME to $APP_NAME"
        temp_file=$(mktemp)
        while IFS= read -r line; do
            if [[ "$line" == "APP_NAME=" ]]; then
                echo "APP_NAME=$APP_NAME" >> "$temp_file"
            elif [[ "$line" == "REPO_NAME=" ]]; then
                echo "REPO_NAME=$REPO_NAME" >> "$temp_file"
            else
                echo "$line" >> "$temp_file"
            fi
        done < "$dest_file"
        mv "$temp_file" "$dest_file"
        echo "  - Setting REPO_NAME to $REPO_NAME"
        
        # Make it executable
        echo "  - Making script executable"
        chmod +x "$dest_file"
    else
        # For all other files, rename from template.* to APP_NAME.*
        new_filename="${filename/template/$APP_NAME}"
        # Handle files without 'template' in the name (like README.MD)
        if [ "$new_filename" = "$filename" ]; then
            # If filename doesn't contain 'template', keep the original name
            new_filename="$filename"
        fi
        dest_file="$APP_DIR/$new_filename"
        
        echo "Processing file: $filename -> $new_filename"
        # Copy the file
        cp "$template_file" "$dest_file"
        
        # ===== DESKTOP FILE SPECIFIC PROCESSING =====
        # Handle special configuration for .desktop files which require specific formatting
        if [[ "$filename" == *.desktop ]]; then
            echo "  - Special handling for desktop file"
            
            # Create capitalized version of APP_NAME for display purposes in the desktop environment
            APP_NAME_CAPITALIZED="$(tr '[:lower:]' '[:upper:]' <<< ${APP_NAME:0:1})${APP_NAME:1}"
            
            # === Update standard .desktop file entries ===
            # The Name field appears in application launchers
            echo "    - Updating Name field to capitalized app name"
            sed -i "s/^Name=.*/Name=$APP_NAME_CAPITALIZED/" "$dest_file"
            
            # The GenericName is a general description that appears as a tooltip in some launchers
            echo "    - Updating GenericName field with provided description"
            sed -i "s/^GenericName=.*/GenericName=$GENERIC_NAME/" "$dest_file"
            
            # StartupWMClass helps window managers associate windows with the correct launcher
            echo "    - Updating StartupWMClass field"
            sed -i "s/^StartupWMClass=.*/StartupWMClass=$APP_NAME/" "$dest_file"
            
            # Exec defines the command to run when the application is launched
            echo "    - Updating Exec field"
            sed -i "s|^Exec=.*|Exec=BIN_DIR/$APP_NAME --no-sandbox|" "$dest_file"
            
            # Icon defines the path to the application icon
            echo "    - Updating Icon field"
            sed -i "s|^Icon=.*|Icon=HOME/.local/share/icons/$APP_NAME.svg|" "$dest_file"
            
            # MimeType defines which file types/URLs the application can handle
            echo "    - Updating MimeType field"
            sed -i "s|x-scheme-handler/[^;]*;|x-scheme-handler/$APP_NAME;|" "$dest_file"
            
            # Replace any remaining template or bruno references with the new app name
            echo "    - Replacing any other occurrences of template or bruno"
            sed -i "s/template/$APP_NAME/g" "$dest_file"
            sed -i "s/bruno/$APP_NAME/g" "$dest_file"
            
            echo "  - ✓ Desktop file updated with appropriate values"
        fi
        
        echo "  - ✓ File processed successfully"
    fi
done || { echo "Error: File processing loop exited with an error"; exit 1; }

# Verify all files were copied
echo "✓ All files processed!"
echo "Files in destination directory:"
find "$APP_DIR" -type f | sort

echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║                      SUCCESS!                            ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""
echo "✓ Application $APP_NAME has been created in: $APP_DIR"
echo "✓ All template files were copied and updated successfully"
echo ""

# Replace the static box with dynamically sized box
create_text_box

# End of script
