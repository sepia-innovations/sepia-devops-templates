#!/bin/bash
set -e

# Function to handle upgrading services
deploy_services() {
    
    # Extracting parameters and removing trailing spaces
    local workspace_dir=${1%% }
    local service_list=${2%% }
    local new_tag=${3%% }

    echo "Welcome to the Deployment Process of Docker Compose Service: ${service_list}"
    echo "Working Directory: ${workspace_dir}"

    # Move to the directory containing micro-services
    cd ${workspace_dir}

    echo "Taking Backup of .env file"
    cp -rf .env .env.bak

    # Echo statement to display the comma-separated service list
    echo "Comma separated services list: ${service_list}"

    # Splitting the service list into an array
    IFS=',' read -r -a service_array <<< "${service_list}"
    
    # Echo statement to display the array of service list
    echo "Array of services list: ${service_array[@]}"

    # Check if service list is empty
    if [[ -z "${service_array}" ]]; then
        echo "Service list is empty. Exiting."
        exit 1
    fi

    # Get existing image information from one service to identify the image
    service_name=${service_array[0]}

    existing_image_long=$(docker container ls --all --filter label=com.docker.compose.service --format "{{.Image}}" | awk -v service="$service_name" '$0 ~ service {print $1, $2, $3}')
    existing_image_short=$(echo "${existing_image_long}" | awk -F '/' '{print $NF}')
    existing_tag=$(echo "${existing_image_long}" | awk -F ':' '{print $NF}')

    # Echo statement to display the current image being deleted
    echo "Deleting Current Image: ${existing_image_long}"
    
    # Delete existing image
    docker rmi --force ${existing_image_long} || true

    # Extract service underscore
    service_underscore=$(echo "${service_name}" | tr '-' '_')
    
    # Get current tag from .env file
    env_current_tag=$(grep -E "^${service_underscore}=" .env | cut -d '=' -f2-)
    if [[ -z "${env_current_tag}" ]]; then
        echo "Configuration for '${service_underscore}' is missing in the .env file. Exiting."
        exit 1
    fi

    # Echo statements to display old and new tag information
    echo "Existing Tag: ${env_current_tag}"
    echo "New Tag: ${new_tag}"
    echo "Service Underscore: ${service_underscore}"
    
    # Update .env file with new tag
    echo "Updating .env file with new configuration"
    sed -i "s/^${service_underscore}=.*/${service_underscore}=${new_tag}/" .env

    # Loop through each service in the list
    for service_name in "${service_array[@]}"; do
        echo "Processing Service: ${service_name}"
        existing_container_id=$(docker-compose ps -q ${service_name})

        # Restart services
        # || "${service_name}" == "ai-client-portal-apis"
        if [[ "${service_name}" == "ai-client-portal" || "${service_name}" == "ai-client-portal-apis" ]]; then
            # Restart nginxproxy conditionally only after successful upgrade
            docker-compose stop "${service_name}" && docker-compose rm "${service_name}" --force
            docker-compose up -d --force-recreate --no-deps --quiet-pull "${service_name}" && docker-compose stop nginxproxy && docker-compose start nginxproxy
        else
            # Upgrade other services as usual
            docker-compose stop "${service_name}" && docker-compose rm "${service_name}" --force
            docker-compose up -d --force-recreate --no-deps --quiet-pull "${service_name}"
        fi
        sleep 2

        # Echo statement to display updated image information
        new_container_id=$(docker-compose ps -q ${service_name})
        echo Previous Container Id: $existing_container_id
        echo New Container Id: $new_container_id
        if [[ "$new_container_id" == "$existing_container_id" ]]; then
            echo "New container ID is the same as the old one, Deployment check failed. Exiting."
            exit 1
        fi
    done
}

# Check if the number of arguments provided is correct
if [[ $# -ne 3 ]]; then
    echo "Usage: $0 <workspace_dir> <service_list> <new_tag>"
    exit 1
fi

# Usage of the function: deploy_services "service1,service2" "new_tag"
deploy_services "$1" "$2" "$3"