#!/bin/bash
#===============================================================================
#
#          FILE:  multi_wallpapers.sh
#
#         USAGE:  ./multi_wallpapers.sh
#
#   DESCRIPTION:  This script is intended to create dual, side by side wallpaper
#                 for Linux systems running Gnome and want random different
#                 wallpapers on each monitor.  It will do more, but it has not
#                 been tested.
#       OPTIONS:  none
#  REQUIREMENTS:  Basic conf file and index file.  Resolutions are expected to
#                 be the same at the moment. xrandr is helpful, and imagemagick
#                 is manditory for this to work correctly.
#          BUGS:  None known
#         NOTES:  ---
#        AUTHOR:  Christopher S. Hubbard (), guyverix@yahoo.com
#       COMPANY:  I Will Fear No Evil DOT com
#       VERSION:  1.0.1
#       CREATED:  03/04/2011 07:27:43 PM PST
#      REVISION:  Emily
#===============================================================================



LOCATION=/home/${USER}/.multi_wall

if [ -e ${LOCATION}/multi.cfg ];then
  . ${LOCATION}/multi.cfg
else
  echo "Please create the config file \"${LOCATION}/multi.cfg\" "
  exit 1
fi

if [ -e ${LOCATION}/images.lst ];then
  # We know we have a set of images to start with
  JUNK=0
else
  echo "Indexing images found in the path defined in config file"
  echo "This may take awhile depending on counts"
  nice nohup multi_update.sh New 2&1 > /dev/null &
fi

shopt -s nocasematch
case ${1} in
  N|Ne*)
    nice nohup ${LOCATION}/multi_update.sh New &> /dev/null
    exit 0
    ;;
  U|Upd*)
    nice nohup ${LOCATION}/multi_update.sh Update &> /dev/null
    exit 0
    ;;
  R|Ran*)
    nohup ${LOCATION}/multi_update.sh Random &> /dev/null
    exit 0
    ;;
  *)
    #catchall for other than new
    JUNK=0
    ;;
esac
shopt -u nocasematch


full_spanner() {
  local full_x=${RT_SIZE_SPAN_X}
  local full_y=${RT_SIZE_SPAN_Y}
  local check_x=`echo "${@}" | awk '{print $NF}' | sed "s/'//g" | awk -F'x' '{print $1}'`
  local check_y=`echo "${@}" | awk '{print $NF}' | sed "s/'//g" | awk -F'x' '{print $2}'`
  local return=NO
  if [ ${check_x} -gt ${full_x} -a ${check_y} -gt ${full_y} ];then
    # We know this is valid for spanning ALL monitors
    local return=YES
  fi
  echo "${return}"
}

row_spanner() {
  eval full_x='${R'${RSTART}'_SIZE_SPAN_X}'
  eval full_y='${R'${RSTART}'_SIZE_SPAN_Y}'
  local check_x=`echo "${@}" | awk '{print $NF}' | sed "s/'//g" | awk -F'x' '{print $1}'`
  local check_y=`echo "${@}" | awk '{print $NF}' | sed "s/'//g" | awk -F'x' '{print $2}'`
  local return=NO
  if [ ${check_x} -gt ${full_x} -a ${check_y} -gt ${full_y} ];then
    # We know this is valid for spanning the row of monitors
    local return=YES
  fi
  echo "${return}"
}

grab_image() {
  local range=`grep -c '^' ${LIST}`
  if [ "${SEARCH}" = "RANDOM" ];then
    local pick=$[ (${RANDOM} % ${range} ) +1 ]
    local image=`awk "NR==${pick}" "${LIST}"`
    # logging to confirm we really get random images
    echo "Max: ${range} Pick: ${pick} Detail: ${image}" >> ${LOCATION}/random.log
  else
    if [ -e ${LOCATION}/multi.count ];then
      local counts=`cat ${LOCATION}/multi.count`
      if [ ${counts} -ge ${range} ];then
        counts=1
      fi
      local image=`awk "NR==${counts}" "${LIST}"`
      counts=$(($counts +1))
      echo "$counts" > ${LOCATION}/multi.count
    else
      local counts=1
      local image=`awk "NR==${counts}" "${LIST}"`
      echo "$counts" > ${LOCATION}/multi.count
    fi
  fi
  echo "${image}"
}

create_full_span() {
#echo create full span
  local fin_image=`echo ${FULL_SPAN} | awk '{print $1}' | sed "s/'//g"`
#  nice  convert ${fin_image} -gravity "${GRAVITY_SPAN}" -background ${BG_COLOR} -resize ${SPAN_SIZE_RT} ${LOCATION}/background.jpg
  convert ${fin_image} -background ${BG_COLOR} -resize ${SPAN_SIZE_RT} ${LOCATION}/background.jpg
  gconftool-2 --set "/desktop/gnome/background/picture_options" --type string "spanned"
}

create_row_span() {
#echo create row span ${RSTART}
  local row_span=${RSTART}
  eval row_size='$SPAN_SIZE_R'${RSTART}
  local fin_image=`echo ${ROW_SPAN} | awk '{print $1}' | sed "s/'//g"`
#  nice  convert ${fin_image} -background ${BG_COLOR} -gravity "${GRAVITY1}" -resize ${row_size}  -extent ${row_size} /tmp/multi_wall_row_${row_span}.jpg
  convert ${fin_image} -background ${BG_COLOR} -gravity "${GRAVITY1}" -resize ${row_size}  -extent ${row_size} /tmp/multi_wall_row_${row_span}.jpg
}

create_descrete() {
#echo  create descrete row ${RSTART}
  local row_span=${RSTART}
  local fin_image=${CLEANUP}
  local j=$i
  eval row_size='${R'${RSTART}'_['$j']}'
#  nice  convert ${fin_image} -background ${BG_COLOR} -gravity "${GRAVITY1}" -resize ${row_size} -extent ${row_size} /tmp/multi_wall_row_${row_span}_${i}.jpg
  convert ${fin_image} -background ${BG_COLOR} -gravity "${GRAVITY1}" -resize ${row_size} -extent ${row_size} /tmp/multi_wall_row_${row_span}_${i}.jpg
}

merge_descrete() {
#echo merge descrete!
  if [ "${ORIENT}" == "horizontal" ];then
    local orentation="+"
  else
    local orentation="-"
  fi
  local row_span=${CSTART}
  for merge in `find /tmp/multi_wall_row_${CSTART}_*`;do
    local fin_image="$fin_image ${merge}"
  done
  eval row_size='$SPAN_SIZE_R'${CSTART}
#  nice  convert ${fin_image} -background ${BG_COLOR} -gravity "${GRAVITY1}" ${orentation}append /tmp/multi_wall_row_${row_span}.jpg
  convert ${fin_image} -background ${BG_COLOR} -gravity "${GRAVITY1}" ${orentation}append /tmp/multi_wall_row_${row_span}.jpg
}

create_merge() {
#echo create merge!
  if [ "${ORIENT}" == "horizontal" ];then
    local merge="-"
  else
    local merge="+"
  fi

  for row_counts in `seq 1 ${ROWS}`;do
    local images="${images} /tmp/multi_wall_row_${row_counts}.jpg"
  done
  local row_size=${SPAN_SIZE_RT}
#  nice  convert ${images} -background ${BG_COLOR} -gravity "${GRAVITY1}" ${merge}append ${LOCATION}/background.jpg
  convert ${images} -background ${BG_COLOR} -gravity "${GRAVITY1}" ${merge}append ${LOCATION}/background.jpg
  gconftool-2 --set "/desktop/gnome/background/picture_options" --type string "spanned"
  gconftool-2 -t string -s /desktop/gnome/background/picture_filename ${LOCATION}/background.jpg
}

while true; do
monitors=0
RSTART=1

# error correction and definition if there is only 
# one row of monitors
if [ "${ROWS}" -eq "1" ];then
  RT_SIZE_SPAN_X=${R1_SIZE_SPAN_X}
  RT_SIZE_SPAN_Y=${R1_SIZE_SPAN_Y}
fi

while [ "${RSTART}" -le "${ROWS}" ];do
  eval ARRAYS='${#R'${RSTART}'_[@]}'
  for ((i=0; i< ${ARRAYS}; i++)); do
    eval  WHERE='${R'${RSTART}'_[$i]}'

    IMAGE=$(grab_image)
    FULL_CHECK=$(full_spanner ${IMAGE})
    if [ "${FULL_CHECK}" == "YES" ];then
      FULL_SPAN=${IMAGE}
      create_full_span "$FULL_SPAN"
      break 2
    fi

    ROW_CHECK=$(row_spanner ${IMAGE})
    if [ "${ROW_CHECK}" == "YES" ];then
      ROW_SPAN=${IMAGE}
      create_row_span "${ROW_SPAN}"
      break
    else
      CLEANUP=`echo ${IMAGE} | awk '{print $1}' | sed "s/'//g"`
      DESCRETE="${DESCRETE} ${CLEANUP}"
      create_descrete "${CLEANUP}"
      CLEANUP=''
    fi
  done

  CSTART=${RSTART}

  if [ "${FULL_CHECK}" = "YES" ];then
  JUNK=0
  else
    if [ "${ROW_CHECK}" = "NO" ];then
    merge_descrete
    fi
  fi

#  echo Monitors for row $RSTART $ARRAYS
  RSTART=$(($RSTART + 1))
  DESCRETE=''
  ROW_CHECK=''

  # add up all array values to find monitor count
  eval monitors=$((${ARRAYS} + $monitors))
done

#echo monitor count for all $monitors

if [ "${FULL_CHECK}" = "YES" ];then
  JUNK=0
else
  create_merge
fi
find /tmp/multi_wall_row* -delete &> /dev/null

   shopt -s nocasematch
   if [ ${1} = "instant" ];then
   # If we just want a single wallaper change to occur
   exit 0
   else
   # Sleep until it is time to change the wallaper again.
   sleep ${TIMER}
   shopt -u nocasematch
   fi

done

# If we ever get to here, something has gone REALLY wrong.
exit 1
