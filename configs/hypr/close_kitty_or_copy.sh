#!/bin/bash

# Fetch the active window details in JSON format
ACTIVE_WINDOW=$(hyprctl activewindow -j)

# Extract class and address
CLASS=$(echo "$ACTIVE_WINDOW" | jq -r '.class')
ADDRESS=$(echo "$ACTIVE_WINDOW" | jq -r '.address')

# If the active window is Kitty, close it. Otherwise, pass the Ctrl+C shortcut through.
if [ "$CLASS" = "kitty" ]; then
    hyprctl dispatch closewindow address:"$ADDRESS"
else
    hyprctl dispatch sendshortcut "CTRL, C, address:$ADDRESS"
fi
