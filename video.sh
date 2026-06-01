#!/bin/bash

PROJECT_ID=$(gcloud config get-value project)

echo "Project: $PROJECT_ID"
echo

echo "Creating service account..."

gcloud iam service-accounts create quickstart \
    --display-name="quickstart" 2>/dev/null

echo "Creating service account key..."

gcloud iam service-accounts keys create key.json \
    --iam-account=quickstart@${PROJECT_ID}.iam.gserviceaccount.com

echo "Authenticating service account..."

gcloud auth activate-service-account \
    --key-file=key.json

TOKEN=$(gcloud auth print-access-token)

echo
echo "Access Token Generated"
echo

echo "Creating request.json..."

cat > request.json <<EOF
{
  "inputUri":"gs://spls/gsp154/video/train.mp4",
  "features":[
    "LABEL_DETECTION"
  ]
}
EOF

echo "Submitting Video Intelligence request..."

RESPONSE=$(curl -s \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${TOKEN}" \
  "https://videointelligence.googleapis.com/v1/videos:annotate" \
  -d @request.json)

echo
echo "Response:"
echo "$RESPONSE"
echo

OPERATION=$(echo "$RESPONSE" | sed -n 's/.*"name"[ ]*:[ ]*"\([^"]*\)".*/\1/p')

if [ -z "$OPERATION" ]; then
    echo "Failed to obtain operation name."
    exit 1
fi

echo "Operation:"
echo "$OPERATION"
echo

echo "Waiting 60 seconds for processing..."
sleep 60

echo
echo "Checking operation status..."
echo

curl -s \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${TOKEN}" \
  "https://videointelligence.googleapis.com/v1/${OPERATION}"

echo
echo
echo "Completed."
echo "Check My Progress for both tasks."