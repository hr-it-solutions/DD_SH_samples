#!/bin/bash

## DD_SH_samples
## Some small excerpt samples of our private DD Staging SH Scripts
##
## No support!
##
## SAMPLE OF DD STAGING
#
# @package    HR IT-Solutions - Deployment - Staging Dev to live + Backup + DB + chmod strict
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

# Dev Site database
DEV_HOST="$(config_get DEV_HOST)"
DEV_USER="$(config_get DEV_USER)"
DEV_PASSWORD="$(config_get DEV_PASSWORD)"
DEV_DATABASE="$(config_get DEV_DATABASE)"

# Live Site database
LIVE_HOST="$(config_get LIVE_HOST)"
LIVE_USER="$(config_get LIVE_USER)"
LIVE_PASSWORD="$(config_get LIVE_PASSWORD)"
LIVE_DATABASE="$(config_get LIVE_DATABASE)"

############

## Script

# Datestamp
DATESTAMP=`date +%Y-%m-%d_%Hh%Mm`

# Full path live site
FULLPATH_LIVE="$DIRECTORY/$LIVE_SITE/"

# Full path dev site
FULLPATH_DEV="$DIRECTORY/$DEV_SITE/"

#HASH 20 character
HASH="$(echo -n "$DATESTAMP" | md5sum )"
HASH=$(expr substr "${HASH}" 1 20)

#Folder prefixes
DTL_UPDATE=_dtl_update_
DTL_TRASH=_dtl_trash_

#Tmp update and trash folder
LIVE_SITE_UPDATE_HASH=$LIVE_SITE$DTL_UPDATE$HASH
LIVE_SITE_TRASH_HASH=$LIVE_SITE$DTL_TRASH$HASH

# Function process live to dev
process_dtl () {

    printf "\nchmod live site directories"
    find $DIRECTORY/$LIVE_SITE/ -type d -exec chmod 755 {} \;
    printf "\nchmod live site files"
    find $DIRECTORY/$LIVE_SITE/ -type f -exec chmod 644 {} \;

    # File-Backup first
    printf "\nFile Backup: backup/$LIVE_SITE/$DATESTAMP\n"
    mkdir ${HOME}/backup/$LIVE_SITE/
    mkdir ${HOME}/backup/$LIVE_SITE/$DATESTAMP/
    cp -R $DIRECTORY/$LIVE_SITE/* ${HOME}/backup/$LIVE_SITE/$DATESTAMP/

    # Database-Backup first
    printf "\nDatabase Backup: backup/$LIVE_SITE/_db_backup/..."
    sh "$PWD"/live_backup_db.sh #todo! NO PROVIDED IN SAMPLE SCRITPS!

    printf "\nBackup successfull\n"

    # TMP Update folder
    printf "\nhtml/$LIVE_SITE_UPDATE_HASH"
    mkdir "$DIRECTORY/$LIVE_SITE_UPDATE_HASH/"
    cp -R $DIRECTORY/$LIVE_SITE/ $DIRECTORY/$LIVE_SITE_UPDATE_HASH/

    printf "\nFiles to ignored from live site:\n"
    find $DIRECTORY/$LIVE_SITE_UPDATE_HASH/ -regex ".*/\(.htaccess\|.htpasswd\|.user.ini\\${EXC_FPATTERN})" -print

    # Sleep 2 seconds to get time to check files
    sleep 2

    ## Delete files form folder, excluded specific files
    # Find in folder                        find "$FULLPATH_DEV"
    # Delete all files, excluded pattern    -not -regex ".*/\(.htaccess\|.htpasswd\|.user.ini\\${EXC_FPATTERN})" -delete
    # Suppress not empty folder errors      2>/dev/null
    find $DIRECTORY/$LIVE_SITE_UPDATE_HASH/ -not -regex ".*/\(.htaccess\|.htpasswd\|.user.ini\\${EXC_FPATTERN})" -delete 2>/dev/null

    printf "\nFiles to ignored from dev site:\n"
    find "$FULLPATH_DEV" -regex ".*/\(.htaccess\|.htpasswd\|.user.ini\\${EXC_FPATTERN})" -print

    cd $FULLPATH_DEV

    printf "\nJob in progress:\n"
    sleep 2

    echo -ne 'Creating directories\r'

    ## Copy dir from dir to dir
    find -type d -exec mkdir ../$DIRECTORY/$LIVE_SITE_UPDATE_HASH/$LIVE_SITE/{} \; 2>/dev/null

    echo -ne 'Creating files      \r'

    ## Copy files form dir to dir, excluded specific files
    find -type f -not -regex ".*/\(.htaccess\|.htpasswd\|.user.ini\\${EXC_FPATTERN})" -exec cp -r {} ../$DIRECTORY/$LIVE_SITE_UPDATE_HASH/$LIVE_SITE/{} \; 2>/dev/null

    echo -ne 'Set live site online \r'

    # Rename old live site to trash
    mv ../$FULLPATH_LIVE ../$DIRECTORY/$LIVE_SITE_TRASH_HASH

    # Rename new updated live site hash to LIVE_SITE
    mv ../$DIRECTORY/$LIVE_SITE_UPDATE_HASH/$LIVE_SITE ../$DIRECTORY/$LIVE_SITE

    echo -ne 'Database mysqldump  \r'

    # Database to live
    mysqldump -h$DEV_HOST -u$DEV_USER -p$DEV_PASSWORD $DEV_DATABASE | mysql -h$LIVE_HOST -u$LIVE_USER -p$LIVE_PASSWORD $LIVE_DATABASE

    # Delete live site hash
    rm -r ../$DIRECTORY/$LIVE_SITE_UPDATE_HASH/

    # Remove old live site
    rm -r ../$DIRECTORY/$LIVE_SITE_TRASH_HASH/

    echo -ne 'chmod direcotries strict\r'
    find ../$DIRECTORY/$LIVE_SITE/ -type d -exec chmod 555 {} \;

    echo -ne 'chmod direcotries exclude\r'
    #todo: Example of excluding dir 	find ../$DIRECTORY/$LIVE_SITE/cache/ -type d -exec chmod 755 {} \;

    echo -ne 'chmod files strict      \r'
    find ../$DIRECTORY/$LIVE_SITE/ -type f -exec chmod 444 {} \;

    echo -ne 'chmod files exclude      \r'
    #todo: Example of excluding file 	find ../$DIRECTORY/$LIVE_SITE/cache/ -type f -exec chmod 644 {} \;

    echo -ne 'Job done :)            \r'
    sleep 5
    printf "\n"

}

# Alert DB Function
alert_db () {

    while true; do
    printf "\nDatabase Dev to live:\n"
    read -p "Are you sure ([Y] Yes [N] No) to bring dev database to live site?" yn
        case $yn in
            [Yy]* ) process_dtl; break;;
            [Nn]* ) exit;;
            * ) echo "Please answer yes or no.";;
        esac
    done

}

if [ -d "$FULLPATH_DEV" ]; then

    if [ -d "$FULLPATH_LIVE" ]; then

        while true; do
        printf "\nDev to live:\n"
        read -p "Are you sure ([Y] Yes [N] No) to bring dev to live site?" yn
            case $yn in
                [Yy]* ) alert_db; break;;
                [Nn]* ) exit;;
                * ) echo "Please answer yes or no.";;
            esac
        done

    else
        echo "Live site path does not exists!"
    fi

else
    echo "Dev site path does not exists!"
fi