#!/bin/bash

source helpers.inc

declare ORGANIZATIONAL_IDS=$(gcloud organizations list --format="flattened(ID)" | grep id | cut -d " " -f 2 | cut -d "/" -f 2)

for ORGANIZATION_ID in $ORGANIZATIONAL_IDS; do
	echo "Working on Organizational ID $ORGANIZATION_ID"
	declare FOLDER_IDS=$(gcloud resource-manager folders list --organization $ORGANIZATION_ID)

	for FOLDER_ID in $FOLDER_IDS; do
    	if ! api_enabled logging.googleapis.com; then
    	    echo "Logging API is not enabled on Folder $FOLDER_ID for Organization $ORGANIZATION_ID"
    	    continue
    	fi

		echo "Working on Folder $FOLDER_ID"
		echo ""
		gcloud logging sinks list --folder=$FOLDER_ID;
		echo ""
	done;
done;
