#!/bin/bash

# Kill any existing Godot instances running this project
pkill -f "godot.*Elimination" 2>/dev/null
pkill -f "Elimination.app" 2>/dev/null

# Wait a moment for processes to terminate
sleep 0.5

# Find Godot executable
GODOT=""
if command -v godot &> /dev/null; then
    GODOT="godot"
elif [ -d "/Applications/Godot.app" ]; then
    GODOT="/Applications/Godot.app/Contents/MacOS/Godot"
elif [ -d "/Applications/Godot_mono.app" ]; then
    GODOT="/Applications/Godot_mono.app/Contents/MacOS/Godot"
else
    # Try common Godot 4 naming
    for app in /Applications/Godot*.app; do
        if [ -d "$app" ]; then
            GODOT="$app/Contents/MacOS/Godot"
            break
        fi
    done
fi

if [ -z "$GODOT" ]; then
    echo "Error: Godot not found. Please install Godot or add it to PATH."
    exit 1
fi

echo "Starting Elimination with: $GODOT"
cd "$(dirname "$0")"
"$GODOT" --path . 2>&1
