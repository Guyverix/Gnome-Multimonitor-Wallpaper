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

USERID1=`got_root`
if [[ "${USERID1}" == "root" ]];then
  echo "sudo is required only when running mate, this should be run as yourself (so we can find your home directory)"
  exit 1
else
  echo "Confirmed we are not running as root user... Continuing"; sleep .5
fi

USERID=$(whoami)

if [[ ! -d ~/.multi_wall ]];then
  mkdir ~/.multi_wall 2>&1 >/dev/null
  cp -R * ~/.multi_wall/
else
  echo "The .multi_wall directory already exists"
  echo "Not taking the chance of clobbering any customizing done"
  echo "Only will copy minimal files necessary"
  cp *.sh ~/.multi_wall/
  cp *.py ~/.multi_wall/
  cp wallpapers ~/.multi_wall/
  cp version ~/.multi_wall/
fi

# Setup should not need a lot of brains, and we do NOT want to
# screw with the users machine and possibly break things.
# Keep it simple!

# Assume that the user who is running setup will be the only one
# This will not damage other users of the system
if [[ ! -e /home/${USER}/.multi_wall/images.lst ]];then
  echo "Configure  /home/${USER}/.multi_wall/multi.cfg with the needed path for images and monitor resolutions"
  echo "See the README in the .multi_wall directory for details.  Additional examples are included in the directory"
  echo "or on github."
else
  echo "The images.lst file exists.  This is likely an update."
fi
sleep .5

if [[ ! -e /home/${USER}/.multi_wall/multi.cfg ]];then
  cp /home/${USER}/.multi_wall/EXAMPLES/multi_3_head_cfg_example /home/${USER}/.multi_wall/multi.cfg
  echo "No multi.cfg file was found.  Three headed config pulled from EXAMPLES directory to use"
fi

# If cinnamon is installed, get the pathing in there
if [[ -e ~/.cinnamon ]]; then
  echo "A Cinnamon config directory was found."
  # Here is where we add to the desktop menu ABILITY.  Do not turn on by default, thats just rude.
  if [[ ! -e ~/.local/share/applications/multiwall.desktop ]]; then
    cat multiwallpaper.desktop | sed "s/USERID/${USERID}/g" > ~/.local/share/applications/multiwall.desktop
    echo "Application has been added to the Menu as Multi_Wallpaper"
  fi

  if [[ $(grep -c multi_wall ~/.cinnamon/backgrounds/user-folders.lst) -eq 0 ]]; then
    echo "/home/${USER}/.multi_wall" >> ~/.cinnamon/backgrounds/user-folders.lst
    echo "Added .multi_wall to your background wallpapers path"
    echo "After indexing and running either start, or instant choose this path for your background.jpg file"
  fi
fi

# Check if Gnome - MATE installed via the gsettings existing or not
if [[ $(which gsettings) ]]; then
  echo "The gsettings binary was found.  Updating gnome - mate settings"
  gsettings set org.gnome.desktop.background picture-uri "file:///home/${USER}/.multi_wall/background.jpg"
fi

# cinnamon, mate, and XFCE all use this same spec
# https://askubuntu.com/questions/63407/where-are-startup-commands-stored
if [[ ! -e ~/.config/autostart ]]; then
  mkdir ~/.config/autostart
fi

if [[ ! -e ~/.config/autostart/multiwallpaper.desktop ]] ; then
  cat multiwallpaper.desktop | sed "s/USERID/${USERID}/g" > ~/.config/autostart/multiwallpaper.desktop
  echo "Application is set to start on login but not change wallpapers"
fi

if [[ ! $(which identify) ]]; then
  echo "For courtesey, this script does not install random packages"
  echo "Please install ImageMagick via: sudo apt install imagemagick"
fi

# Check if XFCE installed
# Run anything special that we might need here

echo "Setup complete"; exit 0
