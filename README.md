xSwipe
======================
xSwipe is multitouch gesture recognizer.
This script make your linux PC able to recognize swipes like a Macbook.

## Usage

Before running the script, you must first do some preparations.

  1. Download xSwipe  
  2. Install X11::GUITest  
  3. Enable SHMConfig  

### 1. Download xSwipe
Type below code, download xSwipe from github  

    $ cd ~
    $ wget https://github.com/iberianpig/xSwipe/archive/master.zip
    $ unzip master.zip

### 2. Install X11::GUITest

To install libx11-guitest-perl from synaptic package manager  
Or run the script on the terminal run as 

    $ sudo apt-get install libx11-guitest-perl

### 3. Enable SHMConfig

Open /etc/X11/xorg.conf.d/50-synaptics.conf with your favorite text editor and edit it to enable SHMConfig

    $ sudo gedit /etc/X11/xorg.conf.d/50-synaptics.conf

NOTE:You will need to create the /etc/X11/xorg.conf.d/ directory and create 50-synaptics.conf if it doesn't exist yet.   
     `$ sudo mkdir /etc/X11/xorg.conf.d/`

##### /etc/X11/xorg.conf.d/50-synaptics.conf

    Section "InputClass"
    Identifier "evdev touchpad catchall"
    Driver "synaptics"
    MatchDevicePath "/dev/input/event*"
    MatchIsTouchpad "on"
    Option "Protocol" "event"
    Option "SHMConfig" "on"
    EndSection

To reflect SHMConfig, restart your session. 

That's it for preparation.

## Run xSwipe

To run xSwipe, type below code on terminal.  

    $ perl ~/xSwipe-master/xSwipe.pl

**Note:You should run xSwipe.pl in same directory as "eventKey.cfg" .**

You can use "swipe" with 3 or 4 fingers, they can call an event.  
Additionally, some gestures are avilable. 
- *edge-swipe* : swipe with 2 fingers from outside edge.
- *long-press* : hold pressure for 0.5 seconds with 3 or 4 fingers.

### Option
+   `-d RATE` :  
      *RATE* is sensitivity to swipe.Default value is 1.  
      Shorten swipe-length by half (e.g.,`$ perl xSwipe.pl -d 0.5`)
+   `-n` :  
      Natural scroll like Macbook, use "/nScroll/eventKey.cfg".

## Customize 
You can customize the settings for gestues to edit eventKey.cfg.  
Please check this article, ["How to customize gesture"](https://github.com/iberianpig/xSwipe/wiki/Customize-eventKey.cfg).

* go back/forward on browser
* move workspaces
* move a window
* open launcher
* open a terminal
* close a window

Please let me know if you have any questions about this program.
