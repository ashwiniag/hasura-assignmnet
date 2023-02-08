#!/bin/bash

#set -euo pipefail
set -x

# Check if both key and value are provided
if [ "$#" -ne 6 ]; then
  echo "Usage: ./encrypts_and_updates_secrets.sh --key <KEY> --value <VALUE> --service <env-echo>"
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
FILE="$6_secrets.yaml" ## encrypted_env-echo_secrets.yaml
current_dir=$PWD



# Check if the file exists
cd $current_dir/provision/services_k8s
if [ ! -f encrypted_${FILE} ]; then
  echo "ERROR: encrypted_'${FILE}' file not found"
  exit 1
fi


function encrypt_the_file() {
  #the input file: $FILE, or do I need to check if the file is ecnrypted??
	# Define the output file
	output_file="encrypted_$FILE"

	# Encrypt
	## tested: echo value=$(openssl enc -aes-256-cbc -salt -in "env-echo_secrets.yaml" -out "encrypt_env-echo_secrets.yaml" -k "your-encryption-key-dummy")
	encryption_key="your-encryption-key-dummy" #maybe keep it constant?
	encrypted_contents=$(openssl enc -aes-256-cbc -salt -in "decrypted_${FILE}" -out "${output_file}" -k "$encryption_key")

	echo "Encrypted secret file created: $output_file"
}

#Self note:
#openssl enc: invokes the openssl encryption utility
#-aes-256-cbc: specifies the encryption algorithm to use, aes-256-cbc ?
#-salt: generates a random salt value to be used during encryption, which helps to make the encrypted data more secure

function decrypt_the_file() {
  #the input file: $FILE
	# Define the output file
	input_file="encrypted_$FILE"
	output_file="decrypted_$FILE"

	# Encrypt
	encryption_key="your-encryption-key-dummy" #maybe keep it constant?
	decrypted_contents=$(openssl enc -d -aes-256-cbc -in "$input_file" -out "$output_file" -k "$encryption_key")

	echo "Decrypted secret file created: $output_file"
}

# Check if the key exists in the file
decrypt_the_file
#exit 1
true=$(grep -E "$KEY:" "decrypted_${FILE}")

#echo $?

if [ -z "$true" ]; then

	# Key does not exist, add the key-value pair
  echo "INFO: Adding KEY and encrypted VALUE"
  ENCRYPTED_VALUE=$(echo -n "$VALUE" | base64)
  #echo -e "\t$KEY: $ENCRYPTED_VALUE" >> $FILE
  cat << EOF >> "decrypted_$FILE"
  $KEY: $ENCRYPTED_VALUE
EOF
	# encrypt the file:
	encrypt_the_file
else

	# Key exists, update the value
  echo "INFO: KEY exists, updates its value by encrypting"
  ENCRYPTED_VALUE=$(echo -n "$VALUE" | base64)
  sed -i -E "s#  $KEY:.*#  $KEY: $ENCRYPTED_VALUE#" $FILE
	# encrypt the file:
	encrypt_the_file
fi



# Update the yaml file in Github.
echo "INFO: The $FILE is updated. Do verify."


#function git_commit() {
# TODO: git pull the file, do the logic text and git commit to new brach"
#	echo "INFO: Committing to the branch <>, get it reviewed"
#	git checkout -b updates-$(FILE)-file
#	git commit -m "Updates $(FILE) with KEY=$KEY and its encrypted Value"
#	git push origin updates-$(FILE)-file
#
#}


echo "INFO: deploys the latest $(FILE)"
cd $current_dir/provision/services_k8s
make update

# make apply // As of now, the env-echo application doesn't read multiple automatically. Need clarity here, because this can be redeployed if the application is using it.




# local test:
#decrypted_contents=$(openssl enc -d -aes-256-cbc -in "$input_file" -out "$output_file" -k "$encryption_key")
#echo value=$(openssl enc -d -aes-256-cbc -in "encrypted_env-echo_secrets.yaml" -out "decrypt_env-echo_secrets.yaml" -k "your-encryption-key-dummy")
#echo value=$(openssl enc -aes-256-cbc -salt -in "env-echo_secrets.yaml" -out "encrypted_env-echo_secrets.yaml" -k "your-encryption-key-dummy")
