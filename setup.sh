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

USERID=`got_root`
if [ "${USERID}" == "root" ];then
  echo "While sudo is required, this should be run as yourself (so we can find your home directory)"
  exit 1
else
  echo "Confirmed we are not running as root user... Continuing"; sleep .5
fi

# Setup should not need a lot of brains, and we do NOT want to screw with the users machine and possibly break things.
# Keep it simple!

# Make a common path.  This will change later after code consolidation happens.  Those changes will not hurt things.
# So even though this is not a good idea (what happens with more than one user?) this will not damage the machine.
if [ ! -e /usr/local/bin/wallpapers ];then
  echo "Creating symlink wallpapers in /usr/local/bin"
  sudo ln -s /home/${USER}/.multi_wall/multi_wallpapers.sh /usr/local/bin/wallpapers
else
  echo "Symlink /usr/local/bin/wallpapers already exists."
fi
sleep .5

# Assume that the user who is running setup will be the only one
if [ ! -e /home/${USER}/.multi_wall/images.lst ];then
  echo "Configure  /home/${USER}/.multi_wall/multi.cfg with the needed path for images and monitor resolutions"
  echo "See the README in the .multi_wall directory for details.  Additional examples are included in the directory"
else
  echo "The images.lst file exists.  This is likely an update."
fi
sleep .5

echo "Setup complete"; exit 0


