#!/bin/bash

# Get OS Version
OS_MAJOR_VER=$(sw_vers -productVersion | awk -F'.' '{print $1}')

CONFIG_FILE="/var/root/.DIT/DIT.cfg"
TARGET_KEY="Finder"
REPLACEMENT_VALUE="true"

rm -f $CONFIG_FILE # TEMP

if [[ ! -e "/var/root/.DIT/" ]]; then
    echo "Creating Dir '/var/root/.DIT/'"
    mkdir "/var/root/.DIT/"
fi

if [[ ! -e "$CONFIG_FILE" ]]; then
    echo "$CONFIG_FILE Not Found! Creating..."
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
    if [[ "$CURRENT_VALUE" = "false" ]]; then
        if [[ "$OS_MAJOR_VER" = "11" ]]; then
            
            echo "Arranging Desktop and Finder by Grid..."
            # Define the target directory
            TARGET_DIR="/Users"
            # Loop through each directory in the target directory
            for DIR in "$TARGET_DIR"/*; do
                # Check if it is a directory
                if [[ -d "$DIR" ]]; then
                    # Remove the leading path and trailing slash
                    USER=$(basename "$DIR")
                    
                    if [[ $USER != "Library" && $USER != "Shared" ]]; then
                        # Perform an action (e.g., echo the directory name)
                        echo "Processing Directory: /Users/$USER"
                        CONFIG_FILE="/Users/$USER/Library/Preferences/com.apple.finder.plist"
                        EXISTS=$(/usr/libexec/PlistBuddy -c "Print $KEY_PATH" "$CONFIG_FILE" 2>/dev/null)
                        if [[ ! -z "$EXISTS" ]]; then
                            echo "Key $KEY_PATH exists!"
                        else
                            echo "Unexpected Finder Structure for $USER, Resetting..."
                            rm -f $CONFIG_FILE
                            killall Finder
                            sleep 15
                        fi

                        if [[ -e "$CONFIG_FILE" ]]; then
                            /usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:arrangeBy grid" "$CONFIG_FILE"
                            /usr/libexec/PlistBuddy -c "Set :StandardViewSettings:IconViewSettings:arrangeBy grid" "$CONFIG_FILE"
                        fi
                    fi
                fi
            done

            # Configure Finder 
            echo "Configuring Finder..."
            defaults write com.apple.finder "ShowHardDrivesOnDesktop" -bool "true"
            defaults write com.apple.finder "ShowExternalHardDrivesOnDesktop" -bool "true"
            defaults write com.apple.finder "ShowRemovableMediaOnDesktop" -bool "true"
            defaults write com.apple.finder "_FXSortFoldersFirst" -bool "true"
            defaults write com.apple.finder "ShowPathbar" -bool "true"
            defaults write com.apple.finder "ShowStatusBar" -bool "true"

            # Restart Finder
            echo "Restarting Finder to Ensure Changes are Displayed..."
            killall Finder

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
