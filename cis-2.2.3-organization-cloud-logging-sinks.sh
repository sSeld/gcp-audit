#!/bin/bash

source helpers.inc

declare ORGANIZATION_IDS=$(gcloud organizations list --format="flattened(ID)" | grep id | cut -d " " -f 2 | cut -d "/" -f 2)

for ORGANIZATION_ID in $ORGANIZATION_IDS; do
    if ! api_enabled logging.googleapis.com; then
        echo "Logging API is not enabled on Organization $ORGANIZATION_ID"
        continue
    fi
	echo "IAM Policy for Organization $ORGANIZATION_IDS"
	echo ""
	gcloud logging sinks list --organization=$ORGANIZATION_ID;
	echo ""
done;
