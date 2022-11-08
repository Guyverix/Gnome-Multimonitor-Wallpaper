#!/usr/bin/env python3

import gi

gi.require_version('Gtk', '3.0')
gi.require_version('AppIndicator3', '0.1')
gi.require_version('Notify', '0.7')

import signal,time,os,fcntl,datetime,re
from subprocess import Popen, PIPE, CalledProcessError
from shutil import which
from gi.repository import Gtk,GLib,GdkPixbuf
from gi.repository import AppIndicator3 as appindicator
from gi.repository import Notify as notify

import signal

def kill_child():
    if child_pid is None:
        pass
    else:
        os.kill(child_pid, signal.SIGTERM)

import atexit
atexit.register(kill_child)

APPINDICATOR_ID = 'Multiwall'

class Indicator():

    global child_pid
    multi_wall_status = Popen("export TERM=xterm-color;while :; do clear; pgrep -fx '/bin/bash " + os.environ['HOME']+ "/.multi_wall/multi_wallpapers.sh start' && echo 'active'; sleep 2; done", stdout=PIPE, shell=True)
    child_pid = multi_wall_status.pid

    homedir = os.path.expanduser("~")
    kconfig = homedir+"/.multi_wall/multi.cfg"
    ostype = os.environ.get('XDG_CURRENT_DESKTOP')

    enable_id = 0
    winmac_id = 0
    chkautostart_id = 0
    autostart_bool = False
    menu = Gtk.Menu()

    restart = Gtk.MenuItem(label='Restart')
    stop = Gtk.MenuItem(label='Stop')
    instant = Gtk.MenuItem(label='Single Change')
    new = Gtk.MenuItem(label='Rebuild image index')
    update = Gtk.MenuItem(label='Update image index')

    edit = Gtk.MenuItem(label='Customize')
    edit_submenu = Gtk.Menu()
    edit.set_submenu(edit_submenu)

    button_config = Gtk.MenuItem(label='Edit Config file')
    about = Gtk.MenuItem(label='About')

    helpm = Gtk.MenuItem(label='Help')
    help_submenu = Gtk.Menu()
    helpm.set_submenu(help_submenu)

    support = Gtk.MenuItem(label='Support')
    checkbox_autostart = Gtk.CheckMenuItem(label='Autostart')

    global restartsvc
    restartsvc = False
    unixts = int(time.time())
    last_status = ''

    def __init__(self):
        # Initialize our watchdog to see if the daemon is running
        res = Popen(['pgrep', '-fx', '/bin/bash ' + os.environ['HOME']+ '/.multi_wall/multi_wallpapers.sh start'])
        res.wait()

        if res.returncode == 0:
            self.last_status = 'active'
            self.indicator = appindicator.Indicator.new(APPINDICATOR_ID, os.environ['HOME']+'/.multi_wall/images/multi-happy.png', appindicator.IndicatorCategory.SYSTEM_SERVICES)
        else:
            self.last_status = 'inactive'
            self.indicator = appindicator.Indicator.new(APPINDICATOR_ID, os.environ['HOME']+'/.multi_wall/images/multi-sleep.png', appindicator.IndicatorCategory.SYSTEM_SERVICES)

        self.indicator.set_status(appindicator.IndicatorStatus.ACTIVE)
        self.indicator.set_menu(self.build_menu(res))
        notify.init(APPINDICATOR_ID)

        GLib.timeout_add(2000, self.update_terminal)

    def build_menu(self,res):
        # Pull from our config file if we are running the initial startup or sitting idle
        autostart_line = str(Popen("grep '^AUTOSTART' " + os.environ['HOME']+'/.multi_wall/multi.cfg', stdout=PIPE, shell=True).communicate()[0].strip().decode('UTF-8'))

        if autostart_line == "AUTOSTART=true":
            autostart_bool = True
        else:
            autostart_bool = False

        if autostart_bool:
            # If True, start daemon
            Popen([os.environ['HOME']+'/.multi_wall/wallpapers', 'start'])
            self.checkbox_autostart.set_active(True)
            self.chkautostart_id = self.checkbox_autostart.connect('activate',self.setAutostart,False)
        else:
            self.checkbox_autostart.set_active(False)
            self.chkautostart_id = self.checkbox_autostart.connect('activate',self.setAutostart,True)

        self.restart.connect('activate',self.runRestart)
        self.menu.append(self.restart)
        self.stop.connect('activate',self.runStop)
        self.menu.append(self.stop)

        self.instant.connect('activate',self.runInstant)
        self.menu.append(self.instant)

        self.new.connect('activate',self.runNew)
        self.menu.append(self.new)

        self.update.connect('activate',self.runUpdate)
        self.menu.append(self.update)

        self.button_config.connect('activate',self.setConfig)
        self.edit_submenu.append(self.button_config)
        self.edit_submenu.append(self.checkbox_autostart)

        self.menu.append(self.edit)

        self.about.connect('activate',self.runAbout)
        self.help_submenu.append(self.about)
        self.support.connect('activate',self.openSupport)
        self.help_submenu.append(self.support)
        self.menu.append(self.helpm)

        item_quit = Gtk.MenuItem(label='Close')
        item_quit.connect('activate', quit)
        self.menu.append(item_quit)
        self.menu.show_all()

        return self.menu


    def checkTray(self,button,tray_bool):
        # make very sure that the .autostart directory exists, as this does not make the directory
        if tray_bool:
            Popen(['cp',os.environ['HOME']+'/.multi_wall/wallpapers_wrapper.py',os.environ['HOME']+'/.multi_wall/.autostart/wallpapers_wrapper.py'])
            self.systray.disconnect(self.systray.signal_id)
            self.systray.set_active(True)
            self.systray.signal_id = self.systray.connect('activate',self.checkTray,False)
        else:
            Popen(['rm',os.environ['HOME']+'/.multi_wall/.autostart/wallpapers_wrapper.py'])
            Gtk.main_quit()
            self.systray.disconnect(self.systray.signal_id)
            self.systray.set_active(False)
            self.systray.signal_id = self.systray.connect('activate',self.checkTray,True)
        return

    def runRestart(self,button):
        try:
            stop = Popen([os.environ['HOME']+'/.multi_wall/wallpapers', 'stop'])
            stop.wait()
            time.sleep(1)
            res = Popen(['pgrep', '-fx', '/bin/bash ' + os.environ['HOME']+'/.multi_wall/multi_wallpapers.sh start'])
            res.wait()
            if res.returncode == 0:
                pkillxkey = Popen(["ps aux | grep '[m]ulti_wallpapers.sh start' | awk '{print $2}' | xargs kill -9"])
                pkillxkey.wait()
            Popen([os.environ['HOME']+'/.multi_wall/wallpapers', 'start'])
        except:
            Popen(['notify-send','Multiwallpaper: Error restarting Multi-Wallpapers!'])

    def runInstant(self,button):
        try:
          instant = Popen([os.environ['HOME']+'/.multi_wall/wallpapers', 'instant'])
          instant.wait()
        except:
          Popen(['notify-send','Multiwallpaper: Error running instant single wallpaper change'])

    def runNew(self,button):
        try:
          Popen(['notify-send','Multiwallpaper: Reindexing ALL images this will take some time'])
          new = Popen([os.environ['HOME']+'/.multi_wall/wallpapers', 'new'])
          new.wait()
        except:
          Popen(['notify-send','Multiwallpaper: Reindexing ALL images failed'])

    def runUpdate(self,button):
        try:
          Popen(['notify-send','Multiwallpaper: Attempting to find newer images'])
          update = Popen([os.environ['HOME']+'/.multi_wall/wallpapers', 'update'])
          update.wait()
        except:
          Popen(['notify-send','Multiwallpaper: Searching for updated images failed'])

    def runStop(self,button):
        try:
            stop = Popen([os.environ['HOME']+'/.multi_wall/wallpapers', 'stop'])
            stop.wait()
            time.sleep(1)
            res = Popen(['pgrep', '-fx', '/bin/bash ' + os.environ['HOME']+'/.multi_wall/multi_wallpapers.sh start'])
            res.wait()
            if res.returncode == 0:
                Popen(['notify-send','Multiwall: Stop command failed.  Killing with napalm next'])
                pkillxkey = Popen(["ps aux | grep '[m]ulti_wallpapers.sh start' | awk '{print $2}' | xargs kill -9"])
                pkillxkey.wait()
        except:
            Popen(['notify-send','Multiwallpaper: Error stopping Multi-Wallpapers! find the damn exception that pgrep missed'])


    def setConfig(self,button):
    # All editors MUST be GUI editors, not terminal ones.  No nano, vi, vim
        try:
            if os.path.exists('/opt/sublime_text/sublime_text'):
                Popen(['/opt/sublime_text/sublime_text',os.environ['HOME']+'/.multi_wall/multi.cfg'])
            elif which('gvim') is not None:
                Popen(['gvim',os.environ['HOME']+'/.multi_wall/multi.cfg'])
            elif which('gedit') is not None:
                Popen(['gedit',os.environ['HOME']+'/.multi_wall/multi.cfg'])
            elif which('mousepad') is not None:
                Popen(['mousepad',os.environ['HOME']+'/.multi_wall/multi.cfg'])
            elif which('kate') is not None:
                Popen(['kate',os.environ['HOME']+'/.multi_wall/multi.cfg'])
            elif which('kwrite') is not None:
                Popen(['kwrite',os.environ['HOME']+'/.multi_wall/multi.cfg'])
            elif which('xed') is not None:
                Popen(['xed',os.environ['HOME']+'/.multi_wall/multi.cfg'])
            else
                Popen(['notify-send','Multiwall: Error could not open config file multi.cfg with any known editor'])
        except CalledProcessError:                                  # Notify if we cannot edit multi.cfg for some reason
            Popen(['notify-send','Multiwall: Error could not open config file multi.cfg with any known editor'])


    def setAutostart(self,button,autostart):
        try:
            if autostart == False:
                Popen(['perl','-pi','-e','s/AUTOSTART=true/AUTOSTART=false/g',os.environ['HOME']+'/.multi_wall/multi.cfg'])
                self.checkbox_autostart.set_active(False)
                self.checkbox_autostart.disconnect(self.chkautostart_id)
                self.chkautostart_id = self.checkbox_autostart.connect('activate',self.setAutostart,True)
            else:
                Popen(['perl','-pi','-e','s/AUTOSTART=false/AUTOSTART=true/g',os.environ['HOME']+'/.multi_wall/multi.cfg'])
                self.checkbox_autostart.set_active(True)
                self.checkbox_autostart.disconnect(self.chkautostart_id)
                self.chkautostart_id = self.checkbox_autostart.connect('activate',self.setAutostart,False)
        except CalledProcessError:
            Popen(['notify-send','Multiwallpaper: Error setting autostart!'])


    def update_terminal(self):
        status = self.non_block_read().strip()
        nowts = int(time.time())
        multiwall_icon_desc = "Multiwall"
        if (nowts - self.unixts) > 5 and (status=='active' and self.indicator.get_icon() != os.environ['HOME']+'/.multi_wall/images/multi-happy.png'):
            self.indicator.set_icon_full(os.environ['HOME']+'/.multi_wall/images/multi-happy.png', multiwall_icon_desc)
        elif (nowts - self.unixts) > 5 and (status == 'inactive' and self.indicator.get_icon() != os.environ['HOME']+'/.multi_wall/images/multi-sleep.png'):
            self.indicator.set_icon_full(os.environ['HOME']+'/.multi_wall/images/multi-sleep.png', multiwall_icon_desc)
        self.last_status = status
        return self.multi_wall_status.poll() is None

    def openSupport(self,button):
        Gtk.show_uri_on_window(None, "https://github.com/Guyverix/Gnome-Multimonitor-Wallpaper#readme", Gtk.get_current_event_time())
        return

    def queryConfig(self,query):
        res = Popen(query, stdout=PIPE, stderr=None, shell=True)
        res.wait()
        return res.communicate()[0].strip().decode('UTF-8')

    def non_block_read(self):
        ''' even in a thread, a normal read with block until the buffer is full '''
        output = self.multi_wall_status.stdout
        # with open('goodlines.txt') as f:
        #     mylist = list(f)
        # output = '\n'.join(self.multi_wall_status.stdout.splitlines()[-1:])
        # '\n'.join(stderr.splitlines()[-N:])
        # .splitlines()[-1:]
        fd = output.fileno()
        fl = fcntl.fcntl(fd, fcntl.F_GETFL)
        fcntl.fcntl(fd, fcntl.F_SETFL, fl | os.O_NONBLOCK)
        op = output.read()
        if op == None:
            return ''
        status = op.decode('utf-8').rstrip()
        if "inactive" in status or "failed" in status or "deactivating" in status or "activating" in status:
            stats = "inactive"
        elif "active" in status:
            stats = "active"
        else:
            stats = "inactive"
        return stats

    def on_delete_event(event, self, widget):
        global restartsvc
        if restartsvc == True:
            try:
               restartcmd = ([os.environ['HOME']+'/.multi_wall/wallpapers', 'stop'])
               restartcmd2 = ([os.environ['HOME']+'/.multi_wall/wallpapers', 'start'])
               Popen(restartcmd)
               Popen(restartcmd2)
               restartsvc = False
            except CalledProcessError:
                Popen(['notify-send','Multiwall: Error restarting wallpapers after setting values!'])
        self.hide()
        self.destroy()
        return True


    def runAbout(self,button):
        win = Gtk.Window()

        path = os.environ['HOME']+'/.multi_wall/images/multi-color-48.png'
        width = -1
        height = 128
        preserve_aspect_ratio = True

        pixbuf = GdkPixbuf.Pixbuf.new_from_file_at_scale(path, width, height, preserve_aspect_ratio)
        win.set_default_icon_list([pixbuf])

        win.set_title("About")
        win.set_default_size(350, 200)
        win.set_position(Gtk.WindowPosition.CENTER)

        context = win.get_style_context()
        default_background = str(context.get_color(Gtk.StateType.NORMAL))

        tokenValue = re.search('red=(\d.\d+), green=(\d.\d+), blue=(\d.\d+), alpha=(\d.\d+)', default_background)
        red = float(tokenValue.group(1))
        green = float(tokenValue.group(2))
        blue = float(tokenValue.group(3))
        alpha = float(tokenValue.group(4))

        bgAvg = (red + green + blue)/3

        if(bgAvg > 0.5):
            theme = "light"
        else:
            theme = "dark"

        vbox = Gtk.VBox()

        if theme == "dark":
            path = os.environ['HOME']+'/.multi_wall/images/multi-color-48.png'
        else:
            path = os.environ['HOME']+'/.multi_wall/images/multi-color-48.png'
        width = -1
        height = 128
        preserve_aspect_ratio = True

        pixbuf = GdkPixbuf.Pixbuf.new_from_file_at_scale(path, width, height, preserve_aspect_ratio)
        image = Gtk.Image()
        image.set_from_pixbuf(pixbuf)

        with open(os.environ['HOME']+'/.multi_wall/version', 'r') as file:
            verdata = file.read().replace('\n', '')

        version = Gtk.Label()
        version.set_label('Multi-wall v' + verdata)
        credits = Gtk.Label()
        credits.set_label("Author: Christopher Hubbard")
        spacer = Gtk.Label()
        spacer.set_label(" ")
        copy = Gtk.Label()
        copy.set_label("© 2011, 2022 - GPLv2")
        url = Gtk.LinkButton(uri="https://iwillfearnoevil.com", label="I Will Fear No Evil")
        url2 = Gtk.LinkButton(uri="https://github.com/Guyverix/Gnome-Multimonitor-Wallpaper#readme", label="Github Repository")

        vbox.add(image)
        vbox.add(version)
        vbox.add(spacer)
        vbox.add(credits)
        vbox.add(copy)
        vbox.add(url)
        vbox.add(url2)
        win.add(vbox)

        win.show_all()
        win.show_all()

        version.set_selectable(True)
        win.connect('delete-event', self.on_delete_event)

        return


    def quit(source):
        Gtk.main_quit()

Indicator()
signal.signal(signal.SIGINT, signal.SIG_DFL)
Gtk.main()
