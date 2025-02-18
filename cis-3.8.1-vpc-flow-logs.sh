#!/bin/bash

source helpers.inc

PROJECT_IDS="";
DEBUG="False";
HELP=$(cat << EOL
	$0 [-p, --project PROJECT] [-d, --debug] [-h, --help]	
EOL
);

for arg in "$@"; do
  shift
  case "$arg" in
    "--help") 		set -- "$@" "-h" ;;
    "--debug") 		set -- "$@" "-d" ;;
    "--project")   	set -- "$@" "-p" ;;
    *)        		set -- "$@" "$arg"
  esac
done

while getopts "hdp:" option
do 
    case "${option}"
        in
        p)
        	PROJECT_IDS=${OPTARG};;
        d)
        	DEBUG="True";;
        h)
        	echo $HELP; 
        	exit 0;;
    esac;
done;

if [[ $PROJECT_IDS == "" ]]; then
    declare PROJECT_IDS=$(gcloud projects list --format="flattened(PROJECT_ID)" | grep project_id | cut -d " " -f 2);
fi;

for PROJECT_ID in $PROJECT_IDS; do
	if ! api_enabled compute.googleapis.com; then
		echo "Compute Engine API is not enabled on Project $PROJECT_ID"
		continue
	fi

	gcloud config set project $PROJECT_ID 2>/dev/null;

	declare SUBNETS=$(gcloud compute networks subnets list --format json);
	
	echo "---------------------------------------------------------------------------------";
	echo "Subnets for Project $PROJECT_ID";
	echo "---------------------------------------------------------------------------------";

	if [[ $SUBNETS != "[]" ]]; then

		PROJECT_DETAILS=$(gcloud projects describe $PROJECT_ID --format="json");
		PROJECT_NAME=$(echo $PROJECT_DETAILS | jq -rc '.name');
		PROJECT_APPLICATION=$(echo $PROJECT_DETAILS | jq -rc '.labels.app');
		PROJECT_OWNER=$(echo $PROJECT_DETAILS | jq -rc '.labels.adid');
	
		echo $SUBNETS | jq -rc '.[]' | while IFS='' read -r SUBNET;do
			
			SUBNET_NAME=$(echo $SUBNET | jq -rc '.name');
			IP_RANGE=$(echo $SUBNET | jq -rc '.ipCidrRange');
			FLOW_LOGS_CONFIGURED=$(echo $SUBNET | jq -rc '.logConfig');

			echo "Project Name: $PROJECT_NAME";
			echo "Project Application: $PROJECT_APPLICATION";
			echo "Project Owner: $PROJECT_OWNER";			
			echo "Subnet: $SUBNET_NAME";
			echo "IP Range: $IP_RANGE";
			
			if [[ $FLOW_LOGS_CONFIGURED != "null" ]]; then
			
				FLOW_LOGS_ENABLED=$(echo $SUBNET | jq -rc '.enableFlowLogs');
				FLOW_LOG_AGGREGATION_INTERVAL=$(echo $SUBNET | jq -rc '.logConfig.aggregationInterval');
				FLOW_LOG_SAMPLE_RATE=$(echo $SUBNET | jq -rc '.logConfig.flowSampling');
				FLOW_LOG_METADATA_CONFIGURATION=$(echo $SUBNET | jq -rc '.logConfig.metadata');
				
				# Returns 0 for FALSE and 1 for TRUE
				FLOW_LOG_SAMPLE_RATE_TOO_LOW=$(echo "$FLOW_LOG_SAMPLE_RATE < 0.10" | bc);
					
				echo "Flow Log Enabled: $FLOW_LOGS_ENABLED";
				echo "Flow Log Aggregation Interval: $FLOW_LOG_AGGREGATION_INTERVAL";
				echo "Flow Log Sample Rate: $FLOW_LOG_SAMPLE_RATE";
				echo "Flow Log Metadata Configuration: $FLOW_LOG_METADATA_CONFIGURATION";
				if [[ $FLOW_LOGS_ENABLED == "false" ]]; then
					echo "VIOLATION: Flow logging is configured but not enabled";
				fi;
				if [[ $FLOW_LOG_SAMPLE_RATE_TOO_LOW == 1 ]]; then
					echo "VIOLATION: Flow log sample rate is too low";
				fi;			
			else
				echo "VIOLATION: Flow logging is not configured";
			fi;
			echo "";
		done;

	else
		echo "No subnets found for project $PROJECT_ID";
		echo "";
	fi;
	sleep 0.5;
done;

