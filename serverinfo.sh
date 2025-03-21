#!/bin/bash

echo "Select the Option (1 or 2):"
echo "1) Password Authentication"
echo "2) SSH Key-Based Authentication"
read -p "Choice is: " auth_type

if [ "$auth_type" == "1" ]; then
    read -sp "Enter password for the 'automation' user: " user_password
    echo ""
elif [ "$auth_type" == "2" ]; then
    read -p "Enter path to your public key file (/home/automation/.ssh/asha.nvirg.pem.pub): " key_file
    if [ ! -f "$key_file" ]; then
        echo "Public key file not found!"
        exit 1
    fi
    pub_key=$(cat "$key_file")
else
    echo "Invalid option!"
    exit 1
fi

SERVERS=(server1 server2 server3)


BOOTSTRAP_USER="ec2-user"
BOOTSTRAP_KEY="/home/automation/.ssh/asha.nvirg.pem"

if [ ! -f "$BOOTSTRAP_KEY" ]; then
    echo "Bootstrap private key not found!"
    exit 1
fi

for server in "${SERVERS[@]}"; do
   
    echo "Setting up $server..."
    ssh -i "$BOOTSTRAP_KEY" "$BOOTSTRAP_USER@$server" "sudo useradd -c 'automation user' -d /home/automation -m automation"

   # permissions
    ssh -i "$BOOTSTRAP_KEY" "$BOOTSTRAP_USER@$server" "
      sudo mkdir -p /home/automation/.ssh && \
      sudo touch /home/automation/.ssh/authorized_keys && \
      sudo chown -R automation:automation /home/automation/.ssh && \
      sudo chmod 700 /home/automation/.ssh && \
      sudo chmod 600 /home/automation/.ssh/authorized_keys
    "

    ssh -i "$BOOTSTRAP_KEY" "$BOOTSTRAP_USER@$server" "echo 'automation ALL=(ALL) NOPASSWD:ALL' | sudo tee /etc/sudoers.d/automation && sudo chmod 0440 /etc/sudoers.d/automation"

    if [ "$auth_type" == "1" ]; then
        ssh -i "$BOOTSTRAP_KEY" "$BOOTSTRAP_USER@$server" "echo 'automation:$user_password' | sudo chpasswd"
    else
        ssh -i "$BOOTSTRAP_KEY" "$BOOTSTRAP_USER@$server" "echo '$pub_key' | sudo tee -a /home/automation/.ssh/authorized_keys"
    fi

    echo "Verifying connection to automation user on $server..."
    if ssh -i "$BOOTSTRAP_KEY" automation@"$server" "hostname -I" >/dev/null 2>&1; then
        echo " Successfully connected to $server"
    else
        echo " Failed to connect to $server"
    fi

    echo "Configuration completed on $server."
done


