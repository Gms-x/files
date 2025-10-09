#!/bin/bash

# Initialize a variable to track the command's success
success=0

# Loop until the command succeeds
while [ $success -eq 0 ]; do
 # Run the command and capture its exit status
 oc mirror --config=imageset-config-4.18.24.yaml  file:///root/ocp/ocp-release-images/ocp4.18.24/ --v2  --skip-verification 2>&1

 # Check the exit status of the command
 if [ $? -eq 0 ]; then
     echo "Command succeeded."
     success=1
 else
     echo "Command failed, retrying..."
     sleep 5  # Wait for 5 seconds before retrying
 fi
done
