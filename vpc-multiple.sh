#!/bin/bash

echo "Google Cloud Networking Lab Setup"
echo

# ENVIRONMENT SETUP
echo "Step 1: Configuring Network Environment"

export INSTANCE_ZONE_1=$(gcloud compute instances list --filter="name:mynet-vm-1" --format="value(zone)")
export INSTANCE_ZONE_2=$(gcloud compute instances list --filter="name:mynet-vm-2" --format="value(zone)")

export REGION_1=${INSTANCE_ZONE_1%-*}
export REGION_2=${INSTANCE_ZONE_2%-*}

echo "Zone 1: $INSTANCE_ZONE_1 (Region: $REGION_1)"
echo "Zone 2: $INSTANCE_ZONE_2 (Region: $REGION_2)"
echo

# NETWORK CREATION
echo "Step 2: Creating Networks and Subnets"

gcloud compute networks create managementnet --subnet-mode=custom || exit 1

gcloud compute networks subnets create managementsubnet-1 \
    --network=managementnet \
    --region=$REGION_1 \
    --range=10.130.0.0/20 || exit 1

gcloud compute networks create privatenet --subnet-mode=custom || exit 1

gcloud compute networks subnets create privatesubnet-1 \
    --network=privatenet \
    --region=$REGION_1 \
    --range=172.16.0.0/24 || exit 1

gcloud compute networks subnets create privatesubnet-2 \
    --network=privatenet \
    --region=$REGION_2 \
    --range=172.20.0.0/20 || exit 1

echo "Networks and subnets created successfully."
echo

# FIREWALL RULES
echo "Step 3: Configuring Firewall Rules"

gcloud compute firewall-rules create managementnet-allow-icmp-ssh-rdp \
    --direction=INGRESS \
    --priority=1000 \
    --network=managementnet \
    --action=ALLOW \
    --rules=icmp,tcp:22,tcp:3389 \
    --source-ranges=0.0.0.0/0 || exit 1

gcloud compute firewall-rules create privatenet-allow-icmp-ssh-rdp \
    --direction=INGRESS \
    --priority=1000 \
    --network=privatenet \
    --action=ALLOW \
    --rules=icmp,tcp:22,tcp:3389 \
    --source-ranges=0.0.0.0/0 || exit 1

echo "Firewall rules configured successfully."
echo

# INSTANCE DEPLOYMENT
echo "Step 4: Deploying Compute Instances"

gcloud compute instances create managementnet-vm-1 \
    --zone=$INSTANCE_ZONE_1 \
    --machine-type=e2-micro \
    --subnet=managementsubnet-1 || exit 1

gcloud compute instances create privatenet-vm-1 \
    --zone=$INSTANCE_ZONE_1 \
    --machine-type=e2-micro \
    --subnet=privatesubnet-1 || exit 1

gcloud compute instances create vm-appliance \
    --zone=$INSTANCE_ZONE_1 \
    --machine-type=e2-standard-4 \
    --network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY,subnet=privatesubnet-1 \
    --network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY,subnet=managementsubnet-1 \
    --network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY,subnet=mynetwork || exit 1

echo "All instances deployed successfully."
echo
echo "Lab completed successfully."