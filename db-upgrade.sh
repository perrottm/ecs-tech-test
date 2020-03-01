#!/bin/bash

#This script will run any SQL Scripts within a desired directory, to a desired Database. To execute the script run the following command:
#./db-upgrade.sh directory username db-host db-name db-password.
#NOTE: This will only execute scripts OF A LOWER VERSION VALUE SPECIFIED IN THE FILE NAME.
#Defining variables

set -e

DIR=$1
USER=$2
HOST=$3
DB_NAME=$4
PASS=$5
C_VER_FILE=/tmp/current_ver

#Gets the current version value stored on the database and stores it to a variable.
get_current_version() {
    echo "Getting current version number..."
    sleep 3
    mysql --user="$USER" --host="$HOST" --password="$PASS" --database="$DB_NAME" --execute="SELECT * FROM versionTable" > $C_VER_FILE  ;
    CURRENT_VERSION=$(cat $C_VER_FILE | tail -n 1)
    echo "Current version: ${CURRENT_VERSION}"
    sleep 3
}

#Gets the contents of the user defined directory and stores as a variable.
get_new_scripts() {
    SCRIPTS=$(ls $DIR | sort -n )
    echo "List of possible Scripts... "
    echo "${SCRIPTS}"
    sleep 3
}

#Reads through the list of current scripts, takes the number from the file and checks it against the current version number. 
check_version() {
echo "Checking scripts for new versions..."
while IFS= read -r SCRIPT; do
    SCRIPT_VER=$(sed 's/[^0-9]*//g' <<< $SCRIPT)
    if [ $(($SCRIPT_VER)) -gt $(($CURRENT_VERSION)) ]
    then
        CURRENT_SCRIPTS+=([$SCRIPT_VER]=$SCRIPT)
    fi
done < <(printf '%s\n' "$SCRIPTS")
}

#Executes the sql scripts that are newer than the curerent version on the database.
execute_scripts(){
    for e in ${!CURRENT_SCRIPTS[@]}
    do
        echo "Running script: " "${CURRENT_SCRIPTS[${e}]}"
        mysql --user="$USER" --host="$HOST" --password="$PASS" --database="$DB_NAME" < "${DIR}/${CURRENT_SCRIPTS[${e}]}"
        mysql --user="$USER" --host="$HOST" --password="$PASS" --database="$DB_NAME" --execute="UPDATE versionTable SET version='$SCRIPT_VER';SELECT * from versionTable" > $C_VER_FILE
    done
    NEW_VER=$(cat $C_VER_FILE | tail -n 1)
    echo "Success! Scripts have been executed and current version is now: ${NEW_VER}"
    sleep 2
}

#Simple checker to ensure user is aware of the scripts actions.
echo "This script will apply the selected upgade scripts to the Database. It will ONLY EXECUTE SCRIPTS THAT ARE NEWER THAN THE CURRENT VERSION."
read -p "DO YOU WISH TO CONTINUE? [ (y/Y)/n ]" CONF

if [ $CONF != "Y" ] && [ $CONF != "y" ]
then
    echo "Quitting..."
    exit
else
    echo "Starting upgrade..." 
fi

get_current_version
echo ""
get_new_scripts
echo ""
check_version
echo ""
execute_scripts

#Removes the file that states the current version.
rm -f $C_VER_FILE