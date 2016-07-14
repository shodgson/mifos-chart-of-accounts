#!/bin/bash
# 
# importCoA.sh 
# Import chart of accounts from CSV to Mifos X
#
# Usage:
# 
# ./importCoA.sh -u [MifosUsername] -p [MifosPassword] -t [MifosTenantId] -a [MifosUrl] -f [CSV file]
# e.g. ./importCoA.sh -u mifos -p password -t default -a https://domain.com:80/mifosng-provider/
#
# CSV format
#	One row of field headers
#	Columns must be:
#	- ID (integer): sequential from 1 (note: the resourceId will be set automatically)
#	- ParentId (integer): a number that corresponds to the ID above
#	- name (string): account name
#	- glCode (string): A user defined identifier to define the account. Must be unique.
#	- manualEntriesAllowed (boolean): define whether users can make manual entries
#	- TypeValue(string): ASSET, LIABILITY, EQUITY, INCOME, or EXPENSE
#	- usage(string): DETAIL or HEADER
#	- description (string): An informative description about the account
#
#	Restrictions:
#	- Data must not have any commas other than seperators
#
# Version: 0.0.1
# Author:  Steven Hodgson
# Contact: steven@kanopi.asia
#



# Get command line arguments

while [[ $# -gt 1 ]]
do
key="$1"

case $key in
    -u|--username)
    USERNAME="$2"
    shift 
    ;;
    -p|--password)
    PASSWORD="$2"
    shift
    ;;
    -t|--tenant)
    TENANT="$2"
    shift
    ;;
    -a|--address)
    URL="$2"
    shift
    ;;
    -f|--file)
    FILE="$2"
    shift
    ;;
    --default)
    DEFAULT=YES
    ;;
    *)
            # unknown option
    ;;
esac
shift # past argument or value
done

# Ask for argument values if not provided
if [ -z "$USERNAME" ]
then
	echo Username:
	read USERNAME
fi
if [ -z "$PASSWORD" ]
then
	echo Password:
	read -s PASSWORD
fi
if [ -z "$TENANT" ]
then
	echo "Tenant (leave blank for 'default'):"
	read TENANT
	if [ -z "$TENANT" ] 
	then
		TENANT='default'
	fi
fi
if [ -z "$URL" ]
then
	echo URL:
	read URL
fi
if [ -z "$FILE" ]
then
	echo "Name of CSV file containing chart of accounts (include file extension):"
	read FILE
fi

# Set up variables
OLDIFS=$IFS
INDEX=0
declare -A ACTUALID
#Set separator as comma (for CSV format)
IFS=,

# Helper functions

getTypeId () {
	if [ "$1" = "ASSET" ]; then
		echo 1 
	fi
	if [ "$1" = "LIABILITY" ]; then
		echo 2
	fi
	if [ "$1" = "EQUITY" ]; then
		echo 3
	fi
	if [ "$1" = "INCOME" ]; then
		echo 4
	fi
	if [ "$1" = "EXPENSE" ]; then
		echo 5
	fi
}

getUsageId () {
	if [ "$1" = "DETAIL" ]; then
		echo 1 
	fi
	if [ "$1" = "HEADER" ]; then
		echo 2
	fi
}


# Go through each line of the CSV and POST request to Mifos server
[ ! -f $FILE ] && { echo "$FILE file not found"; exit 99; }
while read ID ParentId name glCode manualEntriesAllowed TypeValue usage description
do
	# Ignore first row (field headers)
	if [ $INDEX -ne 0 ]; then
		TYPEID=$(getTypeId "$TypeValue")
		USAGEID=$(getUsageId "$usage")
		if [ -z $ParentId ]; then
			# If no parent:
			RESPONSE=$(curl -s \
				${URL}"api/v1/glaccounts" \
				-X POST \
				-H "Content-Type: application/json" \
				-H "X-Mifos-Platform-TenantId: $TENANT" \
				-u ${USERNAME}":"${PASSWORD} \
				-d "{ \
				    'name': \"$name\", \
				    'glCode': \"$glCode\", \
				    'manualEntriesAllowed': $manualEntriesAllowed, \
				    'type': $TYPEID, \
				    'usage': $USAGEID, \
				    'description': \"$description\" \
			            }" )
		else
			# If there is a parent ID
			RESPONSE=$(curl -s \
				${URL}"api/v1/glaccounts" \
				-X POST \
				-H "Content-Type: application/json" \
				-H "X-Mifos-Platform-TenantId: $TENANT" \
				-u ${USERNAME}":"${PASSWORD} \
				-d "{ \
				    'name': \"$name\", \
				    'glCode': \"$glCode\", \
				    'manualEntriesAllowed': $manualEntriesAllowed, \
				    'type': $TYPEID, \
				    'parentId': ${ACTUALID[$ParentId]}, \
				    'usage': $USAGEID, \
				    'description': \"$description\" \
			            }" )
			
		fi
		# Check the server reponded successfully with {"resourceId":xx}
		if [[ "$RESPONSE" == *"resourceId"* ]]; then
			RESOURCEID=$(awk -v RS=[0-9]+ '{print RT+0;exit}' <<< "$RESPONSE")
			# Save the resource ID to use for future parent IDs
			ACTUALID[$INDEX]=$RESOURCEID
			echo "Created [$name] with resourceId $RESOURCEID"
		else
			echo "[ERROR] Could not create general ledger account with name [$name]"
			echo "Response from server:"
			echo $RESPONSE
			exit 1
		fi
	fi
	let INDEX=INDEX+1

done < $FILE
IFS=$OLDIFS

