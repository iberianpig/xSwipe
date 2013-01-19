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

my $naturalScroll=0;
my $baseDist=1;
my $confFileName="eventKey.cfg";
my $NscrollConfFileName="nScroll/eventKey.cfg";

while(my $ARGV = shift){
  ### $ARGV got:$ARGV
  if ($ARGV eq '-n'){
    $naturalScroll=1; 
  }elsif ($ARGV eq '-d'){
    if ($ARGV[0]>0){
      $baseDist=$ARGV[0];
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

open (Scroll_setting, "synclient -l | grep ScrollDelta | grep -v -e Circ | ")or die "can't synclient -l";
my @Scroll_setting = <Scroll_setting>;
close(fileHundle);
my $VertScrollDelta=abs((split "= ", $Scroll_setting[0])[1]);
my $HorizScrollDelta=abs((split "= ", $Scroll_setting[1])[1]);

&initSynclient($naturalScroll);

open (area_setting, "synclient -l | grep Edge | grep -v -e Area -e Motion -e Scroll | ")or die "can't synclient -l";
my @area_setting = <area_setting>;
close(fileHundle);
my $LeftEdge=(split "= ", $area_setting[0])[1];
my $RightEdge=(split "= ", $area_setting[1])[1];
my $TopEdge=(split "= ", $area_setting[2])[1];
my $BottomEdge=(split "= ", $area_setting[3])[1];
my $TouchpadSizeH = abs($TopEdge-$BottomEdge);
my $TouchpadSizeW = abs($LeftEdge-$RightEdge);
my $xSwipeDist = $TouchpadSizeW*$baseDist*0.1;
my $ySwipeDist = $TouchpadSizeH*$baseDist*0.1;
### @area_setting
### $TouchpadSizeH
### $TouchpadSizeW
### $xSwipeDist got:$xSwipeDist
### $ySwipeDist got:$ySwipeDist

my $edgeSwipeLeftEdge=$LeftEdge+$xSwipeDist;
my $edgeSwipeRightEdge=$RightEdge-$xSwipeDist;
### $edgeSwipeLeftEdge got:$edgeSwipeLeftEdge
### $edgeSwipeRightEdge got:$edgeSwipeRightEdge

#load config
my $script_dir = $FindBin::Bin;#CurrentPath
my $conf = require $script_dir."/".$confFileName;
my $command = qq{pgrep -lf ^gnome-session};
open (fileHundle, " $command |")or die "can't pgrep -lf ^gnome-session";
my @data = <fileHundle>;
my $sessionName = (split "session=", $data[0])[1];
close(fileHundle);
chomp($sessionName);
if ($sessionName eq undef){$sessionName='other'};
### $command
### $sessionName

my @swipeRight3=split "/", ($conf->{$sessionName}->{finger3}->{right});
my @swipeLeft3=split "/", ($conf->{$sessionName}->{finger3}->{left});
my @swipeDown3=split "/", ($conf->{$sessionName}->{finger3}->{down});
my @swipeUp3=split "/", ($conf->{$sessionName}->{finger3}->{up});
my @swipeRight4=split "/", ($conf->{$sessionName}->{finger4}->{right});
my @swipeLeft4=split "/", ($conf->{$sessionName}->{finger4}->{left});
my @swipeDown4=split "/", ($conf->{$sessionName}->{finger4}->{down});
my @swipeUp4=split "/", ($conf->{$sessionName}->{finger4}->{up});
my @swipeRight5=split "/", ($conf->{$sessionName}->{finger5}->{right});
my @swipeLeft5=split "/", ($conf->{$sessionName}->{finger5}->{left});
my @swipeDown5=split "/", ($conf->{$sessionName}->{finger5}->{down});
my @swipeUp5=split "/", ($conf->{$sessionName}->{finger5}->{up});
my @edgeSwipeRight=split "/", ($conf->{$sessionName}->{edgeSwipe}->{right});
my @edgeSwipeLeft=split "/", ($conf->{$sessionName}->{edgeSwipe}->{left});
my @longPress3=split "/", ($conf->{$sessionName}->{finger3}->{press});
my @longPress4=split "/", ($conf->{$sessionName}->{finger4}->{press});

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
my $axis=0;
my $rate=0;
my $lastTime = 0;              # time monitor for TouchPad event reset
my $eventTime = 0;             # ensure enough time has passed between events
my @eventString= ("default");   # the event to execute

my $synCmd = qq{synclient -m 10};
my $currWind = GetInputFocus();
die "couldn't get input window" unless $currWind;
open(INFILE," $synCmd |") or die "can't read from synclient";

while( my $line  = <INFILE>){
  chomp($line);
  my($time, $x, $y, $z, $f, $w) = split " ", $line;
  next if( $time =~ /time/ ); #ignore header lines

  if( $time - $lastTime > 0.1 ){
    cleanHist(1,2,3,4,5);
    if( $time - $lastTime > 5 ){
      &initSynclient($naturalScroll);
    }
  }#if time reset
  $lastTime = $time;
  $axis=0;
  $rate=0;

  if($f==1){
    cleanHist(2,3,4,5);
    if ($x<$edgeSwipeLeftEdge){
      ###edge1left
      push @xHist1, $x;
      push @yHist1, $y;
    }elsif ($edgeSwipeRightEdge<$x){
      ###edge1right
      push @xHist1, $x;
      push @yHist1, $y;
    }
  }elsif($f==2 and @xHist1>0){
    ###edge2
    cleanHist(3,4,5);
    push @xHist2, $x;
    push @yHist2, $y;
    $axis=getAxis(\@xHist2,\@yHist2,3,0.3);
    if($axis eq "x"){
      $rate=getRate(@xHist2);
    }elsif($axis eq "y"){
      $rate=getRate(@yHist2);  
    }
  }elsif($f==3){
    cleanHist(1,2,4,5);
    push @xHist3, $x;
    push @yHist3, $y;
    $axis=getAxis(\@xHist3,\@yHist3,10,1);
    if($axis eq "x"){
      $rate=getRate(@xHist3);
    }elsif($axis eq "y"){
      $rate=getRate(@yHist3);  
    }elsif($axis eq "z"){
      $axis=getAxis(\@xHist3,\@yHist3,30,0.5);
      if($axis eq "z"){
        ###press###########################
      }
    }

  }elsif($f==4){
    cleanHist(1,2,3,5);  
    push @xHist4, $x;
    push @yHist4, $y;
    $axis=getAxis(\@xHist4,\@yHist4,10,1);
    if($axis eq "x"){
      $rate=getRate(@xHist4);
    }elsif($axis eq "y"){
      $rate=getRate(@yHist4);  
    }elsif($axis eq "z"){
      $axis=getAxis(\@xHist4,\@yHist4,30,0.5);
      if($axis eq "z"){
        ###press###########################
      }
    }

  }elsif($f==5){
    cleanHist(1,2,3,4);
    push @xHist5, $x;
    push @yHist5, $y;
    $axis=getAxis(\@xHist5,\@yHist5,10,1);
    if($axis eq "x"){
      $rate=getRate(@xHist5);
    }elsif($axis eq "y"){
      $rate=getRate(@yHist5);
    }
  }else{
    cleanHist(1,2,3,4,5);  
  }

  if ($axis ne 0 and $rate ne 0){
    swipe($f,$axis,$rate);
    cleanHist(1,2,3,4,5);
  }elsif ($axis eq "z" and $rate eq "0"){
    swipe($f,$axis,$rate);
    cleanHist(1,2,3,4,5);
  } 
  # only process one event per time window
  if( $eventString[0] ne "default" ){
    ### ne default
    if( abs($time - $eventTime) > 0.3 ){
      ### $time - $eventTime got: $time - $eventTime
      $eventTime = $time;
      PressKey $_ foreach(@eventString); 
      ReleaseKey $_ foreach(reverse @eventString);
      ### @eventString got:@eventString 
    }#if enough time has passed
    @eventString = ("default");
  }#if non default event
}#synclient line in

close(INFILE);

###init
sub initSynclient{
  ### initSynclient
  my $naturalScroll=$_[0];
  if($naturalScroll==1){
    $confFileName=$NscrollConfFileName;
    `synclient VertScrollDelta=-$VertScrollDelta HorizScrollDelta=-$HorizScrollDelta ClickFinger3=1 TapButton3=2`;
  }else{
    `synclient VertScrollDelta=$VertScrollDelta HorizScrollDelta=$HorizScrollDelta ClickFinger3=1 TapButton3=2`;
  }
}


sub getRate{
  my @hist=();
  my $rtn=0;
  my @srt =();
  my @revSrt =();  
  @hist=@_;
  my @srt = sort {$a <=> $b} @hist;
  my @revSrt = sort {$b <=> $a} @hist;
  if( "@srt" eq "@hist" ){
      $rtn = "+";
  }elsif( "@revSrt" eq "@hist" ){ 
      $rtn = "-";
  }#if forward or backward
  return $rtn;
}

sub getAxis{
  my($xHist, $yHist, $max, $DistRate)=@_;
  my $rtn =0;
  if(@$xHist>$max or @$yHist>$max){
    my $x0=@$xHist[0];
    my $y0=@$yHist[0];
    my $xmax=@$xHist[$max];
    my $ymax=@$yHist[$max];
    my $xDist = abs( $x0 - $xmax );
    my $yDist = abs( $y0 - $ymax );
    if($xDist > $yDist){
      if($xDist > $xSwipeDist*$DistRate){
        $rtn="x";
      }else{
        $rtn="z";
      }
    }else{
      if($yDist > $ySwipeDist*$DistRate){
        $rtn="y";
      }else{
        $rtn="z";
      }
    }
  }
  ### $rtn
  return $rtn;
}

sub cleanHist{
  ### cleanHist 
  while(my $arg = shift){
    if($arg==1){
      @xHist1 = ();
      @yHist1 = ();
    }elsif($arg==2){
      @xHist2 = ();
      @yHist2 = ();
    }elsif($arg==3){
      @xHist3 = ();
      @yHist3 = ();
    }elsif($arg==4){
      @xHist4 = ();
      @yHist4 = ();
    }elsif($arg==5){
      @xHist5 = ();
      @yHist5 = ();
    }
  }
}

#decide to send event
sub swipe{
  if($_[0]==2){
    if($_[1] eq "x"){
      if($_[2] eq"+"){
        @eventString = @edgeSwipeRight;
      }elsif($_[2] eq "-"){
        @eventString = @edgeSwipeLeft;
      }
    }
  }elsif($_[0]==3){
    if($_[1] eq "x"){
      if($_[2] eq"+"){
        @eventString = @swipeRight3;
      }elsif($_[2] eq "-"){
        @eventString = @swipeLeft3;
      }
    }elsif($_[1] eq "y"){
      if($_[2] eq "+"){
        @eventString = @swipeDown3;
      }elsif($_[2] eq "-"){
        @eventString = @swipeUp3;
      }
    }elsif($_[1] eq "z"){
      if($_[2] eq "0"){
        @eventString = @longPress3;
      }
    }
  }elsif($_[0]==4){
    if($_[1] eq "x"){
      if($_[2] eq "+"){
        @eventString = @swipeRight4;
      }elsif($_[2] eq "-"){
        @eventString = @swipeLeft4;
      }
    }elsif($_[1] eq "y"){
      if($_[2] eq "+"){
        @eventString = @swipeDown4;
      }elsif($_[2] eq "-"){
        @eventString = @swipeUp4;
      }
    }elsif($_[1] eq "z"){
      if($_[2] eq "0"){
        @eventString = @longPress4;
      }
    }
  }elsif($_[0]==5){
    if($_[1] eq "x"){
      if($_[2] eq "+"){
        @eventString = @swipeRight5;
      }elsif($_[2] eq "-"){
        @eventString = @swipeLeft5;
      }
    }elsif($_[1] eq "y"){
      if($_[2] eq "+"){
        @eventString = @swipeDown5;
      }elsif($_[2] eq "-"){
        @eventString = @swipeUp5;
      }
    }
  }
  return @eventString;
}
