#!/bin/bash

# Check if dialog is installed and install if not
check_install_dialog() {
    if ! command -v dialog &> /dev/null; then
        echo "Installing Dialog. Please wait..."
        apt-get install dialog -y > /dev/null 2>&1
        if [ $? -ne 0 ]; then
            echo "Failed to install Dialog. Please install it manually." >&2
            exit 1
        fi
    fi
}

check_install_dialog

# Function to generate SSH key and update authorized_keys
generate_key() {
    local user_home=$(getent passwd "$1" | cut -d: -f6)
    local ssh_dir="$user_home/.ssh"
    local auth_keys="$ssh_dir/authorized_keys"

    # Create .ssh directory if it doesn't exist
    mkdir -p "$ssh_dir"
    chmod 700 "$ssh_dir"
    chown "$1":"$1" "$ssh_dir"

    # Ask for the comment to include in the key
    local comment
    comment=$(dialog --inputbox "Enter a User who this SSH key is for:" 10 50 3>&1 1>&2 2>&3 3>&-)

    # Generate the SSH key with the comment in the filename
    local key_path="$ssh_dir/id_ed25519_$comment"
    ssh-keygen -t ed25519 -f "$key_path" -N "" -C "$comment" < /dev/null
    if [ $? -eq 0 ]; then
        chown "$1":"$1" "$key_path" "$key_path.pub"

        # Add the public key with the comment to authorized_keys
        cat "$key_path.pub" >> "$auth_keys"
        chmod 600 "$auth_keys"
        chown "$1":"$1" "$auth_keys"

        # Inform the user about the key location
        dialog --title "SSH Key Generated" --msgbox "SSH keys have been generated for $1.\n\nPrivate Key: $key_path\nPublic Key: ${key_path}.pub\n" 10 50
    else
        dialog --title "Error" --msgbox "SSH key generation failed." 5 50
    fi
}

# Function to delete an SSH key
delete_key() {
    local user_home=$(getent passwd "$1" | cut -d: -f6)
    local ssh_dir="$user_home/.ssh"
    local auth_keys="$ssh_dir/authorized_keys"

    # Extract User from the authorized_keys file
    if [ -f "$auth_keys" ]; then
        local User
        User=$(awk '{print $NF}' "$auth_keys" | nl -w2 -s' ')

        if [ -z "$User" ]; then
            dialog --title "Delete SSH Key" --msgbox "No SSH keys found to delete." 5 50
            return
        fi

        # Present the User in a menu for selection
        local comment_choice
        comment_choice=$(dialog --menu "Select the SSH key to delete:" 20 60 10 $User 3>&1 1>&2 2>&3 3>&-)

        if [ -n "$comment_choice" ]; then
            local selected_comment
            selected_comment=$(echo "$User" | awk -v choice="$comment_choice" '$1 == choice { $1=""; print $0 }' | xargs)

            # Find and remove the corresponding public key entry from authorized_keys
            local key_line
            key_line=$(grep -n "$selected_comment" "$auth_keys" | cut -d: -f1)
            if [ -n "$key_line" ]; then
                sed -i "${key_line}d" "$auth_keys"
                local key_path="$ssh_dir/id_ed25519_$selected_comment"
                rm -f "$key_path" "$key_path.pub"
                dialog --title "Delete SSH Key" --msgbox "SSH key with comment '$selected_comment' deleted successfully." 5 50
            else
                dialog --title "Error" --msgbox "Failed to delete SSH key. Key not found." 5 50
            fi
        else
            dialog --title "Delete SSH Key" --msgbox "No SSH key selected for deletion." 5 50
        fi
    else
        dialog --title "Delete SSH Key" --msgbox "No SSH keys found to delete." 5 50
    fi
}

# Function to view SSH keys
view_keys() {
    local user_home=$(getent passwd "$1" | cut -d: -f6)
    local ssh_dir="$user_home/.ssh"
    local auth_keys="$ssh_dir/authorized_keys"

    # Extract User from the authorized_keys file
    if [ -f "$auth_keys" ]; then
        local User
        User=$(awk '{print $NF}' "$auth_keys" | nl -w2 -s' ')

        if [ -z "$User" ]; then
            dialog --title "View SSH Keys" --msgbox "No SSH keys found to view." 5 50
            return
        fi

        # Present the User in a menu for selection
        local comment_choice
        comment_choice=$(dialog --menu "Select the SSH key to view:" 20 60 10 $User 3>&1 1>&2 2>&3 3>&-)

        if [ -n "$comment_choice" ]; then
            local selected_comment
            selected_comment=$(echo "$User" | awk -v choice="$comment_choice" '$1 == choice { $1=""; print $0 }' | xargs)

            local key_path="$ssh_dir/id_ed25519_$selected_comment"
            local key_pub_path="$key_path.pub"

            if [ -f "$key_path" ] && [ -f "$key_pub_path" ]; then
                local key_content=$(cat "$key_path")
                local key_pub_content=$(cat "$key_pub_path")
                dialog --title "Private Key" --msgbox "$key_content" 22 80
                dialog --title "Public Key" --msgbox "$key_pub_content" 22 80
            else
                dialog --title "View SSH Keys" --msgbox "SSH key files not found." 5 50
            fi
        else
            dialog --title "View SSH Keys" --msgbox "No SSH key selected for viewing." 5 50
        fi
    else
        dialog --title "View SSH Keys" --msgbox "No SSH keys found to view." 5 50
    fi
}

# Function to restore public key from private
restore_public_key() {
    local user_home=$(getent passwd "$1" | cut -d: -f6)
    local ssh_dir="$user_home/.ssh"
    local auth_keys="$ssh_dir/authorized_keys"

    # Extract User from the authorized_keys file
    if [ -f "$auth_keys" ]; then
        local User
        User=$(awk '{print $NF}' "$auth_keys" | nl -w2 -s' ')

        if [ -z "$User" ]; then
            dialog --title "Restore Public Key" --msgbox "No private key files found to restore from." 5 50
            return
        fi

        # Present the User in a menu for selection
        local comment_choice
        comment_choice=$(dialog --menu "Select the SSH key to restore:" 20 60 10 $User 3>&1 1>&2 2>&3 3>&-)

        if [ -n "$comment_choice" ]; then
            local selected_comment
            selected_comment=$(echo "$User" | awk -v choice="$comment_choice" '$1 == choice { $1=""; print $0 }' | xargs)

            local key_path="$ssh_dir/id_ed25519_$selected_comment"

            if [ -f "$key_path" ]; then
                ssh-keygen -y -f "$key_path" > "$key_path.pub"
                dialog --title "Restore Public Key" --msgbox "Public key restored from private key." 5 50
            else
                dialog --title "Restore Public Key" --msgbox "Private key file not found." 5 50
            fi
        else
            dialog --title "Restore Public Key" --msgbox "No SSH key selected for restoration." 5 50
        fi
    else
        dialog --title "Restore Public Key" --msgbox "No private key files found to restore from." 5 50
    fi
}

# Function to handle user action
handle_action() {
    while true; do
        action=$(dialog --title "SSH Key Management" --cancel-label "Exit" --menu "Choose action for $user:" 15 70 6 \
            1 "Generate SSH Key" \
            2 "Delete SSH Key" \
            3 "View SSH Keys" \
            4 "Restore Public Key from Private" \
            5 "Change User" \
            3>&1 1>&2 2>&3)

        case $action in
            1) generate_key "$user" ;;
            2) delete_key "$user" ;;
            3) view_keys "$user" ;;
            4) restore_public_key "$user" ;;
            5) return ;;  # Go back to user selection
            "") clear; exit 0 ;;  # Exit on cancel or ESC
            *) dialog --title "Invalid Option" --msgbox "Please select a valid option." 5 50 ;;
        esac
    done
}

# User selection menu
choose_user() {
    if [ $(id -u) -eq 0 ]; then
        # Root user, show all system users except 'nobody' and those containing 'libvirt'
        exec 3>&1
        user=$(dialog --title "Select User" --cancel-label "Exit" --menu "Choose a user:" 20 60 10 \
            $(getent passwd | awk -F: '$3 >= 1000 && $3 <= 1999 && $1 != "nobody" && $1 !~ /libvirt/ {print $1 " " $1}') 2>&1 1>&3)
        exec 3>&-
    else
        # Regular user, only their username
        user="$USER"
    fi
}

# Main action loop
while true; do
    choose_user

    if [ -n "$user" ]; then
        handle_action
    else
        dialog --title "Error" --msgbox "No user selected or operation cancelled." 5 50
        clear
        exit 1
    fi
done

# Clear up the dialog artifacts
clear