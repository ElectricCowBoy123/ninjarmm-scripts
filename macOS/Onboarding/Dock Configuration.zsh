#!/bin/bash

# Get OS Version
OS_MAJOR_VER=$(sw_vers -productVersion | awk -F'.' '{print $1}')

CONFIG_FILE="/var/root/.DIT/DIT.cfg"
TARGET_KEY="Dock"
REPLACEMENT_VALUE="true"

set_dock_icon_size() {
    local icon_size=$1
    local plist_file="$HOME/Library/Preferences/com.apple.dock.plist"

    # Check if the plist file exists
    if [ ! -f "$plist_file" ]; then
        echo "Plist file not found: $plist_file"
        return 1
    fi

    # Check if the tilesize key exists, if not, add it
    /usr/libexec/PlistBuddy -c "Print :tilesize" "$plist_file" &>/dev/null
    if [ $? -ne 0 ]; then
        echo "tilesize key does not exist. Adding key..."
        /usr/libexec/PlistBuddy -c "Add :tilesize integer $icon_size" "$plist_file"
    else
        echo "tilesize key exists. Updating value..."
        /usr/libexec/PlistBuddy -c "Set :tilesize $icon_size" "$plist_file"
    fi

    # Restart Dock to apply changes
    killall Dock

    echo "Dock icon size set to $icon_size. Dock restarted."
}

if [[ ! -e "/var/root/.DIT/" ]]; then
    echo "Creating Dir '/var/root/.DIT/'"
    mkdir "/var/root/.DIT/"
fi

if [[ ! -e "$CONFIG_FILE" ]]; then
    printf "$CONFIG_FILE Not Found! Creating...\n"
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

if [ -e "$CONFIG_FILE" ]; then
    echo "$CONFIG_FILE found!" 
    echo ""
    CURRENT_VALUE=$(echo "$FILE_CONTENT" | grep "^$TARGET_KEY = " | sed "s/^$TARGET_KEY = //")
    if [[ "$CURRENT_VALUE" == "false" ]]; then
        if [[ "$OS_MAJOR_VER" == "11" ]]; then
            items_to_pin=("/Applications/Safari.app" "/System/Applications/Launchpad.app")
            target_dir="/Users"
            for dir in "$target_dir"/*; do
                # Check if it is a directory
                if [ -d "$dir" ]; then
                    # Remove the leading path and trailing slash
                    dir_name=$(basename "$dir")
                    
                    # Perform an action (e.g., echo the directory name)
                    echo "- Processing directory: /Users/$dir_name"
                    plist_file="/Users/$dir_name/Library/Preferences/com.apple.dock.plist"
                    if [ -e "$plist_file" ]; then
                        echo ""
                        echo "Deleting $plist_file"
                        rm $plist_file

                        if [ ! -e "$plist_file" ]; then
                            echo "* Restarting Dock to Regenerate com.apple.dock.plist *"
                            killall Dock
                            sleep 15
                        else
                            echo "Failed to remove $plist_file"
                            exit 1
                        fi    

                        echo "Pinning & Unpinning Icons on the Dock..."
                        if [ -e "$plist_file" ]; then
                            /usr/libexec/PlistBuddy -c "Print :persistent-apps" "$plist_file" &>/dev/null
                            if [ $? -ne 0 ]; then
                                echo "Adding persistent-apps array $plist_file"
                                /usr/libexec/PlistBuddy -c "Add :persistent-apps array" $plist_file
                            else
                                echo "Deleting persistent-apps array $plist_file"
                                /usr/libexec/PlistBuddy -c "Delete :persistent-apps" $plist_file
                                sleep 5
                                /usr/libexec/PlistBuddy -c "Add :persistent-apps array" $plist_file
                                sleep 5
                            fi

                            sleep 15
                            for app in "${items_to_pin[@]}"; do
                                if [[ -e $app ]]; then
                                    echo "| Processing $app |"
                                    sleep 5
                                    /usr/libexec/PlistBuddy -c "Add :persistent-apps:0 dict" -c "Add :persistent-apps:0:tile-data dict" -c "Add :persistent-apps:0:tile-data:file-data dict" -c "Add :persistent-apps:0:tile-data:file-data:_CFURLString string $app" -c "Add :persistent-apps:0:tile-data:file-data:_CFURLStringType integer 0" -c "Add :persistent-apps:0:tile-type string file-tile" "$plist_file"
                                fi
                            done
                        else 
                            echo "No plist for $dir_name!"
                        fi
                    fi
                fi
            done

            # Change Dock Icon Size
            echo "Changing Dock Icon Size..."
            sleep 5
            /usr/libexec/PlistBuddy -c "Set :tilesize 50" $plist_file

            # Restart Dock
            echo "Restarting Dock to Ensure Changes are Displayed..."
            sleep 5
            killall Dock

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
            echo "This script is only supported on macOS Big Sur"
        fi
    else
        echo "Script Already Ran!"  
    fi
fi