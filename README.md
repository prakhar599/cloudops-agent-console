Agent Trigger APIs

- CPU Alert Agent

Endpoint
POST https://n8ncloudops.duckdns.org/webhook/cpu-alert

cURL
curl -X POST https://n8ncloudops.duckdns.org/webhook/cpu-alert \
-H "Content-Type: application/json" \
-d '{
  "serverName": "ad-srv-07",
  "cpuPercent": 94
}'


- IaC Provisioning Agent

Endpoint
POST https://n8ncloudops.duckdns.org/webhook/iac-agent

cURL
curl -X POST https://n8ncloudops.duckdns.org/webhook/iac-request \
-H "Content-Type: application/json" \
-d '{
  "environment": "production",
  "resourceType": "virtual-machine",
  "region": "centralindia"
}'

- Cleanup Agent

Endpoint
POST https://n8ncloudops.duckdns.org/webhook/cleanup-agent

cURL
curl -X POST https://n8ncloudops.duckdns.org/webhook/cleanup-agent \
-H "Content-Type: application/json" \
-d '{
  "resourceGroup": "legacy-rg",
  "cleanupMode": "unused-resources"
}'
