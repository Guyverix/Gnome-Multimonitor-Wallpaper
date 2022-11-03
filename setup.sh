#!/bin/bash


#===  FUNCTION  ================================================================
#          NAME:  got_root
#   DESCRIPTION:  Confirm that this is being run as root. 
#    PARAMETERS:  None
#       RETURNS:  echos if root user (or sudo was used)
#===============================================================================
got_root() {
if [ "$(id -u)" != "0" ]; then
  echo "safe"
else
  echo "root"
fi
}

# Set default

USERID=`got_root`
if [ "${USERID}" == "root" ];then
  echo "sudo is not required, this should be run as yourself (so we can find your home directory)"
  exit 1
else
  echo "Confirmed we are not running as root user... Continuing"; sleep .5
fi

if [ ! -e "~/.multi_wall" ];then
  mkdir ~/.multi_wall
  cp -R * ~/.multi_wall/
else
  echo "The .multi_wall directory already exists"
  echo "Not taking the chance of clobbering any customizing done"
fi

# Setup should not need a lot of brains, and we do NOT want to
# screw with the users machine and possibly break things.
# Keep it simple!

# Assume that the user who is running setup will be the only one
# This will not damage other users of the system
if [ ! -e /home/${USER}/.multi_wall/images.lst ];then
  echo "Configure  /home/${USER}/.multi_wall/multi.cfg with the needed path for images and monitor resolutions"
  echo "See the README in the .multi_wall directory for details.  Additional examples are included in the directory"
  echo "or on github."
else
  echo "The images.lst file exists.  This is likely an update."
  echo "The file copy needs to be done manually so we do not clobber"
  echo "files such as images.lst and multi.cfg"
fi
sleep .5

# Here is where we add to the desktop autorun (if we can figure out how)
cat multiwallpaper.desktop | sed "s/USERID/${USERID}/g" > ~/.config/autostart/multiwallpaper.desktop
echo "Application is set to start on login"

echo "Setup complete"; exit 0


