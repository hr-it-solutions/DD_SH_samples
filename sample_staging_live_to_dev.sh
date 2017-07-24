#!/bin/bash

## DD_SH_samples
## Some small excerpt samples of our private DD Staging SH Scripts
##
## No support!
##
## SAMPLE OF DD STAGING
#
# @package    HR IT-Solutions - Deployment - Staging Live to dev + Backup + Database + chmod
#
# @author     HR IT-Solutions Florian Häusler <info@hr-it-solutions.com>
# @copyright  Copyright (C) 2017 - 2017 Didldu e.K. | HR IT-Solutions
# @license    http://www.gnu.org/licenses/gpl-2.0.html GNU/GPLv2 only

# Load config library functions
source "$PWD"/config.shlib;

## Configuration

# Exclude File Pattern
EXC_FPATTERN="$(config_get EXC_FPATTERN)"

# Live site
LIVE_SITE="$(config_get LIVE_SITE)"

# Dev site
DEV_SITE="$(config_get DEV_SITE)"

# Directory
DIRECTORY="$(config_get DIRECTORY)"

# Live Site database
LIVE_HOST="$(config_get LIVE_HOST)"
LIVE_USER="$(config_get LIVE_USER)"
LIVE_PASSWORD="$(config_get LIVE_PASSWORD)"
LIVE_DATABASE="$(config_get LIVE_DATABASE)"

# Dev Site database
DEV_HOST="$(config_get DEV_HOST)"
DEV_USER="$(config_get DEV_USER)"
DEV_PASSWORD="$(config_get DEV_PASSWORD)"
DEV_DATABASE="$(config_get DEV_DATABASE)"

############

## Script

# Datestamp
DATESTAMP=`date +%Y-%m-%d_%Hh%Mm`

# Full path live site
FULLPATH_LIVE="$DIRECTORY/$LIVE_SITE/"

# Full path dev site
FULLPATH_DEV="$DIRECTORY/$DEV_SITE/"

# Function process live to dev
process_ltd () {

    # File-Backup first
    printf "\nFile Backup: backup/$DEV_SITE/$DATESTAMP/\n"
    mkdir ${HOME}/backup/$DEV_SITE/
    mkdir ${HOME}/backup/$DEV_SITE/$DATESTAMP/
    cp -R $DIRECTORY/$DEV_SITE/* ${HOME}./backup/$DEV_SITE/$DATESTAMP/

    # Database-Backup first
    printf "\nDatabase Backup: backup/$DEV_SITE/_db_backup/..."
    sh "$PWD"/dev_backup_db.sh #todo! NOT PROVIDED IN SAMPLE SCRITPS!

    printf "\nBackup successfull\n"

    printf "\nFiles to ignored from dev site:\n"
    find "$FULLPATH_DEV" -regex ".*/\(.htaccess\|.htpasswd\|.user.ini\\${EXC_FPATTERN})" -print

    # Sleep 2 seconds to get time to check files
    sleep 2

    ## Delete files form folder, excluded specific files
    # Find in folder                        find "$FULLPATH_DEV"
    # Delete all files, excluded pattern    -not -regex ".*/\(.htaccess\|.user.ini\)" -delete
    # Suppress not empty folder errors      2>/dev/null
    find "$FULLPATH_DEV" -not -regex ".*/\(.htaccess\|.htpasswd\|.user.ini\\${EXC_FPATTERN})" -delete 2>/dev/null

    printf "\nFiles to ignored from live site:\n"
    find "$FULLPATH_LIVE" -regex ".*/\(.htaccess\|.htpasswd\|.user.ini\\${EXC_FPATTERN})" -print

    cd $FULLPATH_LIVE

    printf "\nJob in progress:\n"
    sleep 2

    echo -ne 'Creating directories\r'

    ## Copy dir from dir to dir
    find -type d -exec mkdir ../$FULLPATH_DEV{} \; 2>/dev/null

    echo -ne 'Creating files      \r'

    ## Copy files form dir to dir, excluded specific files
    find -type f -not -regex ".*/\(.htaccess\|.htpasswd\|.user.ini\\${EXC_FPATTERN})" -exec cp -r {} ../$FULLPATH_DEV{} \; 2>/dev/null

    echo -ne 'chmod directories      \r'
    find ../$FULLPATH_DEV -type d -exec chmod 755 {} \;

    echo -ne 'chmod files           \r'
    find ../$FULLPATH_DEV -type f -exec chmod 444 {} \;
    find ../$FULLPATH_DEV -type f -not -regex ".*/\(.htaccess\|.htpasswd\\${EXC_FPATTERN})" -exec chmod 644 {} \;

    echo -ne 'Database mysqldump    \r'

    # Database to dev
    mysqldump -h$LIVE_HOST -u$LIVE_USER -p$LIVE_PASSWORD $LIVE_DATABASE | mysql -h$DEV_HOST -u$DEV_USER -p$DEV_PASSWORD $DEV_DATABASE

    echo -ne 'Job done :)           \r'
    sleep 5
    printf "\n"

}

# Alert DB Function
alert_db () {

    while true; do
    printf "\nDatabase Live to dev:\n"
    read -p "Are you sure ([Y] Yes [N] No) to bring live database to dev site?" yn
        case $yn in
            [Yy]* ) process_ltd; break;;
            [Nn]* ) exit;;
            * ) echo "Please answer yes or no.";;
        esac
    done

}

if [ -d "$FULLPATH_LIVE" ]; then

    if [ -d "$FULLPATH_DEV" ]; then

        while true; do
        printf "\nLive to dev:\n"
        read -p "Are you sure ([Y] Yes [N] No) to bring live to dev site?" yn
            case $yn in
                [Yy]* ) alert_db; break;;
                [Nn]* ) exit;;
                * ) echo "Please answer yes or no.";;
            esac
        done

    else
        echo "Dev site path does not exists!"
    fi

else
    echo "Live site path does not exists!"
fi