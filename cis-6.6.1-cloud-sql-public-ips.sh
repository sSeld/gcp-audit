#!/bin/bash

LONG=project:
SHORT=p:
OPTS=$(getopt -a -n testscript --options $SHORT --longoptions $LONG -- "$@")

eval set -- "$OPTS"
while :
do
    case "$1" in --project | -p )
        declare PROJECT_IDS="$2"
        shift 2
     ;;
     -- )
        shift;
        break
        ;;
        *)
        exit 2
    esac
done;

if [[ $PROJECT_IDS == "" ]]; then
    declare PROJECT_IDS=$(gcloud projects list --format="flattened(PROJECT_ID)" | grep project_id | cut -d " " -f 2);
fi;

for PROJECT_ID in $PROJECT_IDS; do	
	gcloud config set project $PROJECT_ID;
	declare INSTANCES=$(gcloud sql instances list --quiet --format="json");

	DATABASE_NAME=$(echo $INSTANCES | jq '.[]' | jq '.name');	
	DATABASE_VERSION=$(echo $INSTANCES | jq '.[]' | jq '.databaseVersion');
	EXTERNAL_IP=$(echo $INSTANCES | jq '.[]' | jq '.ipAddresses[]' | jq 'select(.type == "PRIMARY")' | jq '.ipAddress');
	
	if [[ $DATABASE_NAME != "" ]]; then
	
		PROJECT_DETAILS=$(gcloud projects describe $PROJECT_ID --format="json");
		PROJECT_NAME=$(echo $PROJECT_DETAILS | jq -rc '.name');
		PROJECT_APPLICATION=$(echo $PROJECT_DETAILS | jq -rc '.labels.app');
		PROJECT_OWNER=$(echo $PROJECT_DETAILS | jq -rc '.labels.adid');
		
		echo "Project Name: $PROJECT_NAME";
		echo "Project Application: $PROJECT_APPLICATION";
		echo "Project Owner: $PROJECT_OWNER";
		echo "Cloud SQL Instance $DATABASE_NAME";
		echo "Version: $DATABASE_VERSION";
		if [[ $EXTERNAL_IP != "" ]]; then
			echo "External IP Addresses: $EXTERNAL_IP";
		else
			echo "No external IP found";
		fi
		echo "";
		sleep 0.5;
	else
		echo "Project $PROJECT_ID: No Cloud SQL found";
	fi
done;
