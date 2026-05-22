#!/bin/bash
# Run this on your Azure VM after SSH in
# ssh azureuser@YOUR_VM_IP

# Update and install Node + npm
sudo apt update && sudo apt upgrade -y
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# Install n8n globally
sudo npm install -g n8n

# Install PM2 to keep n8n alive after you close SSH
sudo npm install -g pm2

# Create n8n config directory
mkdir -p ~/.n8n

# Create environment file for n8n
cat > ~/.n8n/.env << 'EOF'
N8N_HOST=0.0.0.0
N8N_PORT=5678
N8N_PROTOCOL=http
N8N_BASIC_AUTH_ACTIVE=true
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=waresmedia2024
WEBHOOK_URL=http://YOUR_VM_IP:5678/
N8N_LOG_LEVEL=info
EXECUTIONS_DATA_SAVE_ON_SUCCESS=all
EXECUTIONS_DATA_SAVE_ON_ERROR=all
EOF

echo "Edit the .env file: nano ~/.n8n/.env"
echo "Replace YOUR_VM_IP with your actual Azure VM public IP"

# Start n8n with PM2 so it runs forever
pm2 start n8n --name "n8n" -- start
pm2 startup
pm2 save

echo ""
echo "=== n8n is running ==="
echo "Open in browser: http://YOUR_VM_IP:5678"
echo "Login: admin / waresmedia2024"
echo ""
echo "Next: open port 5678 in Azure portal:"
echo "  VM > Networking > Add inbound port rule > Port 5678"
