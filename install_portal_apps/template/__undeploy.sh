#!/bin/bash
# Undeployment script to remove all changes made by the __deploy.sh script

set -e

# Define variables
BIN_DIR=~/.local/bin
APP_NAME=
REPO_NAME=
CONFIG_DIR=~/.config/"$APP_NAME"

# Get directory of this script
DIR=$(dirname "$(readlink -f "$0")")

# Print header
echo "========================================"
echo "Undeploying $APP_NAME"
echo "========================================"

# Remove executable from bin directory
if [ -f "$BIN_DIR/$APP_NAME" ]; then
    echo "Removing executable: $BIN_DIR/$APP_NAME"
    rm -f "$BIN_DIR/$APP_NAME"
    echo "✓ Executable removed"
else
    echo "! Executable not found at $BIN_DIR/$APP_NAME"
fi

# Remove desktop file
if [ -f ~/.local/share/applications/"$APP_NAME".desktop ]; then
    echo "Removing desktop file: ~/.local/share/applications/$APP_NAME.desktop"
    rm -f ~/.local/share/applications/"$APP_NAME".desktop
    echo "✓ Desktop file removed"
else
    echo "! Desktop file not found"
fi

# Remove icon
if [ -f ~/.local/share/icons/"$APP_NAME".svg ]; then
    echo "Removing icon: ~/.local/share/icons/$APP_NAME.svg"
    rm -f ~/.local/share/icons/"$APP_NAME".svg
    echo "✓ Icon removed"
else
    echo "! Icon file not found"
fi

# Check for config directory - case insensitive search
echo "Checking for configuration directories..."
CONFIG_DIRS=$(find ~/.config -maxdepth 1 -type d -iname "$APP_NAME" 2>/dev/null || echo "")

if [ -n "$CONFIG_DIRS" ]; then
    echo ""
    echo "Configuration directories found:"
    echo "$CONFIG_DIRS"
    echo "These may contain your personal settings and data."
    echo -n "Do you want to remove these directories? [y/N]: "
    read -r REMOVE_CONFIG
    
    if [[ "$REMOVE_CONFIG" =~ ^[Yy](es)?$ ]]; then
        echo "Removing configuration directories..."
        for dir in $CONFIG_DIRS; do
            echo "Removing: $dir"
            rm -rf "$dir"
        done
        echo "✓ Configuration directories removed"
    else
        echo "Keeping configuration directories"
    fi
else
    echo "No configuration directories found matching: $APP_NAME"
fi

# Update desktop database to reflect changes
echo "Updating desktop database"
update-desktop-database ~/.local/share/applications
echo "✓ Desktop database updated"

echo ""
echo "========================================"
echo "✓ $APP_NAME has been successfully undeployed"
echo "========================================"