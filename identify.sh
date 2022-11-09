#!/bin/bash

#===  FUNCTION  ================================================================
#          NAME:  logger
#   DESCRIPTION:  create log ilfe
#    PARAMETERS:  severity, message
#       RETURNS:  NONE
#===============================================================================
logger() {
# Logging basics
OUT_FILE=${LOCATION}/multi_wallpapers.log

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
echo -e "${LDATE} ${SEV} - $0 - ${STR}" >> ${OUT_FILE}

}


# Set our defaults here
LOCATION=/home/${USER}/.multi_wall

# Make sure we have a valid config file or die
if [ -e ${LOCATION}/multi.cfg ];then
  . ${LOCATION}/multi.cfg
else
  logger "FATAL" "Unable to find file ${LOCATION}/multi.cfg"
  exit 1
fi

# full path and image name we are processing
IMAGE="${1}"

# DEST is a temp file that we are creating with the list
# This is in case it is needed in the future.  Currently not
# called from multi_update.sh
if [[ ! -z ${2} ]]; then
  DEST="${2}"
else
  DEST="${LOCATION}/images_full.lst"
fi

SIZE=$(identify "${IMAGE}" 2>/dev/null | awk '{print $3}')
if [[ ! -z "${SIZE}" ]];then
  X_CHECK=$(echo ${SIZE} | awk -F'x' '{print $1}')
  Y_CHECK=$(echo ${SIZE} | awk -F'x' '{print $2}')
  if [ ${X_CHECK} -gt ${SIZE_X} -a ${Y_CHECK} -gt ${SIZE_Y} ];then
     echo "'${IMAGE}' '${SIZE}'" >> ${DEST}
  else
    logger "DEBUG" "Image ${IMAGE} with size ${SIZE} is too small.  Needs to be greater than ${SIZE_X}x${SIZE_Y}"
  fi
fi
exit 0
