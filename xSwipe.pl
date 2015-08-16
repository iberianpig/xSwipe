#!/usr/bin/perl
################################################
 #    #   ####   #    #     #    #####   ######
  #  #   #       #    #     #    #    #  #
   ##     ####   #    #     #    #    #  #####
   ##         #  # ## #     #    #####   #
  #  #   #    #  ##  ##     #    #       #
 #    #   ####   #    #     #    #       ######
################################################
use strict;
use Time::HiRes();
use X11::GUITest qw( :ALL );
use FindBin;
#debug
use Smart::Comments;

my $natural_scroll = 0;
my $base_dist = 0.1;
my $polling_interval = 10;
my $conf_file_name = "eventKey.cfg";
my $n_scroll_conf_file_name = "nScroll/eventKey.cfg";
my $edge_swipe = 0;

while(my $ARGV = shift){
  ### $ARGV
  if ($ARGV eq '-n'){
    $natural_scroll = 1;
  }elsif ($ARGV eq '-d'){
    if ($ARGV[0] > 0){
      $base_dist = $base_dist * $ARGV[0];
      ### $base_dist
      shift;
    }else{
      print "Set a value greater than 0\n";
      exit(1);
    }
  }elsif ($ARGV eq '-m'){
    if ($ARGV[0] > 0){
      $polling_interval = $ARGV[0];
      ### $polling_interval
      shift;
    }else{
      print "Set a value greater than 0\n";
      exit(1);
    }
  }elsif ($ARGV eq '-e'){
    $edge_swipe = 1;
  }else{
    print "
    Available Options
    -d RATE
    RATE sensitivity to swipe
    RATE > 0, default value is 1
    -m INTERVAL
    INTERVAL how often synclient monitor changes to the touchpad state
    INTERVAL > 0, default value is 10 (ms)
    -n
    Natural Scrolling, like a macbook
    setting file path=nScroll/eventKey.cfg
    -e
    Enable edge-swipe
    \n";
    exit(1);
  }
}
# add syndaemon setting
system("syndaemon -m 10 -i 0.5 -K -d");

open (scroll_setting, "synclient -l | grep ScrollDelta | grep -v -e Circ | ")or die "can't synclient -l";
my @scroll_setting = <scroll_setting>;
close(file_handle);

my $vert_scroll_delta  = abs((split "= ", $scroll_setting[0])[1]);
my $horiz_scroll_delta = abs((split "= ", $scroll_setting[1])[1]);

&init_synclient($natural_scroll);

open (area_setting, "synclient -l | grep Edge | grep -v -e Area -e Motion -e Scroll | ")or die "can't synclient -l";
my @area_setting = <area_setting>;
close(file_handle);

my $left_edge   = (split "= ", $area_setting[0])[1];
my $right_edge  = (split "= ", $area_setting[1])[1];
my $top_edge    = (split "= ", $area_setting[2])[1];
my $bottom_edge = (split "= ", $area_setting[3])[1];

my $touchpad_size_h   = abs($top_edge - $bottom_edge);
my $touchpad_size_w   = abs($left_edge - $right_edge);
my $x_min_thredshould = $touchpad_size_w * $base_dist;
my $y_min_thredshould = $touchpad_size_h * $base_dist;
my $inner_edge_left   = $left_edge   + $x_min_thredshould/3;
my $inner_edge_right  = $right_edge  - $x_min_thredshould/3;
my $inner_edge_top    = $top_edge    + $y_min_thredshould;
my $inner_edge_bottom = $bottom_edge - $y_min_thredshould;

### @area_setting
### $touchpad_size_h
### $touchpad_size_w
### $x_min_thredshould
### $y_min_thredshould
### $inner_edge_left
### $inner_edge_right
### $inner_edge_top
### $inner_edge_bottom

#load config
my $script_dir = $FindBin::Bin;#CurrentPath
my $conf = require $script_dir."/".$conf_file_name;
open (file_handle, "pgrep -lf ^gnome-session |")or die "can't pgrep -lf ^gnome-session";
my @data = <file_handle>;
my $session_name = (split "session=", $data[0])[1];
close(file_handle);
chomp($session_name);
# If $session_name is empty (gnome-session doesn't work), try to find it with $DESKTOP_SESSION
if (not length $session_name){
  open (desktop_session, 'echo $DESKTOP_SESSION |')or die 'can\'t echo $DESKTOP_SESSION';
  $session_name = <desktop_session>;
  close(desktop_session);
  chomp($session_name);
}
$session_name = ("$session_name" ~~ $conf) ? "$session_name" : 'other';
### $session_name

my @swipe3_right      = split "/", ($conf->{$session_name}->{swipe3}->{right});
my @swipe3_left       = split "/", ($conf->{$session_name}->{swipe3}->{left});
my @swipe3_down       = split "/", ($conf->{$session_name}->{swipe3}->{down});
my @swipe3_up         = split "/", ($conf->{$session_name}->{swipe3}->{up});

my @swipe4_right      = split "/", ($conf->{$session_name}->{swipe4}->{right});
my @swipe4_left       = split "/", ($conf->{$session_name}->{swipe4}->{left});
my @swipe4_down       = split "/", ($conf->{$session_name}->{swipe4}->{down});
my @swipe4_up         = split "/", ($conf->{$session_name}->{swipe4}->{up});

my @swipe5_right      = split "/", ($conf->{$session_name}->{swipe5}->{right});
my @swipe5_left       = split "/", ($conf->{$session_name}->{swipe5}->{left});
my @swipe5_down       = split "/", ($conf->{$session_name}->{swipe5}->{down});
my @swipe5_up         = split "/", ($conf->{$session_name}->{swipe5}->{up});

my @edge_swipe2_right = split "/", ($conf->{$session_name}->{edge_swipe2}->{right});
my @edge_swipe2_left  = split "/", ($conf->{$session_name}->{edge_swipe2}->{left});
my @edge_swipe3_down  = split "/", ($conf->{$session_name}->{edge_swipe3}->{down});
my @edge_swipe3_up    = split "/", ($conf->{$session_name}->{edge_swipe3}->{up});
my @edge_swipe4_down  = split "/", ($conf->{$session_name}->{edge_swipe4}->{down});
my @edge_swipe4_up    = split "/", ($conf->{$session_name}->{edge_swipe4}->{up});
my @long_press2       = split "/", ($conf->{$session_name}->{swipe2}->{press});
my @long_press3       = split "/", ($conf->{$session_name}->{swipe3}->{press});
my @long_press4       = split "/", ($conf->{$session_name}->{swipe4}->{press});
my @long_press5       = split "/", ($conf->{$session_name}->{swipe5}->{press});

my @x_hist1 = (); # x coordinate history (1 finger)
my @y_hist1 = (); # y coordinate history (1 finger)
my @x_hist2 = (); # x coordinate history (2 fingers)
my @y_hist2 = (); # y coordinate history (2 fingers)
my @x_hist3 = (); # x coordinate history (3 fingers)
my @y_hist3 = (); # y coordinate history (3 fingers)
my @x_hist4 = (); # x coordinate history (4 fingers)
my @y_hist4 = (); # y coordinate history (4 fingers)
my @x_hist5 = (); # x coordinate history (5 fingers)
my @y_hist5 = (); # y coordinate history (5 fingers)

my $axis = 0;
my $rate = 0;

my $touch_state = "not_swiping"; # touchState={0/1/2} 0=notSwiping, 1=Swiping, 2=edge_swiping
my $last_time = 0;               # time monitor for TouchPad event reset
my $event_time = 0;              # ensure enough time has passed between events
my @event_string = ("default");  # the event to execute

my $curr_wind = GetInputFocus();
die "couldn't get input window" unless $curr_wind;
open(INFILE,"synclient -m $polling_interval |") or die "can't read from synclient";
while(my $line = <INFILE>){
  chomp($line);
  my($time, $x, $y, $z, $f, $w) = split " ", $line;
  next if($time =~ /time/); #ignore header lines
  if($time - $last_time > 5){
    &init_synclient($natural_scroll);
  }#if time reset
  $last_time = $time;
  $axis = 0;
  $rate = 0;
  if($f == 1){
    if($touch_state eq "not_swiping"){
      if(in_edge_area($x, "")){
        $touch_state = "edge_swiping";
      }else{
        $touch_state = "swiping";
      }
    }
    clean_hist(2 ,3 ,4 ,5);
    if ($touch_state eq "edge_swiping"){
      push @x_hist1, $x;
      push @y_hist1, $y;
      $axis = get_axis(\@x_hist1, \@y_hist1, 2, 0.1);
      if($axis eq "x"){
        $rate = get_rate(@x_hist1);
        $touch_state = "edge_swiping";
      }elsif($axis eq "y"){
        $rate = get_rate(@y_hist1);
        $touch_state = "edge_swiping";
      }
    }

  }elsif($f == 2){
    if($touch_state eq "not_swiping"){
      if(in_edge_area($x, "")){
        $touch_state = "edge_swiping";
        &switch_touch_pad("Off");
      }else{
        $touch_state = "swiping";
      }
    }
    clean_hist(1, 3, 4, 5);
    push @x_hist2, $x;
    push @y_hist2, $y;
    $axis = get_axis(\@x_hist2, \@y_hist2, 2, 0.1);
    if($axis eq "x"){
      $rate = get_rate(@x_hist2);
    }elsif($axis eq "y"){
      $rate = get_rate(@y_hist2);
    }elsif($axis eq "z"){
      $axis = get_axis(\@x_hist2, \@y_hist2, 30, 0.5);
      if($axis eq "z"){
      }
    }

  }elsif($f == 3){
    if($touch_state eq "not_swiping" ){
      if(in_edge_area("", $y)){
        $touch_state = "edge_swiping";
      }else{
        $touch_state = "swiping";
      }
    }
    clean_hist(1, 2, 4, 5);
    push @x_hist3, $x;
    push @y_hist3, $y;
    $axis = get_axis(\@x_hist3, \@y_hist3, 5, 0.5);
    if($axis eq "x"){
      $rate = get_rate(@x_hist3);
    }elsif($axis eq "y"){
      $rate = get_rate(@y_hist3);
    }elsif($axis eq "z"){
      $axis = get_axis(\@x_hist3, \@y_hist3, 30, 0.5);
      if($axis eq "z"){
      }
    }

  }elsif($f == 4){
    if($touch_state eq "not_swiping" ){
      if(in_edge_area("", $y)){
        $touch_state = "edge_swiping";
      }else{
        $touch_state = "swiping";
      }
    }
    clean_hist(1, 2, 3, 5);
    push @x_hist4, $x;
    push @y_hist4, $y;
    $axis = get_axis(\@x_hist4, \@y_hist4, 5, 0.5);
    if($axis eq "x"){
      $rate = get_rate(@x_hist4);
    }elsif($axis eq "y"){
      $rate = get_rate(@y_hist4);
    }elsif($axis eq "z"){
      $axis = get_axis(\@x_hist4, \@y_hist4, 30, 0.5);
      if($axis eq "z"){
      }
    }

  }elsif($f == 5){
    if($touch_state eq "not_swiping" ){
      if(in_edge_area("", $y)){
        $touch_state = "edge_swiping";
      }else{
        $touch_state = "not_swiping";
      }
    }
    clean_hist(1, 2, 3 ,4);
    push @x_hist5, $x;
    push @y_hist5, $y;
    $axis = get_axis(\@x_hist5, \@y_hist5, 5, 0.5);
    if($axis eq "x"){
      $rate = get_rate(@x_hist5);
    }elsif($axis eq "y"){
      $rate = get_rate(@y_hist5);
    }
  }else{
    clean_hist(1, 2, 3, 4, 5);
    if($touch_state ne "not_swiping"){
      $touch_state = "not_swiping";
      &switch_touch_pad("On");
    }
  }


#detect action
  if ($axis ne 0){
    @event_string = set_event_string($f,$axis,$rate,$touch_state);
    clean_hist(1, 2, 3, 4, 5);
  }

# only process one event per time window
  if( $event_string[0] ne "default" ){
    ### ne default
    if( abs($time - $event_time) > 0.2 ){
      ### $time - $event_time got: $time - $event_time
      $event_time = $time;
      PressKey $_ foreach(@event_string);
      ReleaseKey $_ foreach(reverse @event_string);
      ### @event_string
    }# if enough time has passed
    @event_string = ("default");
  }#if non default event
}#synclient line in
close(INFILE);

###init
sub init_synclient{
  ### init_synclient
  # &switch_touch_pad("On");
  my $natural_scroll = $_[0];
  if($natural_scroll == 1){
    $conf_file_name = $n_scroll_conf_file_name;
    `synclient VertScrollDelta=-$vert_scroll_delta HorizScrollDelta=-$horiz_scroll_delta ClickFinger3=1 TapButton3=2`;
  }else{
    `synclient VertScrollDelta=$vert_scroll_delta HorizScrollDelta=$horiz_scroll_delta ClickFinger3=1 TapButton3=2`;
  }
}

sub switch_touch_pad{
  open(TOUCHPADOFF,"synclient -l | grep TouchpadOff |") or die "can't read from synclient";
  my $touch_pad_off = <TOUCHPADOFF>;
  close(TOUCHPADOFF);
  chomp($touch_pad_off);
  my $touch_pad_off = (split "= ", $touch_pad_off)[1];
  ### $touch_pad_off
  my $switch_flag = shift;
  if($switch_flag eq 'Off'){
    if($touch_pad_off eq '0'){
      `synclient TouchPadOff=1`;
    }
  }elsif($switch_flag eq "On"){
    if($touch_pad_off ne '0' ){
      `synclient TouchPadOff=0`;
    }
  }
}

sub get_axis{
  my($x_hist, $y_hist, $max, $threshould_rate)=@_;
  if(@$x_hist > $max or @$y_hist > $max){
    my $x0     = @$x_hist[0];
    my $y0     = @$y_hist[0];
    my $xmax   = @$x_hist[$max];
    my $ymax   = @$y_hist[$max];
    my $x_dist = abs( $x0 - $xmax );
    my $y_dist = abs( $y0 - $ymax );
    if($x_dist > $y_dist){
      if($x_dist > $x_min_thredshould * $threshould_rate){
        return "x";
      }else{
        return "z";
      }
    }else{
      if($y_dist > $y_min_thredshould * $threshould_rate){
        return "y";
      }else{
        return "z";
      }
    }
  }
  return 0;
}

sub get_rate{
  my @hist = @_;
  my @srt     = sort {$a <=> $b} @hist;
  my @rev_srt = sort {$b <=> $a} @hist;
  if( "@srt" eq "@hist" ){
    return "+";
  }elsif( "@rev_srt" eq "@hist" ){
    return "-";
  }#if forward or backward
  return 0;
}

sub clean_hist{
  while(my $arg = shift){
    if($arg == 1){
      @x_hist1 = ();
      @y_hist1 = ();
    }elsif($arg == 2){
      @x_hist2 = ();
      @y_hist2 = ();
    }elsif($arg == 3){
      @x_hist3 = ();
      @y_hist3 = ();
    }elsif($arg == 4){
      @x_hist4 = ();
      @y_hist4 = ();
    }elsif($arg == 5){
      @x_hist5 = ();
      @y_hist5 = ();
    }
  }
}

sub in_edge_area{
  unless ($edge_swipe){
    return 0;
  }
  my($x, $y)=@_;
  if($x and ( ($x < $inner_edge_left)or($inner_edge_right < $x) )){
    return 1;
  }
  if($y and ( ($y < $inner_edge_top)or($inner_edge_bottom < $y) )){
    return 1;
  }
  return 0;
}

#return @event_string $_[0]
sub set_event_string{
  my($f, $axis, $rate, $touch_state)=@_;
  if($f == 2){
    if($axis eq "x"){
      if($rate eq "+"){
        if($touch_state eq "edge_swiping"){
          return @edge_swipe2_right;
        }
      }elsif($rate eq "-"){
        if($touch_state eq "edge_swiping"){
          return @edge_swipe2_left;
        }
      }
    }elsif($axis eq "z"){
      if($rate eq "0"){
        if($touch_state eq "swiping"){
          return @long_press2;
        }
      }
    }
  }elsif($f == 3){
    if($axis eq "x"){
      if($rate eq "+"){
        return @swipe3_right;
      }elsif($rate eq "-"){
        return @swipe3_left;
      }
    }elsif($axis eq "y"){
      if($rate eq "+"){
        if($touch_state eq "edge_swiping"){
          return @edge_swipe3_down;
        }
        return @swipe3_down;
      }elsif($rate eq "-"){
        if($touch_state eq "edge_swiping"){
          return @edge_swipe3_up;
        }
        return @swipe3_up;
      }
    }elsif($axis eq "z"){
      if($rate eq "0"){
        return @long_press3;
      }
    }
  }elsif($f == 4){
    if($axis eq "x"){
      if($rate eq "+"){
        return @swipe4_right;
      }elsif($rate eq "-"){
        return @swipe4_left;
      }
    }elsif($axis eq "y"){
      if($rate eq "+"){
        if($touch_state eq "edge_swiping"){
          return @edge_swipe4_down;
        }
        return @swipe4_down;
      }elsif($rate eq "-"){
        if($touch_state eq "edge_swiping"){
          return @edge_swipe4_up;
        }
        return @swipe4_up;
      }
    }elsif($axis eq "z"){
      if($rate eq "0"){
        return @long_press4;
      }
    }
  }elsif($f == 5){
    if($axis eq "x"){
      if($rate eq "+"){
        return @swipe5_right;
      }elsif($rate eq "-"){
        return @swipe5_left;
      }
    }elsif($axis eq "y"){
      if($rate eq "+"){
        return @swipe5_down;
      }elsif($rate eq "-"){
        return @swipe5_up;
      }
    }elsif($axis eq "z"){
      if($rate eq "0"){
        return @long_press5;
      }
    }
  }
  return "default";
}

