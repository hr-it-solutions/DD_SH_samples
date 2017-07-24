#!/bin/bash

## DD_SH_samples
## Some small excerpt samples of our private DD Staging SH Scripts
##
## No support!
##
## SAMPLE OF DD RSYNC
#
# @package    HR IT-Solutions - Deployment - RSYNC modified files
#
# @author     HR IT-Solutions Florian Häusler <info@hr-it-solutions.com>
# @copyright  Copyright (C) 2017 - 2017 Didldu e.K. | HR IT-Solutions
# @license    http://www.gnu.org/licenses/gpl-2.0.html GNU/GPLv2 only

# Load config library functions
source "$PWD"/config.shlib;

## Configuration

# Site
SITE="$(config_get SITE)"

# Directory
DIRECTORY="$(config_get DIRECTORY)"

# RSYNC Target
RSYNC_HOST="$(config_get RSYNC_HOST)"
RSYNC_TARGET="$(config_get RSYNC_TARGET)"

############

## Script

# Backup dir
BACKUPDIR="DIR"

# Backup path site
BACKPPATHSITE="${HOME}/backup/$SITE/$BACKUPDIR"

if [ -d "$BACKPPATHSITE" ]; then

    # DB Backup SYNC modified files
    printf "\RSYNC: Live site backup/$SITE/$BACKUPDIR/"
    rsync -rtvu --rsync-path="mkdir -p /$RSYNC_TARGET/$SITE/$BACKUPDIR/ && rsync" $BACKPPATHSITE/ $RSYNC_HOST:/$RSYNC_TARGET/$SITE/$BACKUPDIR/

    printf "\RSYNC successfull\n"

else
    echo "Site backups does not exists!"
fi