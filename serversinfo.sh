#!/bin/bash
SERVER_FILE="/home/automation/scripts/serverlist.txt"
if [ ! -f "$SERVER_FILE" ]; then
    echo "Error: $SERVER_FILE not found!"
    exit 1
fi

# Bootstrap credentials (used to connect to child servers)
BOOTSTRAP_USER="ec2-user"
BOOTSTRAP_KEY="/home/automation/.ssh/asha.nvirg.pem"
if [ ! -f "$BOOTSTRAP_KEY" ]; then
    echo "Error: Bootstrap private key $BOOTSTRAP_KEY not found!"
    exit 1
fi

echo "Choose authentication type for the automation user on child servers:"
echo "1) Password Authentication"
echo "2) SSH Key-Based Authentication"
read -p "Enter choice (1 or 2): " auth_type
if [[ "$auth_type" != "1" && "$auth_type" != "2" ]]; then
    echo "Invalid choice! Exiting."
    exit 1
fi

if [ "$auth_type" == "1" ]; then
    read -sp "Enter new password for the automation user on child servers: " user_password
    echo
elif [ "$auth_type" == "2" ]; then
    read -p "Enter path to the public key file: " key_file
    if [ ! -f "$key_file" ]; then
        echo "Error: Public key file not found!"
        exit 1
    fi
    pub_key=$(cat "$key_file")
fi

while IFS= read -r server || [ -n "$server" ]; do
    # Skip blank lines
    if [ -z "$server" ]; then
        continue
    fi
    echo "Processing child server: $server"
    
    # Create the automation user if it doesn't exist
    ssh -i "$BOOTSTRAP_KEY" ${BOOTSTRAP_USER}@"$server" "sudo id -u automation >/dev/null 2>&1 || sudo useradd -c 'automation user' -d /home/automation -m automation"
    
    # Set up sudo privileges for the automation user
    ssh -i "$BOOTSTRAP_KEY" ${BOOTSTRAP_USER}@"$server" "echo 'automation ALL=(ALL) NOPASSWD:ALL' | sudo tee /etc/sudoers.d/automation && sudo chmod 0440 /etc/sudoers.d/automation"
    
    # Create the .ssh directory and authorized_keys file for the automation user
    ssh -i "$BOOTSTRAP_KEY" ${BOOTSTRAP_USER}@"$server" "sudo mkdir -p /home/automation/.ssh && sudo touch /home/automation/.ssh/authorized_keys"
    
    # Change ownership of the .ssh directory to automation
    ssh -i "$BOOTSTRAP_KEY" ${BOOTSTRAP_USER}@"$server" "sudo chown -R automation:automation /home/automation/.ssh"
    
    if [ "$auth_type" == "1" ]; then
        # Set the password for the automation user
        ssh -i "$BOOTSTRAP_KEY" ${BOOTSTRAP_USER}@"$server" "echo 'automation:$user_password' | sudo chpasswd"
    elif [ "$auth_type" == "2" ]; then
        # Append the provided public key into the authorized_keys file for the automation user
        ssh -i "$BOOTSTRAP_KEY" ${BOOTSTRAP_USER}@"$server" "echo '$pub_key' | sudo tee -a /home/automation/.ssh/authorized_keys"
    fi
    
    # Set correct permissions for the .ssh directory and authorized_keys file
    ssh -i "$BOOTSTRAP_KEY" ${BOOTSTRAP_USER}@"$server" "sudo chmod 700 /home/automation/.ssh && sudo chmod 600 /home/automation/.ssh/authorized_keys"
    
    echo "Verifying connection as automation on $server:"
    ssh -i "$BOOTSTRAP_KEY" automation@"$server" "hostname -I"
    echo "Configuration completed on $server"
done < "$SERVER_FILE"
echo "Configuration on all child servers completed."

