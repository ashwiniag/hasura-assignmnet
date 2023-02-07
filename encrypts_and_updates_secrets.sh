#!/bin/bash

#set -euo pipefail
set -x

# Check if both key and value are provided
if [ "$#" -ne 6 ]; then
  echo "Usage: manage-secrets.sh --key <KEY> --value <VALUE> --service <env-echo>"
  exit 1
fi

# --existing false not implemented array set the script takes care of checking based on key and updates/adds

# Check if the arguments are provided in the correct format
if [ "$1" != "--key" ] || [ "$3" != "--value" ] || [ "$5" != "--service" ]; then
  echo "Usage: manage-secrets.sh --key <KEY> --value <VALUE> --service <SERVICE_NAME>"
  exit 1
fi

KEY=$2
echo $2
VALUE=$4
echo $4
FILE="$6_secrets.yaml" ## env-echo_secrets.yaml
current_dir=$PWD



# Check if the file exists
#cd $current_dir/provision/services_k8s
if [ ! -f $FILE ]; then
  echo "ERROR: $(FILE)_secrets.yaml file not found"
  exit 1
fi

# Check if the key exists in the file
true=$(grep -E "$KEY:" $FILE)

#echo $?

if [ -z "$true" ]; then

	# Key does not exist, add the key-value pair
  echo "INFO: Adding KEY and encrypted VALUE"
  ENCRYPTED_VALUE=$(echo -n "$VALUE" | base64)
  #echo -e "\t$KEY: $ENCRYPTED_VALUE" >> $FILE
  cat << EOF >> "$FILE"
  $KEY: $ENCRYPTED_VALUE
EOF

else

	# Key exists, update the value
  echo "INFO: KEY exists, updates its value by encrypting"
  ENCRYPTED_VALUE=$(echo -n "$VALUE" | base64)
  sed -i -E "s#  $KEY:.*#  $KEY: $ENCRYPTED_VALUE#" $FILE

fi


# Update the yaml file in Github.
 echo "INFO: The $FILE is updated. Do verify."

# echo "INFO: Committing to the branch <>, get it reviewed"
#git checkout -b updates-$(FILE)-file
#git commit -m "Updates $(FILE) with KEY=$KEY and its encrypted Value"
#git push origin updates-$(FILE)-file

echo "INFO: deploys the latest $(FILE)"
cd $current_dir/provision/services_k8s
make update

# make apply // As of now, the env-echo application doesn't read multiple automatically. Need clarity here, because this can be redeployed if the application is using it.



#Need clarification
# Does the sample_k8s_secrets.yaml itself to be crypted and uploaded?
# If just the values to be encrypted then there is no need to decrypt. Task2 requiremnt are bit ambigious
