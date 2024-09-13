#!/bin/bash

# Get OS Version
OS_MAJOR_VER=$(sw_vers -productVersion | awk -F'.' '{print $1}')

ROOT_PATH="/var/folders"
CONFIG_FILE="/var/root/.DIT/DIT.cfg"
TARGET_KEY="Desktop"
REPLACEMENT_VALUE="true"

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

if [ -e "$CONFIG_FILE" ]; then
    echo "$CONFIG_FILE Found!" 
    echo ""
    CURRENT_VALUE=$(echo "$FILE_CONTENT" | grep "^$TARGET_KEY = " | sed "s/^$TARGET_KEY = //")
    if [ "$CURRENT_VALUE" = "false" ]; then
        if [[ $OS_MAJOR_VER == "11" ]]; then

            # Install Pip
            PYTHON_VER=$(python -V 2>&1)
            PYTHON_VER=${PYTHON_VER#Python }
            MAJOR_MINOR_VER=$(awk -F'.' '{print $1"."$2}' <<< "$PYTHON_VER")
            MAJOR_VER=$(awk -F'.' '{print $1}' <<< "$PYTHON_VER")

            if [[ $MAJOR_VER == "3" ]]; then
                
                echo "Informational] Installing PIP 3"
                curl https://bootstrap.pypa.io/get-pip.py | python
                PIP_PATH=$(which pip3)
                $PIP_PATH install pillow
            fi
            
            if [[ $MAJOR_VER == "2" ]]; then
                echo "Informational] Installing PIP $MAJOR_MINOR_VER"
                curl  https://bootstrap.pypa.io/pip/$MAJOR_MINOR_VER/get-pip.py | python
                PIP_PATH=$(which pip)
                $PIP_PATH install pillow
            fi

            if dscl . -read /Groups/admin GroupMembership | grep -qw "$(whoami)"; then
                echo "User is a Local Administrator, Generating Background Image..."

                # Generate Background Image
                IMG_PATH="$ROOT_PATH/Orange.png"
                echo $IMG_PATH

                # Define the output file path
                OUTPUT_FILE="$ROOT_PATH/temp.py"

                # Write the Python script to the file using echo
                echo "from PIL import Image" > "$OUTPUT_FILE"
                echo "import os" >> "$OUTPUT_FILE"
                echo "width, height = 1920, 1080" >> "$OUTPUT_FILE"
                echo "color = (255, 165, 0)  # Orange color in RGB" >> "$OUTPUT_FILE"
                echo "image = Image.new('RGB', (width, height), color)" >> "$OUTPUT_FILE"
                echo "image.save('$IMG_PATH')" >> "$OUTPUT_FILE"

                if [[ $MAJOR_VER == "2" ]]; then
                    echo ""
                    python "$OUTPUT_FILE"
                    rm "$OUTPUT_FILE"
                fi

                if [[ $MAJOR_VER == "3" ]]; then
                    echo ""
                    python3 "$OUTPUT_FILE"
                    rm "$OUTPUT_FILE"
                fi

                # Set Desktop Background
                echo "Setting Background..."
                osascript -e "tell application \"System Events\" to set picture of every desktop to POSIX file \"$IMG_PATH\""
                
                # Hide the desktop background image
                echo "Hiding Background Image File..."
                chflags hidden "$IMG_PATH"

                echo "Updating Runflags..."
                MODIFIED_CONTENT=$(echo "$FILE_CONTENT" | awk -v key="$TARGET_KEY" -v value="$REPLACEMENT_VALUE" '
                BEGIN { FS = OFS = " = " }
                $1 == key { $2 = value }
                { print }
                ')
                echo "$MODIFIED_CONTENT" > "$CONFIG_FILE"
                echo "Successful."
            else 
                echo 'User not a local administrator!'; 
            fi
        else
            echo "This script is only supported on MacOS Big Sur" 
        fi
    else
        echo "Script Already Ran!"
    fi
fi