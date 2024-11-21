#!/bin/zsh
# TODO: Complete the script

# Define the user details
USERNAME="$1"
FULLNAME="$2"
PASSWORD="$3"

# Calculate UID and GID
UID=$(dscl . -list /Users UniqueID | awk '{print $2}' | sort -n | tail -1 | awk '{print $1+1}')
GID=$(dscl . -list /Groups PrimaryGroupID | awk '{print $2}' | sort -n | tail -1 | awk '{print $1+1}')

# Check for spaces in username and full name
if [[ "$USERNAME" == *" "* ]]; then
    echo "$USERNAME contains a space!"
    exit 1
fi

if [[ "$FULLNAME" == *" "* ]]; then
    echo "$FULLNAME contains a space!"
    exit 1
fi

# Create the user
sysadminctl -addUser "$USERNAME" -fullName "$FULLNAME" -password "$PASSWORD"
if [ $? -ne 0 ]; then
    echo "Failed to create user $USERNAME."
    exit 1
fi

# Set home directory
dscl . -create /Users/"$USERNAME" NFSHomeDirectory /Users/"$USERNAME"

# Set the user UID and GID
dscl . -create /Users/"$USERNAME" UniqueID "$UID"
dscl . -create /Users/"$USERNAME" PrimaryGroupID "$GID"

# Create the home directory
createhomedir -c -u "$USERNAME"
if [ $? -ne 0 ]; then
    echo "Failed to create home directory for $USERNAME."
    exit 1
fi

# Enable the user as a mobile account (if needed)
# Uncomment and modify if using Active Directory
# dscl . -create /Users/"$USERNAME" OriginalNodeName "/Active Directory/<DOMAIN>"
# dscl . -append /Users/"$USERNAME" AuthenticationAuthority ";LocalCachedUser;/Active Directory/<DOMAIN>"

# Optional network sync
# sudo mcxrefresh -n "$USERNAME"

echo "User $USERNAME created and configured."
