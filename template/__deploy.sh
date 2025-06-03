#!/bin/bash

set -e

BIN_DIR=~/.local/bin
APP_NAME=
REPO_NAME=
[[ -d $BIN_DIR ]] || mkdir -p $BIN_DIR

DIR=$(dirname "$(readlink -f "$0")")

curl -s curl -s https://api.github.com/repos/"$REPO_NAME"/releases/latest | grep -P 'browser_download_url(?!.*arm64).*AppImage' | cut -d '"' -f 4 | xargs curl -L -o $BIN_DIR/$APP_NAME

chmod +x $BIN_DIR/$APP_NAME

cp "$DIR"/"$APP_NAME".desktop ~/.local/share/applications/"$APP_NAME".desktop
cp "$DIR"/"$APP_NAME".svg ~/.local/share/icons/"$APP_NAME".svg

sed -i "s|BIN_DIR|$BIN_DIR|g" ~/.local/share/applications/"$APP_NAME".desktop
sed -i "s|HOME|$HOME|" ~/.local/share/applications/"$APP_NAME".desktop

update-desktop-database ~/.local/share/applications

