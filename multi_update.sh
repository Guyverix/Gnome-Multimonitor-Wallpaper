#!/bin/bash
#===============================================================================
#
#          FILE:  multi_updatesh
#
#         USAGE:  ./multi_update.sh
#
#   DESCRIPTION:  This script is part of multi_wallapers.  This is the indexer
#                 and updater for the images.lst file.  It is designed to be
#                 called from the main script itself, so that the main script
#                 can get new indexing values when wallpapers are added.
#
#       OPTIONS:  none
#  REQUIREMENTS:  Basic conf file. The imagemagick installation
#                 is manditory for this to work correctly.
#          BUGS:  None known
#         NOTES:  ---
#        AUTHOR:  Christopher S. Hubbard (), guyverix@yahoo.com
#       COMPANY:  I Will Fear No Evil DOT com
#       VERSION:  0.4.1
#       CREATED:  03/04/2011 07:27:43 PM PST
#      REVISION:  Amanda
#===============================================================================

LOCATION=/home/${USER}/.multi_wall

# Make sure we have a valid config file or die
if [ -e multi.cfg ];then
. ${LOCATION}/multi.cfg
else
   echo "Please set up the ${LOCATION}/multi.cfg file."
   exit 1
fi

# Define either create a new index or attempt to update the existing one.

case $1 in
   [Uu]*)
   echo "`date` Starting an update of the images.lst file"
   echo "Indexing path data defined in config file..."
   echo "This may take awhile depending on how many new files there are..."
   PROC=`cat /proc/cpuinfo | grep -c processor`

   while read x; do
     ${LOCATION}/identify.sh "${x}" &
     while [ `ps aux | grep -c '[i]dentify'` -gt ${PROC} ]; do
       sleep 1
     done
   # Ignore lost+found find /home/USER/Wallpapers -name '*lost+found*' -prune -follow -o -type f -mtime +1
   # find /home/USER/Wallpapers  -follow -type f -name "*lost+found*" -prune -o \( -name "*.jpg" -o -name "*.png" \) -exec echo {} \;
   done < <(find ${INDEX} -name '*lost+found*' -prune -follow -type f -mtime -${REFRESH} \( -name "*.jpg" -o -name "*.png" \) -exec echo {} \;)
   # Do not allow duplicate entries
   touch ${LOCATION}/images_full.tmp
   cat ${LOCATION}/images_full.lst | uniq  >> ${LOCATION}/images_full.tmp
   mv ${LOCATION}/images_full.tmp ${LOCATION}/images_full.lst
   ;;
   [Nn]*)
   echo "`date` Full index of all images starting for images_full.lst file"
   rm -f ${LOCATION}/images_full.lst
   touch ${LOCATION}/images_full.lst

   echo "Indexing path data defined in config file..."
   echo "This may take awhile depending on how many files there are..."

   echo "Finding all image files to verify"
   find ${INDEX} -follow -type f -name "*lost+found*" -prune -o \( -name "*.jpg" -o -name "*.png" \) -exec echo {} \; >> /tmp/image_wip_$$.lst
   PROC=`cat /proc/cpuinfo | grep -c processor`
   for x in `cat /tmp/image_wip_$$.lst` ;do
     ${LOCATION}/identify.sh "${x}" &
     while [ `ps aux | grep -c '[i]dentify'` -gt ${PROC} ]; do
       sleep 1
     done
   done
   rm -f /tmp/image_wip$$.lst
   ;;
   [Rr]*)
   echo "Randomize the images.lst file"
   cat ${LIST} | while read line; do echo "$RANDOM $line"; done | sort | sed -r 's/^[0-9]+ //' > ${LOCATION}/images.changed
   mv ${LOCATION}/images.changed ${LIST}
   ;;
   *)
   echo "No valid options given, exiting before I do something wrong"
   echo "Valid options for this script are N (new) U (Update) R (Randomize) image list"
   ;;
esac

exit 0
