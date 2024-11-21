#!/bin/bash

set -e

# Get OS Version
OS_MAJOR_VER=$(sw_vers -productVersion | awk -F'.' '{print $1}')

CONFIG_FILE="/var/root/.DIT/DIT.cfg"
TARGET_KEY="General"
REPLACEMENT_VALUE="true"

if [[ ! -e "/var/root/.DIT/" ]]; then
    echo "Creating Dir '/var/root/.DIT/'"
    mkdir "/var/root/.DIT/"
fi

if [[ ! -e "$CONFIG_FILE" ]]; then
    printf "$CONFIG_FILE not Found! Creating...\n"
    echo '[Runflags]
Finder = false
Dock = false
General = false
Desktop = false' > "$CONFIG_FILE"
    
    while [[ ! -e $CONFIG_FILE ]]; do
        sleep 5
    done
fi

FILE_CONTENT=$(<"$CONFIG_FILE")

if [[ -e "$CONFIG_FILE" ]]; then
    CURRENT_VALUE=$(echo "$FILE_CONTENT" | grep "^$TARGET_KEY = " | sed "s/^$TARGET_KEY = //")
    if [[ "$CURRENT_VALUE" == "false" ]]; then
        if [[ "$OS_MAJOR_VER" == "11" ]]; then
            
            # Define the target directory
            target_dir="/Users"

            # Loop through each directory in the target directory
            for dir in "$target_dir"/*; do
                # Check if it is a directory
                if [[ -d "$dir" ]]; then
                    # Remove the leading path and trailing slash
                    dir_name=$(basename "$dir")
                    
                    # Perform an action (e.g., echo the directory name)
                    echo "Processing Directory: /Users/$dir_name"
                    plist_file="/Users/$dir_name/Library/Preferences/ByHost/com.apple.controlcenter.plist"
                    if [[ -e "$plist_file" ]]; then
                        defaults write "$plist_file" "BatteryShowPercentage" -bool true
                    fi
                fi
            done

            # Prevent Sleep
            pmset -a sleep 0
            pmset -a displaysleep 0
            pmset -a disksleep 0

            # Rename OS Volume
            echo "Renaming OS Volume..."
            VOL_NAME=$(diskutil info / | grep "Volume Name:" | awk -F': ' '{print $2}' | tr -d '[:space:]')
            VOL_PATH=$(diskutil info / | grep "Device Node:" | awk -F': ' '{print $2}' | tr -d '[:space:]')

            HOSTNAME=$(hostname)
            HOSTNAME=${HOSTNAME/.local/}

            if [[ "$VOL_NAME" == "$HOSTNAME" ]]; then
                echo "Hostname is Already Set Correctly."
            else
                diskutil rename "$VOL_PATH" "$HOSTNAME"
            fi
            
            # Updates
            echo "Configuring Updates..."
            softwareupdate -i -a > /dev/null 2>&1
            defaults write com.apple.SoftwareUpdate AutomaticDownload -int 1

            # Update Runflags
            echo "Updating Runflags..."
            MODIFIED_CONTENT=$(echo "$FILE_CONTENT" | awk -v key="$TARGET_KEY" -v value="$REPLACEMENT_VALUE" '
            BEGIN { FS = OFS = " = " }
            $1 == key { $2 = value }
            { print }
            ')
            echo "$MODIFIED_CONTENT" > "$CONFIG_FILE"
            echo "Successful."
        else
            echo "This Script is Only Supported on macOS Big Sur (11.x)!" 
        fi
    else
        echo "Script Already Ran!"
    fi
fi
