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
    
    # Show prompt with default value if provided
    if [ -n "$default" ]; then
        echo -n "$prompt [$default]: "
    else
        echo -n "$prompt: "
    fi
    
    # Read user input
    read input
    
    # If input is empty and default exists, use default
    if [ -z "$input" ] && [ -n "$default" ]; then
        echo "$default"
    else
        echo "$input"
    fi
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

APP_NAME=$(get_input "Enter the application name (e.g., myapp)" "")
if [ -z "$APP_NAME" ]; then
    echo "Error: Application name is required. Exiting."
    exit 1
fi
echo "✓ Application name set to: $APP_NAME"

REPO_NAME=$(get_input "Enter the repository name (e.g., username/repo)" "")
if [ -z "$REPO_NAME" ]; then
    echo "Error: Repository name is required. Exiting."
    exit 1
fi
echo "✓ Repository name set to: $REPO_NAME"
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
find "$TEMPLATE_DIR" -type f -name "*" | while read template_file; do
    filename=$(basename "$template_file")
    
    # Skip the file if it's __deploy.sh (it will be handled separately)
    if [ "$filename" = "__deploy.sh" ]; then
        # Copy deploy script directly, but update its content
        dest_file="$APP_DIR/__deploy.sh"
        echo "Processing special file: $filename -> $dest_file"
        cp "$template_file" "$dest_file"
        
        # Update variables in the deploy script
        echo "  - Setting APP_NAME to $APP_NAME"
        sed -i "s/^APP_NAME=$/APP_NAME=$APP_NAME/g" "$dest_file"
        echo "  - Setting REPO_NAME to $REPO_NAME"
        sed -i "s/^REPO_NAME=$/REPO_NAME=$REPO_NAME/g" "$dest_file"
        
        # Make it executable
        echo "  - Making script executable"
        chmod +x "$dest_file"
    else
        # For all other files, rename from bruno.* to APP_NAME.*
        new_filename="${filename/bruno/$APP_NAME}"
        dest_file="$APP_DIR/$new_filename"
        
        echo "Processing file: $filename -> $new_filename"
        # Copy the file
        cp "$template_file" "$dest_file"
        
        # Replace any occurrence of 'bruno' with APP_NAME in the file content
        echo "  - Updating file content with application name"
        sed -i "s/bruno/$APP_NAME/g" "$dest_file"
        
        # If this is a desktop file, update the Name field with capitalized APP_NAME
        if [[ "$dest_file" == *.desktop ]]; then
            echo "  - Special handling for desktop file: capitalizing Name field"
            # Create capitalized version of APP_NAME (first letter uppercase)
            APP_NAME_CAPITALIZED="$(tr '[:lower:]' '[:upper:]' <<< ${APP_NAME:0:1})${APP_NAME:1}"
            # Update the Name field with the capitalized version
            sed -i "s/^Name=.*/Name=$APP_NAME_CAPITALIZED/" "$dest_file"
            echo "  - ✓ Desktop file Name field updated to: $APP_NAME_CAPITALIZED"
        fi
        
        echo "  - ✓ File processed successfully"
    fi
done

echo "✓ All files processed!"

echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║                      SUCCESS!                            ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""
echo "✓ Application $APP_NAME has been created in: $APP_DIR"
echo "✓ All template files were copied and updated successfully"
echo ""

echo "┌─ NEXT STEPS ──────────────────────────────────────────┐"
echo "│                                                        │"
echo "│  1. Verify the content of the files in $APP_DIR       │"
echo "│  2. Run $APP_DIR/__deploy.sh to deploy the application│"
echo "│                                                        │"
echo "└────────────────────────────────────────────────────────┘"
