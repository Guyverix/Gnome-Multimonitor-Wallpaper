# Multi Monitor Wallpaper changer

These scripts make a wallpaper changer via the system tray.  It is intended for Gnome like systems (MATE and
Cinnimon specifically) as well as XFCE desktops.  The project has grown a bit from 2011 when it was a simple set of
bash scripts for my six headed display.  There is now a desktop icon to do much of the same functionality
in a nicer way.

The intent is to change X number of wallpapers on your desktop, and while most desktop managers have an
option for a "slideshow" like change, they do not support the concept of independent wallpapers per monitor
and then spanning a giant one acrosss all monitors if it meets certain criteria.

The system supports multiple rows of monitors in either a horozontal or vertical configuration.  Normally users
will only have a single row of two or three, but the ability is there for other configurations as well.

Features
--------

- Daemon control
- Image indexing both complete and delta
- Multiple rows of monitors supported
- Multiple numbers of monitors supported.
- Horizontal or Vertical row orentations supported
- Gnome, XFCE, Cinnamon, MATE are supported

Overall the load is minimal on changing wallpapers with one exception.  Since this is using ImageMagick if you
are going to create a "spanning" wallpaper, it can take 15-20 seconds for the resizing work to complete.  While
this is happening, it will increase the load on your system, however it is niced down a bit so an end user should
not really notice this.

The desktop system currently supports Start / Restart / Stop / Instant Change / Rebuild Index / Update Index from
the system tray.  The ability is there to also edit your configuration file for timers on when you want changes to
occur, or to change from sequential to random styles.

Installation
------------

- clone the repository and then run the setup script.  
  - It will create a .multi_wall directory in your HOME path and set the system tray, as well as add a menu item.
- Start the Multi_Wallpaper from the menu, and go into Customize >> Edit Config File.
  - Set your INDEX value to where your wallpapers reside on your hard drive.
    - You CAN set as "dir1 dir2 dir3" if they are spread out on your system.
  - From there edit the R1_[#] values with what your monitor resolutions are.  Note that this starts at zero, and not one for the number of monitors.
- Set your SPAN_SIZE_R1 to the sum of all X values so we know how wide your monitor "set" is.
  - set your SPAN_SIZE_RT to be the same value as SPAN_SIZE_R1 if you only have a single row of monitors.  If there are
two rows, then add in the Y values between the two rows and set that here.  This may need some tweaks to get the span across
rows to look nice, due to different resolutions making things look a bit different.  The script will attempt to clip in the event
of a mismatch in resoltuions so the result should look ok overall.
- Setting the R1_SIZE_SPAN_X/Y Values is so we know how big the user wants something to be before it considers the
wallpaper a "spanning" wallpaper.
- The same logic follows for the RT_SIZE_SPAN_X/Y values.
- The GRAVITY values are how we are going to center the wallpapers.  
  - This is used, as we are not generally going to alter the aspect ratio of the wallpaper as they can look horribly deformed if the change is too great.  So this
system will simply change the size while keeping the ratio intact.  Gravity is where in the canvas the image is placed.
- Then the BG_COLOR is used for all areas that are not covered up by the image.
  - You can use different colors, or HEX codes with the ImageMagick convert utility, so you can do interesting affects.
- The REFRESH value is for when you are updating your image list.  
  - It tells the daemon to look this many days back in time and add all the images that are found into your index.  This is used when there are a large number of wallpapers and the
user is not interested in doing a complete rescan of all the image files.
- SEARCH is used to configure the auto change and instant systems to either pull the images sequentially from the list
or just grab random images out of the complete list of images.
- AUTOSTART is where the user can define if they want changing wallpapers on startup of the system tray script, or simply
have the system be idle so the user can enable at their leasure.
- The other options have a basic description in the multi.cfg file and should be mostly self explanitory


Scripts Included
----------------

- multi_update.sh
  * Changes done to the images.lst file are controlled by this script.
  * Args it takes new, update and randomize

- multi_wallpapers.sh
  * Main daemon that communicates with the support scripts and runs the daemon process itself.

- wallpapers
  * Primary script used to control the other scripts in a simple way.
  * In normal operation this is the script that is called to do "something" within the application

- identify.sh
  * This is used to find the size of the wallpapers and add the information into the index file.  This keeps the speed up when requesting changes as it does not need to calculate the wallpapers every time it is run.

- setup.sh
  * This is a bare-bones installer.  It will install to /home/USER/.multi_wall, as well as adding the .desktop files to enable the system tray and menu items to the system.
  * Installation does NOT need sudo and gets grouchy if you do use it. :P

- wallpapers_wrapper.py
  * This is the actual script that runs the applet in the system tray.  This wrapper calls the wallpapers script with the commands you give it from the GUI
  * Important note about the applet script.  I am not a (real) developer.  I took the Kinto python script from this project ![Python Source](https://github.com/rbreaves/kinto) and used it as a template on how to make a usable applet.  Thankfully his work was nice and straightforward or I never would have figured out how to make a reliable system.  If you want to make a nice and easy applet yourself follow what he has done for Kinto as it just works.

- multi.cfg
  * The configuration file necessary to make the wallpapers look good



