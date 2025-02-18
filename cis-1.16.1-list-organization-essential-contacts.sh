#!/bin/bash

source helpers.inc

declare ORGANIZATION_IDS=$(gcloud organizations list --format="flattened(ID)" | grep id | cut -d " " -f 2 | cut -d "/" -f 2)

for ORGANIZATION_ID in $ORGANIZATION_IDS; do
	if ! api_enabled essentialcontacts.googleapis.com; then
		echo "Essential Contacts API is not enabled for Organization $ORGANIZATION_ID"
		continue
	fi

	echo "Essential Contacts for Organization $ORGANIZATION_IDS"
	echo ""
	gcloud essential-contacts list --organization=$ORGANIZATION_ID;
	echo ""
done;
