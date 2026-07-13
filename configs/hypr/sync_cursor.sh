#!/usr/bin/env bash

THEME="$1"
SIZE="${2:-20}"

if [ -z "$THEME" ]; then
    exit 0
fi

# Update GTK 3 settings.ini
GTK3_FILE="$HOME/.config/gtk-3.0/settings.ini"
if [ -f "$GTK3_FILE" ]; then
    # Ensure [Settings] header exists
    if ! grep -q "\[Settings\]" "$GTK3_FILE"; then
        echo -e "[Settings]\n" > "$GTK3_FILE"
    fi
    # Update theme name
    if grep -q "gtk-cursor-theme-name=" "$GTK3_FILE"; then
        sed -i "s/gtk-cursor-theme-name=.*/gtk-cursor-theme-name=$THEME/g" "$GTK3_FILE"
    else
        echo "gtk-cursor-theme-name=$THEME" >> "$GTK3_FILE"
    fi
    # Update size
    if grep -q "gtk-cursor-theme-size=" "$GTK3_FILE"; then
        sed -i "s/gtk-cursor-theme-size=.*/gtk-cursor-theme-size=$SIZE/g" "$GTK3_FILE"
    else
        echo "gtk-cursor-theme-size=$SIZE" >> "$GTK3_FILE"
    fi
fi

# Update GTK 4 settings.ini
GTK4_FILE="$HOME/.config/gtk-4.0/settings.ini"
mkdir -p "$HOME/.config/gtk-4.0"
if [ ! -f "$GTK4_FILE" ]; then
    echo -e "[Settings]\n" > "$GTK4_FILE"
fi
# Update theme name
if grep -q "gtk-cursor-theme-name=" "$GTK4_FILE"; then
    sed -i "s/gtk-cursor-theme-name=.*/gtk-cursor-theme-name=$THEME/g" "$GTK4_FILE"
else
    echo "gtk-cursor-theme-name=$THEME" >> "$GTK4_FILE"
fi
# Update size
if grep -q "gtk-cursor-theme-size=" "$GTK4_FILE"; then
    sed -i "s/gtk-cursor-theme-size=.*/gtk-cursor-theme-size=$SIZE/g" "$GTK4_FILE"
else
    echo "gtk-cursor-theme-size=$SIZE" >> "$GTK4_FILE"
fi

# Update index.theme
INDEX_FILE="$HOME/.icons/default/index.theme"
mkdir -p "$HOME/.icons/default"
if [ ! -f "$INDEX_FILE" ]; then
    echo -e "[Icon Theme]\nName=Default\nComment=Default Cursor Theme" > "$INDEX_FILE"
fi
if grep -q "Inherits=" "$INDEX_FILE"; then
    sed -i "s/Inherits=.*/Inherits=$THEME/g" "$INDEX_FILE"
else
    echo "Inherits=$THEME" >> "$INDEX_FILE"
fi
