#!/bin/bash

# Get OS Version
OS_MAJOR_VER=$(sw_vers -productVersion | awk -F'.' '{print $1}')

CONFIG_FILE="/var/root/.DIT/daffodil.cfg"
TARGET_KEY="Finder"
REPLACEMENT_VALUE="true"

rm -f $CONFIG_FILE # TEMP

if [[ ! -e "/var/root/.DIT/" ]]; then
    echo "Creating Dir '/var/root/.DIT/'"
    mkdir "/var/root/.DIT/"
fi

if [[ ! -e "$CONFIG_FILE" ]]; then
    echo "'$CONFIG_FILE' Not Found! Creating..."
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
        if [[ "$OS_MAJOR_VER" == "11" || "$OS_MAJOR_VER" == "12" ]]; then
            
            echo "Arranging Desktop and Finder by Grid..."
            # Define the target directory
            TARGET_DIR="/Users"
            # Loop through each directory in the target directory
             # Configure Finder 
            echo "Configuring Finder..."
            echo ""
            for DIR in "$TARGET_DIR"/*; do
                # Check if it is a directory
                if [[ -d "$DIR" ]]; then
                    # Remove the leading path and trailing slash
                    USER=$(basename "$DIR")
                    
                    if [[ $USER != "Library" && $USER != "Shared" ]]; then
                        # Perform an action (e.g., echo the directory name)
                        echo "Processing Directory: '/Users/$USER'"
                        CONFIG_FILE="/Users/$USER/Library/Preferences/com.apple.finder.plist"

                        if [[ -e "$CONFIG_FILE" ]]; then
                            echo "Deleting '$CONFIG_FILE'"
                            rm -f "$CONFIG_FILE"

                            if [ ! -e "$CONFIG_FILE" ]; then
                                echo "* Restarting Finder to Regenerate '$CONFIG_FILE' *"
                                killall Finder
                                sleep 20
                            else
                                echo "Failed to remove '$CONFIG_FILE'"
                                exit 1
                            fi    

                            echo "Configuring Finder for '$USER'..."
                            /usr/libexec/PlistBuddy -c "Print :ShowHardDrivesOnDesktop" "$CONFIG_FILE" && \
                            /usr/libexec/PlistBuddy -c "Delete :ShowHardDrivesOnDesktop" "$CONFIG_FILE"
                            /usr/libexec/PlistBuddy -c "Add :ShowHardDrivesOnDesktop bool true" "$CONFIG_FILE"

                            /usr/libexec/PlistBuddy -c "Print :ShowExternalHardDrivesOnDesktop" "$CONFIG_FILE" && \
                            /usr/libexec/PlistBuddy -c "Delete :ShowExternalHardDrivesOnDesktop" "$CONFIG_FILE"
                            /usr/libexec/PlistBuddy -c "Add :ShowExternalHardDrivesOnDesktop bool true" "$CONFIG_FILE"

                            /usr/libexec/PlistBuddy -c "Print :ShowRemovableMediaOnDesktop" "$CONFIG_FILE" && \
                            /usr/libexec/PlistBuddy -c "Delete :ShowRemovableMediaOnDesktop" "$CONFIG_FILE"
                            /usr/libexec/PlistBuddy -c "Add :ShowRemovableMediaOnDesktop bool true" "$CONFIG_FILE"

                            /usr/libexec/PlistBuddy -c "Print :_FXSortFoldersFirst" "$CONFIG_FILE" && \
                            /usr/libexec/PlistBuddy -c "Delete :_FXSortFoldersFirst" "$CONFIG_FILE"
                            /usr/libexec/PlistBuddy -c "Add :_FXSortFoldersFirst bool true" "$CONFIG_FILE"

                            /usr/libexec/PlistBuddy -c "Print :ShowPathbar" "$CONFIG_FILE" && \
                            /usr/libexec/PlistBuddy -c "Delete :ShowPathbar" "$CONFIG_FILE"
                            /usr/libexec/PlistBuddy -c "Add :ShowPathbar bool true" "$CONFIG_FILE"

                            /usr/libexec/PlistBuddy -c "Print :ShowStatusBar" "$CONFIG_FILE" && \
                            /usr/libexec/PlistBuddy -c "Delete :ShowStatusBar" "$CONFIG_FILE"
                            /usr/libexec/PlistBuddy -c "Add :ShowStatusBar bool true" "$CONFIG_FILE"

                            /usr/libexec/PlistBuddy -c "Print :DesktopViewSettings:IconViewSettings:arrangeBy" "$CONFIG_FILE" && \
                            /usr/libexec/PlistBuddy -c "Delete :DesktopViewSettings:IconViewSettings:arrangeBy" "$CONFIG_FILE"
                            /usr/libexec/PlistBuddy -c "Add :DesktopViewSettings:IconViewSettings:arrangeBy string grid" "$CONFIG_FILE"

                            /usr/libexec/PlistBuddy -c "Print :StandardViewSettings:IconViewSettings:arrangeBy" "$CONFIG_FILE" && \
                            /usr/libexec/PlistBuddy -c "Delete :StandardViewSettings:IconViewSettings:arrangeBy" "$CONFIG_FILE"
                            /usr/libexec/PlistBuddy -c "Add :StandardViewSettings:IconViewSettings:arrangeBy string grid" "$CONFIG_FILE"
                        fi
                    fi
                fi
            done

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
