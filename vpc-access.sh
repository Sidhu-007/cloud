#!/bin/bash

echo "Google Cloud Lab Automation"
echo

# INPUT
read -p "Enter your ZONE (example: us-central1-a): " ZONE

REGION=${ZONE%-*}
echo "Region: $REGION"

PROJECT_ID=$(gcloud config get-value project)
echo "Project ID: $PROJECT_ID"
echo

# STARTUP SCRIPTS
cat << 'EOF' > blue-startup.sh
#!/bin/bash
apt-get update
apt-get install nginx-light -y
echo "<h1>Blue Server Ready!</h1>" > /var/www/html/index.nginx-debian.html
EOF

cat << 'EOF' > green-startup.sh
#!/bin/bash
apt-get update
apt-get install nginx-light -y
echo "<h1>Green Server Ready!</h1>" > /var/www/html/index.nginx-debian.html
EOF

# CREATE INSTANCES
echo "Creating blue instance..."
gcloud compute instances create blue \
    --zone=$ZONE \
    --machine-type=e2-micro \
    --tags=web-server \
    --metadata-from-file=startup-script=blue-startup.sh

echo "Creating green instance..."
gcloud compute instances create green \
    --zone=$ZONE \
    --machine-type=e2-micro \
    --metadata-from-file=startup-script=green-startup.sh

# FIREWALL
echo "Creating firewall rule..."
gcloud compute firewall-rules create allow-http-web-server \
    --network=default \
    --action=allow \
    --direction=ingress \
    --rules=tcp:80,icmp \
    --source-ranges=0.0.0.0/0 \
    --target-tags=web-server

# TEST VM
echo "Creating test VM..."
gcloud compute instances create test-vm \
    --zone=$ZONE \
    --machine-type=e2-micro

# SERVICE ACCOUNT
echo "Creating service account..."
gcloud iam service-accounts create Network-admin \
    --display-name="Network-admin"

SA_EMAIL="Network-admin@${PROJECT_ID}.iam.gserviceaccount.com"

echo "Assigning Network Admin role..."
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:${SA_EMAIL}" \
    --role="roles/compute.networkAdmin" > /dev/null 2>&1

echo "Creating credentials.json..."
gcloud iam service-accounts keys create credentials.json \
    --iam-account=${SA_EMAIL}

echo
echo "ACTION REQUIRED"
echo "Click 'Check my progress' in the lab."
read -p "Press ENTER after completing the checkpoints..."

# ROLE SWITCH
echo "Switching roles..."

gcloud projects remove-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:${SA_EMAIL}" \
    --role="roles/compute.networkAdmin" > /dev/null 2>&1

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:${SA_EMAIL}" \
    --role="roles/compute.securityAdmin" > /dev/null 2>&1

sleep 10

# CLEANUP
echo "Deleting firewall rule..."
gcloud compute firewall-rules delete allow-http-web-server --quiet

rm -f blue-startup.sh green-startup.sh

echo
echo "Lab completed successfully."