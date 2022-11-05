#!/bin/bash
#===============================================================================
#
#          FILE:  multi_wallpapers.sh
#
#         USAGE:  ./multi_wallpapers.sh
#
#   DESCRIPTION:  This script is intended to create dual, side by side wallpaper
#                 for Linux systems running Gnome or XFCE and want random different
#                 wallpapers on each monitor.  It will do more, but it has not
#                 been deeply tested.
#       OPTIONS:  none
#  REQUIREMENTS:  Basic conf file and index file.  Resolutions are expected to
#                 be the same at the moment. xrandr is helpful, and imagemagick
#                 is manditory for this to work correctly.
#          BUGS:  None known
#         NOTES:  ---
#        AUTHOR:  Christopher S. Hubbard (), guyverix@yahoo.com
#       COMPANY:  I Will Fear No Evil DOT com
#       VERSION:  2.0.0
#       CREATED:  03/04/2011 07:27:43 PM PST
#      REVISION:  Francine
#===============================================================================

usage() {
cat<<EOF
Usage: $0 option
This script will fire off a set of commands that will change the background wallpapers
of the given system.  It is smart enough to know if we are running XFCE or Gnone and 
use the correct set of commands to do the changes.  It is important to note however that
while this works well for Gnome, XFCE currently only fully supports a single row of 
monitors that are on the same "X" screen.

Options:
Help      - Show this help screen
New       - Reindex all of the wallpaper images
Update    - Look for new wallpapers in the storage directory
Randomize - Randomize the index of all the wallpapers
instant   - Do only a single change and exit
*         - Any other arg will show this screen
EOF
}

#===  FUNCTION  ================================================================
#          NAME:  logger
#   DESCRIPTION:  create log ilfe
#    PARAMETERS:  severity, message
#       RETURNS:  NONE
#===============================================================================
logger() {
local SEV=$1
local STR=$2
if [[ -z ${STR} ]]; then
  STR="No details given"
fi
# If the file does not exist, simply touch it
if [[ ! -e ${OUT_FILE} ]]; then
  touch ${OUT_FILE}
fi

# Make sure our output is uniform.  Why look sloppy?
local SEV=$(echo "${SEV}" | tr [:lower:] [:upper:])

local LDATE=$(date "+%F %H:%M:%S")

# Set our output now into our "logfile"
echo -e "${LDATE} ${SEV} - ${STR}" >> ${OUTFILE}

}

#===  FUNCTION  ================================================================
#          NAME:  full_spanner
#   DESCRIPTION:  Check if an image is large enough to be considered "spanning"
#    PARAMETERS:  global span sizes
#       RETURNS:  YES/NO
#===============================================================================
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

#===  FUNCTION  ================================================================
#          NAME:  row_spanner
#   DESCRIPTION:  Check if an image is large enough to span a row of monitors
#    PARAMETERS:  row span size
#       RETURNS:  YES/NO
#===============================================================================
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


#===  FUNCTION  ================================================================
#          NAME:  grab_image
#   DESCRIPTION:  Choose the image we are going to use
#    PARAMETERS:  
#       RETURNS:  Absolute path to the image
#===============================================================================
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
    if [ -z ${counts} ];then
      counts=0
    fi
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

#===  FUNCTION  ================================================================
#          NAME:  create_full_span
#   DESCRIPTION:  use convert blow up the image
#    PARAMETERS:  globals
#       RETURNS:  none
#===============================================================================
create_full_span() {
  #echo create full span
  local fin_image=`echo ${FULL_SPAN} | awk '{print $1}' | sed "s/'//g"`
  #nice  convert ${fin_image} -gravity "${GRAVITY_SPAN}" -background ${BG_COLOR} -resize ${SPAN_SIZE_RT} ${LOCATION}/background.jpg
#NORMAL  convert ${fin_image} -background ${BG_COLOR} -resize ${SPAN_SIZE_RT} ${LOCATION}/background.jpg
  convert ${fin_image} -background ${BG_COLOR} -resize ${SPAN_SIZE_RT}\! ${LOCATION}/background.jpg #ignore aspect ratio using bang
  if [ "${WIN_MANAGER}" == "GNOME" ];then
    gconftool-2 --set "/desktop/gnome/background/picture_options" --type string "spanned"
  elif [ "${WIN_MANAGER}" == "MATE" ];then
    # useful options stretched spanned tiled
    gsettings set org.mate.background picture-options 'spanned'
    dconf write /org/mate/desktop/background/picture-filename "\"${LOCATION}/background.jpg\""
  else
    gsettings set org.gnome.desktop.background picture-options 'spanned'
  fi

}


#===  FUNCTION  ================================================================
#          NAME:  create_row_span
#   DESCRIPTION:  use convert blow up the image
#    PARAMETERS:  globals
#       RETURNS:  none
#===============================================================================
create_row_span() {
  #echo create row span ${RSTART}
  local row_span=${RSTART}
  eval row_size='$SPAN_SIZE_R'${RSTART}
  local fin_image=`echo ${ROW_SPAN} | awk '{print $1}' | sed "s/'//g"`
  #nice  convert ${fin_image} -background ${BG_COLOR} -gravity "${GRAVITY1}" -resize ${row_size}  -extent ${row_size} /tmp/multi_wall_row_${row_span}.jpg
  convert ${fin_image} -background ${BG_COLOR} -gravity "${GRAVITY1}" -resize ${row_size}  -extent ${row_size} /tmp/multi_wall_row_${row_span}.jpg
}

#===  FUNCTION  ================================================================
#          NAME:  create_descrete
#   DESCRIPTION:  Create a row of descrete images
#    PARAMETERS:  globals
#       RETURNS:  none
#===============================================================================
create_descrete() {
  #echo  create descrete row ${RSTART}
  local row_span=${RSTART}
  local fin_image=${CLEANUP}
  local j=$i
  eval row_size='${R'${RSTART}'_['$j']}'
  #  nice  convert ${fin_image} -background ${BG_COLOR} -gravity "${GRAVITY1}" -resize ${row_size} -extent ${row_size} /tmp/multi_wall_row_${row_span}_${i}.jpg
  convert ${fin_image} -background ${BG_COLOR} -gravity "${GRAVITY1}" -resize ${row_size} -extent ${row_size} /tmp/multi_wall_row_${row_span}_${i}.jpg
}

#===  FUNCTION  ================================================================
#          NAME:  merge_descrete
#   DESCRIPTION:  take two rows of images and glue them together
#    PARAMETERS:  globals
#       RETURNS:  none
#===============================================================================
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
  #nice  convert ${fin_image} -background ${BG_COLOR} -gravity "${GRAVITY1}" ${orentation}append /tmp/multi_wall_row_${row_span}.jpg
  convert ${fin_image} -background ${BG_COLOR} -gravity "${GRAVITY1}" ${orentation}append /tmp/multi_wall_row_${row_span}.jpg
}

#===  FUNCTION  ================================================================
#          NAME:  create_merge
#   DESCRIPTION:  Figure out orentation and append conversions and add wallpaper
#    PARAMETERS:  globals
#       RETURNS:  none
#===============================================================================
create_merge() {
  if [ "${WIN_MANAGER}" == "XFCE" ];then
    FOO=0
  else
    #echo create merge! Gnome/Cinnamon only
    if [ "${ORIENT}" == "horizontal" ];then
      local merge="-"
    else
      local merge="+"
    fi
    for row_counts in `seq 1 ${ROWS}`;do
      local images="${images} /tmp/multi_wall_row_${row_counts}.jpg"
    done
    local row_size=${SPAN_SIZE_RT}
    #nice  convert ${images} -background ${BG_COLOR} -gravity "${GRAVITY1}" ${merge}append ${LOCATION}/background.jpg
    convert ${images} -background ${BG_COLOR} -gravity "${GRAVITY1}" ${merge}append ${LOCATION}/background.jpg
    if [ "${WIN_MANAGER}" == "GNOME" ];then
      gconftool-2 --set "/desktop/gnome/background/picture_options" --type string "spanned"
      gconftool-2 -t string -s /desktop/gnome/background/picture_filename ${LOCATION}/background.jpg
    elif [ "${WIN_MANAGER}" == "MATE" ];then
      gsettings set org.mate.background picture-options 'spanned'
      dconf write /org/mate/desktop/background/picture-filename "\"${LOCATION}/background.jpg\""
    elif [ "${WIN_MANAGER}" == "CINNAMON" ];then
      gsettings set org.gnome.desktop.background picture-options 'spanned'
      gsettings set org.gnome.desktop.background picture-uri file://"${LOCATION}/background.jpg"
    else
      # Catchall for fallthough (if XFCE manages to get here)
      FOO=0
    fi
  fi
}


#===  FUNCTION  ================================================================
#          NAME:  xfce_stretch
#   DESCRIPTION:  Check if we should scale or stretch the image based on math
#    PARAMETERS:  global
#       RETURNS:  integer
#===============================================================================
xfce_stretch() {
## This needs more testing, as the ratios can get really weird.  A better sanity
## check for this would also be helpful.

# Set picture $1 as desktop background
  # 0 - Auto
  # 1 - Centered
  # 2 - Tiled
  # 3 - Stretched
  # 4 - Scaled
  # 5 - Zoomed

local imageStlye='4'
local monit="1.7777"
local ratio="90"
local compare=`echo "${1}" | sed 's|x| / |'`
local check=`echo "scale=4; ${compare}" | bc`
local verify=`echo "scale=4; (${compare} * 100) / ${monit}" | bc`

if [[ `echo "${verify} > ${ratio}" | bc` -gt 0 ]] && [[ `echo "${verify} < 1.9" | bc` -gt 0 ]] ;then
  echo "3"
elif [[ `echo "scale=2; ${check} == 1.333" | bc` -gt 0 ]];then
  echo "3"
else
  echo "4"
fi

}

#===  FUNCTION  ================================================================
#          NAME:  xfce_only
#   DESCRIPTION:  change wallpaper in xfce style
#    PARAMETERS:  globals
#       RETURNS:  none
#===============================================================================
xfce_only() {

# Monitor #1
local RAW1="$(grab_image)"
local SIZE1=`echo "${RAW1}" | awk '{print $NF}' | sed "s|['\]||g"`
local STYLE1="$(xfce_stretch ${SIZE1})"
local WP1=`echo "${RAW1}" | awk '{print $1}' | sed "s|['\]||g"`
xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor1/image-style -s ${STYLE1}
xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor1/image-path -s "${WP1}" 2> /dev/null

# Monitor #0
local RAW2="$(grab_image)"
local SIZE2=`echo "${RAW2}" | awk '{print $NF}' | sed "s|['\]||g"`
local STYLE2="$(xfce_stretch ${SIZE2})"
local WP2=`echo $(grab_image) | awk '{print $1}' | sed "s|['\]||g"`
xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/image-style -s ${STYLE2}
xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/image-path -s "${WP2}" 2> /dev/null
}


#===  FUNCTION  ================================================================
#          NAME:  xfce_span
#   DESCRIPTION:  Configure a wallpaper to span n+1 monitors
#    PARAMETERS:  globals
#       RETURNS:  none
#===============================================================================
xfce_span() {
local RAW1="$(grab_image)"
local SIZE1=`echo "${RAW1}" | awk '{print $NF}' | sed "s|['\]||g"`
local SIZE_X=`echo "${SIZE1}" | awk -F 'x' '{print $1}'`
local SIZE_Y=`echo "${SIZE1}" | awk -F 'x' '{print $2}'`

if [[ ${SIZE_X} -ge ${R1_SIZE_SPAN_X} ]] && [[ ${SIZE_Y} -ge ${R1_SIZE_SPAN_Y} ]];then
  local STYLE1="$(xfce_stretch ${SIZE1})"
  local WP1=`echo "${RAW1}" | awk '{print $1}' | sed "s|['\]||g"`
  xfconf-query -c xfce4-desktop -p /backdrop/screen0/xinerama-stretch -s true
  xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/image-style -s ${STYLE1}
  xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/image-path -s "${WP1}" 2> /dev/null
else
  # We only check once for a spanner, then default to split
  xfconf-query -c xfce4-desktop -p /backdrop/screen0/xinerama-stretch -s false
  xfce_only
fi
}

#===============================================================================
#  Do basic validations and then get arguments
#===============================================================================
LOCATION=/home/${USER}/.multi_wall

# Logging basics
FIL=$(echo "$0" | awk -F '/' '{print $NF}' | sed 's/\.sh/\.log/')
OUT_FILE=${LOCATION}/${FIL} ; touch ${OUT_FILE}

if [ -e ${LOCATION}/multi.cfg ];then
  . ${LOCATION}/multi.cfg
else
  echo "Please create the configuration file: \"${LOCATION}/multi.cfg\" "
  exit 1
fi

if [ ! -e ${LOCATION}/images.lst ];then
  echo "Indexing images found in the path defined in config file"
  echo "This may take awhile depending on image counts"
  nice nohup ${LOCATION}/multi_update.sh New >/dev/null &
  ln -s ${LOCATION}/images_full.lst ${LOCATION}/images.lst
  echo "Wait a few seconds and run again"; exit 2
fi

# See if we are running XFCE or Gnome
X_SESSION=`ps aux | grep X11/x[i]nit | grep -c xfce`
if [ ${X_SESSION} -gt 0 ]; then
  WIN_MANAGER='XFCE'
elif [ `ps aux | grep -c '[c]innamon-session'` -gt 0 ];then
  WIN_MANAGER='CINNAMON'
elif [ $(ps uax | grep -c '[m]ate-session') -gt 0 ];then
  WIN_MANAGER='MATE'
else
  WIN_MANAGER='GNOME'
fi

shopt -s nocasematch

case ${1} in
  N|Ne*)  nice nohup ${LOCATION}/multi_update.sh New &> /dev/null; exit 0    ;;
  U|Upd*) nice nohup ${LOCATION}/multi_update.sh Update &> /dev/null; exit 0    ;;
  R|Ran*) nohup ${LOCATION}/multi_update.sh Random &> /dev/null; exit 0    ;;
  -h|h|H|Hel*) usage;  exit 1    ;;
  *)      # Allow anyhthing, as Instant is not defined here (yet)    ;;
esac
shopt -u nocasematch


#===============================================================================
#  Begin application loop
#===============================================================================
while true; do
  monitors=0
  RSTART=1

#===============================================================================
# error correction and definition if there is only 
# one row of monitors
#===============================================================================
  if [ "${ROWS}" -eq "1" ];then
    RT_SIZE_SPAN_X=${R1_SIZE_SPAN_X}
    RT_SIZE_SPAN_Y=${R1_SIZE_SPAN_Y}
  fi

#===============================================================================
# Decide if we are dealing with XFCE or not.  Keep it simple for XFCE as there
# are not as many active options currently
#===============================================================================
  if [ ${WIN_MANAGER} = 'XFCE' ];then
    xfce_span
  else
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
    if [ ! "${FULL_CHECK}" = "YES" ];then
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
  fi

  #echo monitor count for all $monitors
  if [[ ! "${FULL_CHECK}" = "YES" ]] && [[ ! "${XFCE}" == "TRUE" ]] ;then
    create_merge
  fi

  find /tmp/multi_wall_row* -delete &> /dev/null

  shopt -s nocasematch
  if [[ "${1}" = "instant" ]] || [[ -z "${1}" ]];then
    # If we just want a single wallaper change to occur
    exit 0
  else
    # Sleep until it is time to change the wallaper again.
    sleep ${TIMER}
    shopt -u nocasematch
  fi
done

# If we ever get to here, something has gone REALLY wrong.
echo "Fatal error.  Exit now"; exit 1

