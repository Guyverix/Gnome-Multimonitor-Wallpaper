#!/bin/bash
#===============================================================================
#
#          FILE:  multi_updatesh
#
#         USAGE:  ./multi_update.sh
#
#   DESCRIPTION:  This script is part of multi_wallapers.  This is the indexer
#                 and updater for the images_v3.lst file.  It is designed to be
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
      echo "`date` Starting an update of the images_v3.lst file"
      echo "Indexing path data defined in config file..."
      echo "This may take awhile depending on how many new files there are..."

   while read x; do
   SIZE=`identify -verbose "$x" | grep 'Geometry:' | sed 's/.*://' | sed 's/+.*//' | sed 's/[ ]//g'`
   if [ -n "${SIZE}" ];then
      X_CHECK=`echo ${SIZE} | awk -F'x' '{print $1}'`
      Y_CHECK=`echo ${SIZE} | awk -F'x' '{print $2}'`
      if [ ${X_CHECK} -gt ${SIZE_X} -a ${Y_CHECK} -gt ${SIZE_Y} ];then
         echo "'${x}' '${SIZE}'" >> images_v3.lst
         echo "Added: ${x} "
      fi
   fi
   done < <(find ${INDEX} -follow -type f -mtime -${REFRESH} \( -name "*.jpg" -o -name "*.png" \) -exec echo {} \;)
   # Do not allow duplicate entries
   touch images_v3.tmp
   cat images_v3.lst | uniq  >> images_v3.tmp
   mv images_v3.tmp images_v3.lst
      ;;
   [Nn]*)
      echo "`date` Full index of all images starting for images_v3.lst file"
      rm -f images_v3.lst
      touch images_v3.lst

      echo "Indexing path data defined in config file..."
      echo "This may take awhile depending on how many files there are..."

   while read x; do
   SIZE=`identify -verbose "$x" | grep 'Geometry:' | sed 's/.*://' | sed 's/+.*//' | sed 's/[ ]//g'`
   if [ -n "${SIZE}" ];then
      X_CHECK=`echo ${SIZE} | awk -F'x' '{print $1}'`
      Y_CHECK=`echo ${SIZE} | awk -F'x' '{print $2}'`
      if [ ${X_CHECK} -gt ${SIZE_X} -a ${Y_CHECK} -gt ${SIZE_Y} ];then
         echo "'${x}' '${SIZE}'" >> images_v3.lst
      fi
   fi
   done < <(find ${INDEX} -follow -type f \( -name "*.jpg" -o -name "*.png" \) -exec echo {} \;)

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
