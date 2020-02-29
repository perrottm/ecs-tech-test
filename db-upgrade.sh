#!/bin/bash

#This script will run any SQL Scripts within a desired directory, to a desired Database. To execute the script run the following command:
#./db-upgrade.sh directory username db-host db-name db-password.
#NOTE: This will only execute scripts OF A LOWER VERSION VALUE SPECIFIED IN THE FILE NAME.

#Defining variables
DIR=$1
USER=$2
HOST=$3
DB_NAME=$4
PASS=$5
C_VER_FILE=/tmp/current_ver
REGEX="([0-9]+)"

#Gets the current version value stored on the database and stores it to a variable.
get_current_version() {
    echo "Getting current version number..."
    mysql --user="$USER" --host="$HOST" --password="$PASS" --database="$DB_NAME" --execute="SELECT * FROM versionTable" > $C_VER_FILE  ;
    CURRENT_VERION=$(cat $C_VER_FILE | tail -n 1)
    echo "Current version: ${CURRENT_VERION}"
}

#Gets the contents of the user defined directory and stores as a variable.
get_new_scripts() {
    SCRIPTS=$(ls $DIR | sort -n )
    echo "List of possible Scripts... "
    echo "${SCRIPTS}"
}

execute_scripts(){
    for e in $EXECUTE 
    do
        mysql --user="$USER" --host="$HOST" --password="$PASS" --database="$DB_NAME" < $DIR/$e
    done
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
echo "Checking scripts for new versions..."
echo ""

for s in $SCRIPTS 
do
    SCRIPTS_TO_RUN=($(cut -f1 <<< $s))
    if [ $SCRIPTS_TO_RUN -gt $CURRENT_VERION ] 
    then   
        echo $SCRIPTS_TO_RUN
        CURRENT_SCRIPTS+=([$SCRIPTS_TO_RUN]=$SCRIPTS)
    fi
done

rm -f $C_VER_FILE