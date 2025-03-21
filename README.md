# Shell_Script_Automation
# This project involves automating user creation and SSH access configuration across multiple remote servers using a Bash script. The script provides two authentication options:

1. Password Authentication - Set a manual password for the automation user.

2. SSH Key-Based Authentication - Use public/private key pairs for secure authentication.

The script reads a list of servers from a file and executes commands on each server via SSH to create the user, configure SSH access, and grant sudo privileges.

 # How does it handle different authentication methods?

It prompts the user to choose password-based or SSH key-based authentication
