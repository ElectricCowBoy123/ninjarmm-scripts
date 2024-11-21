#!/bin/zsh

# Install Application
echo "Downloading $appName from $appURL..."
curl -L -o "/Applications/$appName.app" "$appURL"

# Check if the curl command succeeded
if [ $? -ne 0 ]; then
    echo "Failed to download $appName from $appURL."
    exit 1
fi

echo "$appName has been downloaded and saved to /Applications/"