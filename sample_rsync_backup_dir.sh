#!/bin/bash

## DD_SH_samples
## Some small excerpt samples of our private DD Staging SH Scripts
##
## No support!
##
## SAMPLE OF DD RSYNC
#
# @package    HR IT-Solutions - Deployment - File Backup Script THAN RSYNC << This
#
# @author     HR IT-Solutions Florian Häusler <info@hr-it-solutions.com>
# @copyright  Copyright (C) 2017 - 2017 Didldu e.K. | HR IT-Solutions
# @license    http://www.gnu.org/licenses/gpl-2.0.html GNU/GPLv2 only

# Load config library functions
source "$PWD"/config.shlib;

## Configuration

# Site
SITE="$(config_get LIVE_SITE)"

# Directory
DIRECTORY="$(config_get DIRECTORY)"

# RSYNC Target
RSYNC_HOST="$(config_get RSYNC_HOST)"
RSYNC_TARGET="$(config_get RSYNC_TARGET)"

############

## Script

# Datestamp
DATESTAMP=`date +%Y-%m-%d_%Hh%Mm`

# Full path site
FULLPATH_SITE="$DIRECTORY/$SITE/"

if [ -d "$FULLPATH_SITE" ]; then

    # File-Backup first
    printf "\nBackup: backup/$SITE/$DATESTAMP/\n"
    mkdir ${HOME}/backup/$SITE/
    mkdir ${HOME}/backup/$SITE/$DATESTAMP/
    cp -R $DIRECTORY/$SITE/. ${HOME}/backup/$SITE/$DATESTAMP/

    printf "\nRSYNC Backup: $RSYNC_HOST:$RSYNC_TARGET/$SITE/$DATESTAMP/.\n"
	rsync -a --rsync-path="mkdir -p /$RSYNC_TARGET/$SITE/$DATESTAMP/ && rsync" ${HOME}/backup/$SITE/$DATESTAMP/ $RSYNC_HOST:/$RSYNC_TARGET/$SITE/$DATESTAMP/.

    printf "\nBackup successfull\n"

else
    echo "Site path does not exists!"
fi