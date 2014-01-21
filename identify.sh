#!/bin/bash



LOCATION=/home/${USER}/.multi_wall
# Make sure we have a valid config file or die
if [ -e multi.cfg ];then
  . ${LOCATION}/multi.cfg
else
  exit 1
fi

IMAGE="${1}"
SIZE=`identify "${IMAGE}" 2>/dev/null | awk '{print $3}'`
#SIZE=`identify -verbose "${IMAGE}" | grep 'Geometry:' | sed 's/.*://' | sed 's/+.*//' | sed 's/[ ]//g'`
if [ -n "${SIZE}" ];then
  X_CHECK=`echo ${SIZE} | awk -F'x' '{print $1}'`
  Y_CHECK=`echo ${SIZE} | awk -F'x' '{print $2}'`
  if [ ${X_CHECK} -gt ${SIZE_X} -a ${Y_CHECK} -gt ${SIZE_Y} ];then
     echo "'${IMAGE}' '${SIZE}'" >> ${LOCATION}/images_full.lst
  fi
fi
exit 0
