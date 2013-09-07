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
#use Smart::Comments;

my $naturalScroll = 0;
my $baseDist = 0.1;
my $confFileName = "eventKey.cfg";
my $nScrollConfFileName = "nScroll/eventKey.cfg";

while(my $ARGV = shift){
    ### $ARGV
    if ($ARGV eq '-n'){
        $naturalScroll = 1;
    }elsif ($ARGV eq '-d'){
        if ($ARGV[0] > 0){
            $baseDist = $baseDist * $ARGV[0];
            shift;
        }else{
            print "Set a value greater than 0\n";
            exit(1);
        }
    }else{
        print "
        Available Options
        -d RATE
            RATE sensitivity to swipe
            RATE > 0, default value is 1.
        -n
            Natural Scrolling, like a macbook
            setting file path=nScroll/eventKey.cfg
        \n";
        exit(1);
    }
}
# add syndaemon setting
system("syndaemon -m 1 -i 0.5 -K -t &");

open (Scroll_setting, "synclient -l | grep ScrollDelta | grep -v -e Circ | ")or die "can't synclient -l";
my @Scroll_setting = <Scroll_setting>;
close(fileHundle);

my $VertScrollDelta  = abs((split "= ", $Scroll_setting[0])[1]);
my $HorizScrollDelta = abs((split "= ", $Scroll_setting[1])[1]);

&initSynclient($naturalScroll);

open (area_setting, "synclient -l | grep Edge | grep -v -e Area -e Motion -e Scroll | ")or die "can't synclient -l";
my @area_setting = <area_setting>;
close(fileHundle);

my $LeftEdge   = (split "= ", $area_setting[0])[1];
my $RightEdge  = (split "= ", $area_setting[1])[1];
my $TopEdge    = (split "= ", $area_setting[2])[1];
my $BottomEdge = (split "= ", $area_setting[3])[1];

my $TouchpadSizeH = abs($TopEdge - $BottomEdge);
my $TouchpadSizeW = abs($LeftEdge - $RightEdge);
# todo:タッチパッドの比率^2でMinThresholdを決定してもいいかも
my $xMinThreshold = $TouchpadSizeW * $baseDist;
my $yMinThreshold = $TouchpadSizeH * $baseDist;
# todo: エリア取得方法の見直し。場合によっては外部ファイル化やキャリブレーションを検討
my $innerEdgeLeft   = $LeftEdge   + $xMinThreshold/2;
my $innerEdgeRight  = $RightEdge  - $xMinThreshold/2;
my $innerEdgeTop    = $TopEdge    + $yMinThreshold;
my $innerEdgeBottom = $BottomEdge - $yMinThreshold;

### @area_setting
### $TouchpadSizeH
### $TouchpadSizeW
### $xMinThreshold
### $yMinThreshold
### $innerEdgeLeft
### $innerEdgeRight
### $innerEdgeTop
### $innerEdgeBottom

#load config
my $script_dir = $FindBin::Bin;#CurrentPath
my $conf = require $script_dir."/".$confFileName;
open (fileHundle, "pgrep -lf ^gnome-session |")or die "can't pgrep -lf ^gnome-session";
my @data = <fileHundle>;
my $sessionName = (split "session=", $data[0])[1];
close(fileHundle);
chomp($sessionName);
$sessionName = ("$sessionName" ~~ $conf) ? "$sessionName" : 'other';
### $sessionName

my @swipe3Right = split "/", ($conf->{$sessionName}->{swipe3}->{right});
my @swipe3Left  = split "/", ($conf->{$sessionName}->{swipe3}->{left});
my @swipe3Down  = split "/", ($conf->{$sessionName}->{swipe3}->{down});
my @swipe3Up    = split "/", ($conf->{$sessionName}->{swipe3}->{up});

my @swipe4Right = split "/", ($conf->{$sessionName}->{swipe4}->{right});
my @swipe4Left  = split "/", ($conf->{$sessionName}->{swipe4}->{left});
my @swipe4Down  = split "/", ($conf->{$sessionName}->{swipe4}->{down});
my @swipe4Up    = split "/", ($conf->{$sessionName}->{swipe4}->{up});

my @swipe5Right = split "/", ($conf->{$sessionName}->{swipe5}->{right});
my @swipe5Left  = split "/", ($conf->{$sessionName}->{swipe5}->{left});
my @swipe5Down  = split "/", ($conf->{$sessionName}->{swipe5}->{down});
my @swipe5Up    = split "/", ($conf->{$sessionName}->{swipe5}->{up});

my @edgeSwipe2Right = split "/", ($conf->{$sessionName}->{edgeSwipe2}->{right});
my @edgeSwipe2Left  = split "/", ($conf->{$sessionName}->{edgeSwipe2}->{left});
my @edgeSwipe3Down  = split "/", ($conf->{$sessionName}->{edgeSwipe3}->{down});
my @edgeSwipe3Up    = split "/", ($conf->{$sessionName}->{edgeSwipe3}->{up});
my @edgeSwipe4Down  = split "/", ($conf->{$sessionName}->{edgeSwipe4}->{down});
my @edgeSwipe4Up    = split "/", ($conf->{$sessionName}->{edgeSwipe4}->{up});
my @longPress2 = split "/", ($conf->{$sessionName}->{swipe2}->{press});
my @longPress3 = split "/", ($conf->{$sessionName}->{swipe3}->{press});
my @longPress4 = split "/", ($conf->{$sessionName}->{swipe4}->{press});
my @longPress5 = split "/", ($conf->{$sessionName}->{swipe5}->{press});

my @xHist1 = ();                # x coordinate history (1 finger)
my @yHist1 = ();                # y coordinate history (1 finger)
my @xHist2 = ();                # x coordinate history (2 fingers)
my @yHist2 = ();                # y coordinate history (2 fingers)
my @xHist3 = ();                # x coordinate history (3 fingers)
my @yHist3 = ();                # y coordinate history (3 fingers)
my @xHist4 = ();                # x coordinate history (4 fingers)
my @yHist4 = ();                # y coordinate history (4 fingers)
my @xHist5 = ();                # x coordinate history (5 fingers)
my @yHist5 = ();                # y coordinate history (5 fingers)

my $axis = 0;
my $rate = 0;
my $touchState = 0;             # touchState={0/1/2} 0=notSwiping, 1=Swiping, 2=edgeSwiping
my $lastTime = 0;               # time monitor for TouchPad event reset
my $eventTime = 0;              # ensure enough time has passed between events
my @eventString = ("default");  # the event to execute

my $currWind = GetInputFocus();
die "couldn't get input window" unless $currWind;
open(INFILE,"synclient -m 10 |") or die "can't read from synclient";

while(my $line = <INFILE>){
    chomp($line);
    my($time, $x, $y, $z, $f, $w) = split " ", $line;
    next if($time =~ /time/); #ignore header lines
    if($time - $lastTime > 5){
        &initSynclient($naturalScroll);
    }#if time reset
    $lastTime = $time;
    $axis = 0;
    $rate = 0;
    if($f == 1){
        if($touchState == 0){
            if(($x < $innerEdgeLeft)or($innerEdgeRight < $x)){
                $touchState = 2;
                &switchTouchPad("Off");
            }else{
                $touchState = 1;
            }
        }
        cleanHist(2 ,3 ,4 ,5);
        if ($touchState == 2){
            push @xHist1, $x;
            push @yHist1, $y;
            $axis = getAxis(\@xHist1, \@yHist1, 2, 0.1);
            if($axis eq "x"){
                $rate = getRate(@xHist1);
                $touchState = 2;
            }elsif($axis eq "y"){
                $rate = getRate(@yHist1);
                $touchState = 2;
            }
        }

    }elsif($f == 2){
        if($touchState == 0){
            if(
                ($x < $innerEdgeLeft) or ($innerEdgeRight  < $x)
           # or ($y < $innerEdgeTop ) or ($innerEdgeBottom < $y)
            ){
                $touchState = 2;
                ### $touchState
            }else{
                $touchState = 1;
            }
        }
        cleanHist(1, 3, 4, 5);
        push @xHist2, $x;
        push @yHist2, $y;
        $axis = getAxis(\@xHist2, \@yHist2, 2, 0.1);
        if($axis eq "x"){
            $rate = getRate(@xHist2);
        }elsif($axis eq "y"){
            $rate = getRate(@yHist2);
        }elsif($axis eq "z"){
            $axis = getAxis(\@xHist2, \@yHist2, 30, 0.5);
            if($axis eq "z"){
            }
        }

    }elsif($f == 3){
        if($touchState == 0 ){
            if(($y < $innerEdgeTop)or($innerEdgeBottom < $y)){
                $touchState = 2;
                ### $touchState
            }else{
                $touchState = 1;
            }
        }
        cleanHist(1, 2, 4, 5);
        push @xHist3, $x;
        push @yHist3, $y;
        $axis = getAxis(\@xHist3, \@yHist3, 5, 0.5);
        if($axis eq "x"){
            $rate = getRate(@xHist3);
        }elsif($axis eq "y"){
            $rate = getRate(@yHist3);
        }elsif($axis eq "z"){
            $axis = getAxis(\@xHist3, \@yHist3, 30, 0.5);
            if($axis eq "z"){
            }
        }

    }elsif($f == 4){
        if($touchState == 0 ){
            if(($y < $innerEdgeTop)or($innerEdgeBottom < $y)){
                $touchState = 2;
                ### $touchState
            }else{
                $touchState = 1;
            }
        }
        cleanHist(1, 2, 3, 5);
        push @xHist4, $x;
        push @yHist4, $y;
        $axis = getAxis(\@xHist4, \@yHist4, 5, 0.5);
        if($axis eq "x"){
            $rate = getRate(@xHist4);
        }elsif($axis eq "y"){
            $rate = getRate(@yHist4);
        }elsif($axis eq "z"){
            $axis = getAxis(\@xHist4, \@yHist4, 30, 0.5);
            if($axis eq "z"){
            }
        }

    }elsif($f == 5){
        if($touchState == 0 ){
            if(($y < $innerEdgeTop)or($innerEdgeBottom < $y)){
                $touchState = 2;
                ### $touchState
            }else{
                $touchState = 1;
            }
        }
        cleanHist(1, 2, 3 ,4);
        push @xHist5, $x;
        push @yHist5, $y;
        $axis = getAxis(\@xHist5, \@yHist5, 5, 0.5);
        if($axis eq "x"){
            $rate = getRate(@xHist5);
        }elsif($axis eq "y"){
            $rate = getRate(@yHist5);
        }
    }else{
        cleanHist(1, 2, 3, 4, 5);
        if($touchState > 0){
            $touchState = 0; #touchState Reset
            &switchTouchPad("On");
        }
    }


#detect action
    if ($axis ne 0){
        @eventString = setEventString($f,$axis,$rate,$touchState);
        cleanHist(1, 2, 3, 4, 5);
    }

# only process one event per time window
    if( $eventString[0] ne "default" ){
        ### ne default
        if( abs($time - $eventTime) > 0.3 ){
            ### $time - $eventTime got: $time - $eventTime
            $eventTime = $time;
            PressKey $_ foreach(@eventString);
            ReleaseKey $_ foreach(reverse @eventString);
            ### @eventString
        }# if enough time has passed
        @eventString = ("default");
    }#if non default event
}#synclient line in
close(INFILE);

###init
sub initSynclient{
    ### initSynclient
    my $naturalScroll = $_[0];
    if($naturalScroll == 1){
        $confFileName = $nScrollConfFileName;
        `synclient VertScrollDelta=-$VertScrollDelta HorizScrollDelta=-$HorizScrollDelta ClickFinger3=1 TapButton3=2`;
    }else{
        `synclient VertScrollDelta=$VertScrollDelta HorizScrollDelta=$HorizScrollDelta ClickFinger3=1 TapButton3=2`;
    }
}

sub switchTouchPad{
    open(TOUCHPADOFF,"synclient -l | grep TouchpadOff |") or die "can't read from synclient";
    my $TouchpadOff = <TOUCHPADOFF>;
    close(TOUCHPADOFF);
    chomp($TouchpadOff);
    my $TouchpadOff = (split "= ", $TouchpadOff)[1];
    ### $TouchpadOff
    my $switch_flag = shift;
    ### $switch_flag
    if($switch_flag eq 'Off'){
        if($TouchpadOff eq '0'){
            `synclient TouchPadOff=1`;
        }
    }elsif($switch_flag eq 'On'){
        if($TouchpadOff eq '1' ){
            `synclient TouchPadOff=0`;
        }
    }
}



sub getAxis{
    my($xHist, $yHist, $max, $thresholdRate)=@_;
    if(@$xHist > $max or @$yHist > $max){
        my $x0 = @$xHist[0];
        my $y0 = @$yHist[0];
        my $xmax = @$xHist[$max];
        my $ymax = @$yHist[$max];
        my $xDist = abs( $x0 - $xmax );
        my $yDist = abs( $y0 - $ymax );
        if($xDist > $yDist){
            if($xDist > $xMinThreshold * $thresholdRate){
                return "x";
            }else{
                return "z";
            }
        }else{
            if($yDist > $yMinThreshold * $thresholdRate){
                return "y";
            }else{
                return "z";
            }
        }
    }
    return 0;
}

sub getRate{
    my @hist = @_;
    my @srt    = sort {$a <=> $b} @hist;
    my @revSrt = sort {$b <=> $a} @hist;
    if( "@srt" eq "@hist" ){
        return "+";
    }elsif( "@revSrt" eq "@hist" ){
        return "-";
    }#if forward or backward
    return 0;
}

sub cleanHist{
    while(my $arg = shift){
        if($arg == 1){
            @xHist1 = ();
            @yHist1 = ();
        }elsif($arg == 2){
            @xHist2 = ();
            @yHist2 = ();
        }elsif($arg == 3){
            @xHist3 = ();
            @yHist3 = ();
        }elsif($arg == 4){
            @xHist4 = ();
            @yHist4 = ();
        }elsif($arg == 5){
            @xHist5 = ();
            @yHist5 = ();
        }
    }
}

#return @eventString $_[0]
sub setEventString{
    my($f, $axis, $rate, $touchState)=@_;
    if($f == 2){
        if($axis eq "x"){
            if($rate eq "+"){
                if($touchState eq "2"){
                    return @edgeSwipe2Right;
                }
            }elsif($rate eq "-"){
                if($touchState eq "2"){
                    return @edgeSwipe2Left;
                }
            }
        }elsif($axis eq "z"){
            if($rate eq "0"){
                if($touchState eq "1"){
                    return @longPress2;
                }
            }
        }
    }elsif($f == 3){
        if($axis eq "x"){
            if($rate eq "+"){
                return @swipe3Right;
            }elsif($rate eq "-"){
                return @swipe3Left;
            }
        }elsif($axis eq "y"){
            if($rate eq "+"){
                if($touchState eq "2"){
                    return @edgeSwipe3Down;
                }
                return @swipe3Down;
            }elsif($rate eq "-"){
                if($touchState eq "2"){
                    return @edgeSwipe3Up;
                }
                return @swipe3Up;
            }
        }elsif($axis eq "z"){
            if($rate eq "0"){
                return @longPress3;
            }
        }
    }elsif($f == 4){
        if($axis eq "x"){
            if($rate eq "+"){
                return @swipe4Right;
            }elsif($rate eq "-"){
                return @swipe4Left;
            }
        }elsif($axis eq "y"){
            if($rate eq "+"){
                if($touchState eq "2"){
                    return @edgeSwipe4Down;
                }
                return @swipe4Down;
            }elsif($rate eq "-"){
                if($touchState eq "2"){
                    return @edgeSwipe4Up;
                }
                return @swipe4Up;
            }
        }elsif($axis eq "z"){
            if($rate eq "0"){
                return @longPress4;
            }
        }
    }elsif($f == 5){
        if($axis eq "x"){
            if($rate eq "+"){
                return @swipe5Right;
            }elsif($rate eq "-"){
                return @swipe5Left;
            }
        }elsif($axis eq "y"){
            if($rate eq "+"){
                return @swipe5Down;
            }elsif($rate eq "-"){
                return @swipe5Up;
            }
        }elsif($axis eq "z"){
            if($rate eq "0"){
                return @longPress5;
            }
        }
    }
    return "default";
}

