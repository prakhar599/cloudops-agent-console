# CloudOps Async Agent System — Complete Setup Guide
## Waresmedia DevOps | Built with n8n + Azure Free Tier

---

## What you're building

3 async AI agents running on Azure (free tier), managed by n8n, with a live dashboard hosted on Azure Static Web Apps (free). Total cost: $0.

| Component            | Tool                    | Cost         |
|----------------------|-------------------------|--------------|
| Agent engine         | n8n on Azure VM B1s     | Free tier    |
| Event log storage    | Azure Blob Storage      | Free tier    |
| Dashboard hosting    | Azure Static Web Apps   | Free forever |
| Alerts trigger       | Azure Monitor webhook   | Free         |
| Slack notifications  | Slack incoming webhook  | Free         |

---

## PART 1 — Azure VM Setup (n8n engine)

### 1.1 Create the VM

1. Go to https://portal.azure.com
2. Click "Create a resource" → "Virtual Machine"
3. Use these EXACT settings:
   - **Resource group**: Create new → `waresmedia-devops`
   - **VM name**: `n8n-agent-server`
   - **Region**: Central India (or nearest to you)
   - **Image**: Ubuntu Server 22.04 LTS
   - **Size**: Standard_B1s (1 vcpu, 1 GiB) ← free tier
   - **Auth**: SSH public key
   - **Username**: `azureuser`
   - **Inbound ports**: Allow SSH (22)
4. Click "Review + Create" → "Create"
5. Download the SSH key when prompted — save it as `n8n-key.pem`

### 1.2 Open port 5678 for n8n

1. Go to your VM → "Networking" → "Add inbound port rule"
2. Destination port: `5678`
3. Protocol: TCP
4. Action: Allow
5. Name: `n8n-port`
6. Click Add

### 1.3 SSH in and install n8n

```bash
# From your local machine (replace with your VM public IP)
chmod 400 n8n-key.pem
ssh -i n8n-key.pem azureuser@YOUR_VM_PUBLIC_IP

# On the VM — run setup_n8n.sh (file provided separately)
# Or paste this directly:

sudo apt update && sudo apt upgrade -y
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs
sudo npm install -g n8n pm2
mkdir -p ~/.n8n

# Create env config (replace YOUR_VM_IP)
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

# Start n8n and keep it running
pm2 start n8n --name "n8n" -- start
pm2 startup   # copy and run the command it gives you
pm2 save
```

### 1.4 Verify n8n is running

Open in browser: `http://YOUR_VM_PUBLIC_IP:5678`

You should see the n8n login screen.
- Username: `admin`
- Password: `waresmedia2024`

---

## PART 2 — Azure Blob Storage Setup

### 2.1 Create storage account

1. Portal → "Create a resource" → "Storage account"
2. Settings:
   - **Resource group**: `waresmedia-devops`
   - **Name**: `waresmediaops` (must be globally unique — add numbers if taken)
   - **Region**: Same as VM
   - **Redundancy**: Locally-redundant storage (LRS)
3. Click "Review + Create" → "Create"

### 2.2 Create the container

1. Go to your storage account → "Containers" (left menu)
2. Click "+ Container"
3. Name: `agent-logs`
4. Access level: Private
5. Click Create

### 2.3 Enable CORS (so dashboard can read from browser)

1. Storage account → "Resource sharing (CORS)" (left menu)
2. Under "Blob service", click "+ Add"
3. Fill in:
   - Allowed origins: `*`
   - Allowed methods: GET, PUT, POST, DELETE, OPTIONS
   - Allowed headers: `*`
   - Exposed headers: `*`
   - Max age: `3600`
4. Click Save

### 2.4 Get SAS token for dashboard

1. Storage account → "Shared access signature" (left menu)
2. Allowed services: Blob ✓
3. Allowed resource types: Container ✓, Object ✓
4. Allowed permissions: Read ✓, Write ✓, List ✓
5. Set expiry to 1 year from today
6. Click "Generate SAS and connection string"
7. Copy the **SAS token** (starts with `?sv=`)

### 2.5 Get connection string for n8n

1. Storage account → "Access keys"
2. Click "Show keys"
3. Copy **Connection string** under key1

---

## PART 3 — Import n8n Workflows

### 3.1 Import Workflow 1 (CPU Alert Triage)

1. Open n8n at `http://YOUR_VM_IP:5678`
2. Click "+" to create new workflow → "..." menu → "Import from file"
3. Upload `workflow_1_cpu_triage.json`
4. After import:
   - Click the "Post to Slack" node → set your Slack webhook URL
   - Click the "Write to Azure Blob" node → update the URL with your storage account name
   - Click "Active" toggle to enable the workflow
5. Copy the webhook URL shown: `http://YOUR_VM_IP:5678/webhook/cpu-alert`

### 3.2 Import Workflow 2 (IaC Generation)

1. Import `workflow_2_iac_agent.json`
2. Update:
   - Both Slack nodes → your Slack webhook URL
   - "Write Approval to Blob" node → your storage account URL
   - "Create Approval Record" node → replace `YOUR_VM_IP` with actual IP
3. Enable the workflow

### 3.3 Import Workflow 3 (Nightly Cleanup)

1. Import `workflow_3_cleanup.json`
2. Update:
   - Both Slack nodes → your Slack webhook URL
   - "Write Report to Blob" node → your storage account URL
3. Enable the workflow

### 3.4 Get Slack Webhook URL (if you don't have one)

1. Go to https://api.slack.com/apps → "Create New App" → "From scratch"
2. Name: `CloudOps Bot`, choose your workspace
3. Click "Incoming Webhooks" → toggle On
4. Click "Add New Webhook to Workspace"
5. Choose `#cloud-ops` channel → Allow
6. Copy the webhook URL (starts with `https://hooks.slack.com/services/`)

---

## PART 4 — Deploy the Dashboard

### 4.1 Create a GitHub repo

1. Go to https://github.com/new
2. Name: `waresmedia-cloudops-dashboard`
3. Public or Private, your choice
4. Create repo
5. Upload these two files:
   - `index.html` (the dashboard)
   - `staticwebapp.config.json`

```bash
# Or from command line
git init waresmedia-cloudops-dashboard
cd waresmedia-cloudops-dashboard
cp /path/to/index.html .
cp /path/to/staticwebapp.config.json .
git add .
git commit -m "Initial dashboard"
git remote add origin https://github.com/YOUR_USERNAME/waresmedia-cloudops-dashboard.git
git push -u origin main
```

### 4.2 Deploy to Azure Static Web Apps (free)

1. Portal → "Create a resource" → "Static Web App"
2. Settings:
   - **Resource group**: `waresmedia-devops`
   - **Name**: `waresmedia-dashboard`
   - **Plan type**: Free
   - **Source**: GitHub
   - **GitHub account**: Sign in
   - **Organization**: your username
   - **Repository**: `waresmedia-cloudops-dashboard`
   - **Branch**: `main`
   - **Build preset**: Custom
   - **App location**: `/`
   - **Output location**: (leave blank)
3. Click "Review + Create" → "Create"

Azure will deploy automatically via GitHub Actions. In ~2 minutes your dashboard is live at:
`https://YOUR-DASHBOARD-NAME.azurestaticapps.net`

---

## PART 5 — Connect Everything

### 5.1 Configure the dashboard

1. Open your dashboard URL
2. The Settings modal will open automatically
3. Fill in:
   - **n8n base URL**: `http://YOUR_VM_IP:5678`
   - **Azure Blob URL**: `https://waresmediaops.blob.core.windows.net/agent-logs`
   - **SAS Token**: the `?sv=...` token from Part 2.4
   - **Slack Webhook**: optional
4. Click "Save & Connect"

### 5.2 Set up Azure Monitor alert → n8n

1. Portal → Monitor → "Alerts" → "Create alert rule"
2. Scope: your VM (`n8n-agent-server`)
3. Condition: "Percentage CPU" > 90% for 5 minutes
4. Action group: Create new
   - Action type: Webhook
   - URI: `http://YOUR_VM_IP:5678/webhook/cpu-alert`
   - Enable common alert schema: Yes
5. Alert rule name: `High CPU Auto-Triage`
6. Click Create

### 5.3 Test everything end-to-end

```bash
# Test CPU alert agent (from anywhere with curl)
curl -X POST http://YOUR_VM_IP:5678/webhook/cpu-alert \
  -H "Content-Type: application/json" \
  -d '{"serverName": "ad-srv-07", "cpuPercent": 94}'

# Test IaC agent
curl -X POST http://YOUR_VM_IP:5678/webhook/iac-request \
  -H "Content-Type: application/json" \
  -d '{"ticketId": "JIRA-482", "title": "New PostgreSQL DB for ad-analytics", "requestedBy": "prakhar"}'
```

Check:
- ✅ Slack `#cloud-ops` gets a message
- ✅ Azure Blob gets a new JSON file
- ✅ Dashboard shows the new activity

---

## PART 6 — Demo Script for the Interview

### What to say and show

**Opening (30 sec)**
> "So this is our async agent console. We have 3 agents running 24/7 on n8n, self-hosted on an Azure VM. They handle things in the background without me watching — I only get pinged for exceptions or approvals."

**Demo CPU agent (1 min)**
> "I'll trigger a CPU alert right now."

→ Click "Trigger Agent" → "Fire CPU Alert"

> "So this fires a webhook to n8n. The agent pulls logs from Azure, sees it's an OOM in the bidder service, decides it's safe to restart, restarts it, then posts this to Slack. That whole flow takes about 8 seconds. I'm not involved."

**Demo IaC agent (1 min)**
> "If someone files a ticket for new infrastructure, the IaC agent picks it up."

→ Click "Submit IaC Ticket"

> "It generates Terraform, runs a plan check, posts the result here as a pending approval. I review it and click Approve — then it applies and replies with the connection details."

→ Click Approve on the IaC page

**Demo Cleanup agent (30 sec)**
> "Every night at 2am, the cleanup agent scans for unused Azure resources."

→ Show the Cleanup page table

> "Last night it found 9 resources costing us $340 a month. It sends the list to Slack, waits 24 hours, then auto-deletes unless someone objects. We save money without anyone having to manually audit resources."

**Architecture question (ready answer)**
> "The stack is: n8n for orchestration, Azure Monitor for alert triggers, Azure Blob for storing all event logs, and this dashboard reads from Blob via SAS token. Everything on Azure free tier — the VM is B1s, Static Web Apps is free forever."

---

## Quick reference — Webhook URLs

| Agent | URL |
|-------|-----|
| CPU Alert | `http://YOUR_VM_IP:5678/webhook/cpu-alert` |
| IaC Request | `http://YOUR_VM_IP:5678/webhook/iac-request` |
| IaC Approve | `http://YOUR_VM_IP:5678/webhook/approve-iac` |
| IaC Reject | `http://YOUR_VM_IP:5678/webhook/reject-iac` |
| Cleanup (manual) | `http://YOUR_VM_IP:5678/webhook/cleanup-now` |
