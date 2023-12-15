#!/bin/bash

# Update package lists
apt-get update

# Install Apache2
apt-get install -y apache2

# Check if Apache is installed before proceeding
if [ $? -eq 0 ]; then
    # Start and enable Apache service
    systemctl start apache2
    systemctl enable apache2

    # Download the existing index.html file from Azure Blob Storage
    wget -O /var/www/html/index.html 'https://tutorialccd.blob.core.windows.net/scripts/index.html'

else
    echo "Failed to install Apache. Exiting script."
    exit 1
fi