--Update
2012/12/27 - merged 2-finger NaturalScroll function.
2012/12/23 - updated for option, -n and -d.
            -> -d RATE
              : RATE is sensitivity to swipe.Default value is 1.
                Shorten swipe-length by half (e.g.,"$perl xSwipe.pl -d 0.5")
            -> -n
              : use natural scroll like a macook.
2012/12/10 - updated for edge-swipe.
             ->avilable edge-swipe with 2finger from outside edge                            
           - fixed missing swipe bug.
2012/12/02 - updated for multi-PressKey.

--Usage
This file says how to use xSwipe.pl.

This script make your linux PC able to recognize swipes like a macbook.

Before running the script, you must first do some preparations.

0.Download xSwipe
1.Install X11::GUITest
2.Enable SHMConfig

0.Download xSwipe
Type below code, download xSwipe from github
    $ cd ~
    $ wget https://github.com/iberianpig/xSwipe/archive/master.zip
    $ unzip master.zip

1.Install X11::GUITest
To install libx11-guitest-perl from synaptic package manager
Or run the script on the terminal run as sudo apt-get install libx11-guitest-perl

2.Enable SHMConfig
Open /etc/X11/xorg.conf.d/50-synaptics.conf with your favorite text editor and edit it to enable SHMConfig
    $ sudo gedit /etc/X11/xorg.conf.d/50-synaptics.conf

NOTE:You will need to create the /etc/X11/xorg.conf.d/ directory and create 50-synaptics.conf (if it doesn't exist yet) 
    $ sudo mkdir /etc/X11/xorg.conf.d/  (if not exist)

----------/etc/X11/xorg.conf.d/50-synaptics.conf------------------------
Section "InputClass"
Identifier "evdev touchpad catchall"
Driver "synaptics"
MatchDevicePath "/dev/input/event*"
MatchIsTouchpad "on"
Option "Protocol" "event"
Option "SHMConfig" "on"
EndSection
------------------------------------------------------------------------
To reflect SHMConfig, restart your session. 

That's it for preparation.

To run xSwipe, type below code on terminal.

    $ perl ~/xSwipe-master/xSwipe.pl

Note:you should run xSwipe.pl in same directory as "eventKey.cfg" .

You can use "swipe" with 3 or 4 fingers, and "swipe" can call an event.

You can customize the settings for swipe with eventKey.cfg.
#Please check here<https://github.com/iberianpig/xSwipe/wiki/Customize-eventKey.cfg>

Please let me know if you have any questions about this program.
