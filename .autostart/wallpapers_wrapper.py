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
    global sysv
    try:
        sysv = int(Popen("pidof systemd >/dev/null 2>&1 && echo '0' || echo '1'", stdout=PIPE, shell=True).communicate()[0].strip().decode('UTF-8'))
    except:
        sysv = 2
    if sysv:
        multi_wall_status = Popen("export TERM=xterm-color;while :; do clear; pgrep -fx '/bin/bash " + os.environ['HOME']+ "/.multi_wall/multi_wallpapers.sh start' && echo 'active'; sleep 2; done", stdout=PIPE, shell=True)
    else:
        multi_wall_status = Popen("export TERM=xterm-color;while :; do clear; pgrep -fx '/bin/bash " + os.environ['HOME']+ "/.multi_wall/multi_wallpapers.sh start' && echo 'active'; sleep 2; done", stdout=PIPE, shell=True)
#        multi_wall_status = Popen("export TERM=xterm-color;while :; do clear; systemctl is-active wallpaper; sleep 2; done", stdout=PIPE, shell=True)
    child_pid = multi_wall_status.pid

    homedir = os.path.expanduser("~")
    kconfig = homedir+"/.multi_wall/multi.cfg"
    ostype = os.environ.get('XDG_CURRENT_DESKTOP')

    enable_id = 0
    winmac_id = 0
    chkautostart_id = 0
    autostart_bool = False
    menu = Gtk.Menu()
    checkbox_autostart = Gtk.CheckMenuItem(label='Autostart')
    restart = Gtk.MenuItem(label='Restart')
    stop = Gtk.MenuItem(label='Stop')

    edit = Gtk.MenuItem(label='Customize')
    edit_submenu = Gtk.Menu()
    edit.set_submenu(edit_submenu)

    button_config = Gtk.MenuItem(label='Multi-Wallpaper Config (multi.cfg)')
    service = Gtk.MenuItem(label='Multi monitor Service')
    about = Gtk.MenuItem(label='About')

    helpm = Gtk.MenuItem(label='Help')
    help_submenu = Gtk.Menu()
    helpm.set_submenu(help_submenu)

    systray = Gtk.CheckMenuItem(label='Tray Enabled')

    global restartsvc
    restartsvc = False
    unixts = int(time.time())
    last_status = ''

    def __init__(self):
        global sysv
        try:
            sysv = int(Popen("pidof systemd >/dev/null 2>&1 && echo '0' || echo '1'", stdout=PIPE, shell=True).communicate()[0].strip().decode('UTF-8'))
        except:
            sysv = 1
        if sysv:
            res = Popen(['pgrep', '-fx', '/bin/bash ' + os.environ['HOME']+ '/.multi_wall/multi_wallpapers.sh start'])
        else:
            res = Popen(['pgrep', '-fx', '/bin/bash ' + os.environ['HOME']+ '/.multi_wall/multi_wallpapers.sh start'])
#            res = Popen(['sudo', 'systemctl','is-active','--quiet','wallpaper'])
        res.wait()

        if res.returncode == 0:
            self.last_status = 'active'
            self.indicator = appindicator.Indicator.new(APPINDICATOR_ID, os.environ['HOME']+'/.multi_wall/kinto-invert.svg', appindicator.IndicatorCategory.SYSTEM_SERVICES)
        else:
            self.last_status = 'inactive'
            self.indicator = appindicator.Indicator.new(APPINDICATOR_ID, os.environ['HOME']+'/.multi_wall/kinto.svg', appindicator.IndicatorCategory.SYSTEM_SERVICES)

        self.indicator.set_status(appindicator.IndicatorStatus.ACTIVE)
        self.indicator.set_menu(self.build_menu(res))
        notify.init(APPINDICATOR_ID)

        GLib.timeout_add(2000, self.update_terminal)

    def build_menu(self,res):
        autostart_line = str(Popen("grep '^AUTOSTART' " + os.environ['HOME']+'/.multi_wall/multi.cfg', stdout=PIPE, shell=True).communicate()[0].strip().decode('UTF-8'))

        if autostart_line == "AUTOSTART=true":
            autostart_bool = True
        else:
            autostart_bool = False

        if autostart_bool:
            # Popen(['sudo', 'systemctl','restart','multiwall?'])
            self.checkbox_autostart.set_active(True)
            self.chkautostart_id = self.checkbox_autostart.connect('activate',self.setAutostart,False)
        else:
            self.checkbox_autostart.set_active(False)
            self.chkautostart_id = self.checkbox_autostart.connect('activate',self.setAutostart,True)

        self.restart.connect('activate',self.runRestart)
        self.menu.append(self.restart)
        self.stop.connect('activate',self.runStop)
        self.menu.append(self.stop)

        self.edit_submenu.append(self.service)
        self.edit_submenu.append(self.button_config)
        self.edit_submenu.append(self.checkbox_autostart)
        if os.path.exists(os.environ['HOME']+'/.multi_wall/multi_wall.desktop'):
            self.systray.set_active(True)
            self.systray.signal_id = self.systray.connect('activate',self.checkTray,False)
        else:
            self.systray.signal_id = self.systray.connect('activate',self.checkTray,True)

        self.edit_submenu.append(self.systray)
        self.menu.append(self.edit)




# At the end
        self.about.connect('activate',self.runAbout)
        self.help_submenu.append(self.about)
        self.menu.append(self.helpm)

        item_quit = Gtk.MenuItem(label='Close')
        item_quit.connect('activate', quit)
        self.menu.append(item_quit)
        self.menu.show_all()

        return self.menu


    def checkTray(self,button,tray_bool):
        # path.exists('.autostart/wallpapers_wrapper.py')
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
        global sysv
        try:
            if sysv:
                stop = Popen(['sudo', '-E','/etc/init.d/multi_wall','stop'])
            else:
#                stop = Popen(['sudo', 'systemctl','stop','multi_wall'])
                stop = Popen([os.environ['HOME']+'/.multi_wall/wallpapers', 'stop'])
            stop.wait()
            time.sleep(1)
#            res = Popen(['pgrep', '-lf', 'bin/bash.*.multi_wallpaper.sh'])
            res = Popen(['pgrep', '-fx', '/bin/bash ' + os.environ['HOME']+'/.multi_wall/multi_wallpapers.sh start'])
            res.wait()

            if res.returncode == 0:
                # Popen(['notify-send','Kinto: Ending Debug'])
#                pkillxkey = Popen(['sudo', 'pkill','-f','wallpapers'])
                pkillxkey = Popen(["ps aux | grep '[m]ulti_wallpapers.sh start' | awk '{print $2}' | xargs kill -9"])
                pkillxkey.wait()
            if sysv:
                Popen(['sudo', '-E','/etc/init.d/multi_wall','start'])
            else:
#                Popen(['sudo', 'systemctl','start','multi_wall'])
                Popen([os.environ['HOME']+'/.multi_wall/wallpapers', 'start'])
        except:
            Popen(['notify-send','Multiwallpaper: Error restarting Multi-Wallpapers!'])

    def runStop(self,button):
        global sysv
        try:
            if sysv:
                Popen(['notify-send','Hitting sysv stop command'])
                stop = Popen(['sudo', '-E','/etc/init.d/multi_wall','stop'])
#                stop = Popen(['sudo', '-E', os.environ['HOME']+'/.multi_wall/wallpapers stop'])
            else:
                stop = Popen([os.environ['HOME']+'/.multi_wall/wallpapers', 'stop'])
            stop.wait()
            time.sleep(1)
            res = Popen(['pgrep', '-fx', '/bin/bash ' + os.environ['HOME']+'/.multi_wall/multi_wallpapers.sh start'])
            res.wait()

            #Popen(['notify-send','DEBUG: return code for pgrep ' + str(res.returncode)])
            if res.returncode == 0:
                Popen(['notify-send','Multiwall: Ending Debug killing process'])
                pkillxkey = Popen(["ps aux | grep '[m]ulti_wallpapers.sh start' | awk '{print $2}' | xargs kill -9"])
                pkillxkey.wait()
        except:
            Popen(['notify-send','Multiwallpaper: Error stopping Multi-Wallpapers! find the damn exception '])


    def setConfig(self,button):
        try:
            if os.path.exists('/opt/sublime_text/sublime_text'):
                Popen(['/opt/sublime_text/sublime_text',os.environ['HOME']+'/.multi_wall/multi.cfg'])
            elif which('nano') is not None:
                Popen(['nano',os.environ['HOME']+'/.multi_wall/multi.cfg'])
            elif which('gedit') is not None:
                Popen(['gedit',os.environ['HOME']+'/.multi_wall/multi.cfg'])
            elif which('mousepad') is not None:
                Popen(['mousepad',os.environ['HOME']+'/.multi_wall/multi.cfg'])
            elif which('kate') is not None:
                Popen(['kate',os.environ['HOME']+'/.multi_wall/multi.cfg'])
            elif which('kwrite') is not None:
                Popen(['kwrite',os.environ['HOME']+'/.multi_wall/multi.cfg'])
        except CalledProcessError:                                  # Notify user about error on running restart commands.
            Popen(['notify-send','Multiwall: Error could not open config file multi.cfg!'])


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
        kinto_icon_desc = "Kinto"
        if (nowts - self.unixts) > 5 and (status=='active' and self.indicator.get_icon() != os.environ['HOME']+'/.multi_wall/kinto-invert.svg'):
            self.indicator.set_icon_full(os.environ['HOME']+'/.multi_wall/kinto-invert.svg', kinto_icon_desc)
        elif (nowts - self.unixts) > 5 and (status == 'inactive' and self.indicator.get_icon() != os.environ['HOME']+'/.multi_wall/kinto.svg'):
            self.indicator.set_icon_full(os.environ['HOME']+'/.multi_wall/kinto.svg', kinto_icon_desc)
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


    def setService(self,button):
        try:
            if os.path.exists('/opt/sublime_text/sublime_text'):
                Popen(['/opt/sublime_text/sublime_text','/lib/systemd/system/multi_wall.service'])
            elif which('gedit') is not None:
                Popen(['gedit','/lib/systemd/system/multi_wall.service'])
            elif which('mousepad') is not None:
                Popen(['mousepad','/lib/systemd/system/multi_wall.service'])
            elif which('kate') is not None:
                Popen(['kate','/lib/systemd/system/multi_wall.service'])
            elif which('kwrite') is not None:
                Popen(['kwrite','/lib/systemd/system/multi_wall.service'])
        except CalledProcessError:                                  # Notify user about error on running restart commands.
            Popen(['notify-send','Multiwall: Error could not open service config file!'])


    def on_delete_event(event, self, widget):
        global restartsvc
        if restartsvc == True:
            try:
                if sysv:
                    restartcmd = ([os.environ['HOME']+'/.multi_wall/wallpapers', 'stop'])
                    restartcmd2 = ([os.environ['HOME']+'/.multi_wall/wallpapers', 'start'])
#                    restartcmd = ['sudo', '-E','/etc/init.d/kinto','restart']
                else:
                    restartcmd = ([os.environ['HOME']+'/.multi_wall/wallpapers', 'stop'])
                    restartcmd2 = ([os.environ['HOME']+'/.multi_wall/wallpapers', 'start'])
#                    restartcmd = ['sudo', 'systemctl','restart','xkeysnail']
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

        path = os.environ['HOME']+'/.multi_wall/kinto-color.svg'
        width = -1
        height = 128
        preserve_aspect_ratio = True

        pixbuf = GdkPixbuf.Pixbuf.new_from_file_at_scale(path, width, height, preserve_aspect_ratio)
        win.set_default_icon_list([pixbuf])

        win.set_title("About")
        win.set_default_size(350, 200)
        win.set_position(Gtk.WindowPosition.CENTER)

        context = win.get_style_context()
#        default_background = str(context.get_background_color(Gtk.StateType.NORMAL))
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
        # innervbox = Gtk.VBox()

        if theme == "dark":
            path = os.environ['HOME']+'/.multi_wall/kinto-invert.svg'
        else:
            path = os.environ['HOME']+'/.multi_wall/kinto-color.svg'
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

        vbox.add(image)
        vbox.add(version)
        vbox.add(spacer)
        vbox.add(credits)
        vbox.add(copy)
        vbox.add(url)
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
