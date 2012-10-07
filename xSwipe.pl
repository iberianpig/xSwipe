#!/usr/bin/perl

use strict;
use Time::HiRes();
use X11::GUITest qw( :ALL );
use FindBin;
#debug
#use Smart::Comments;

my @xHist3 = ();              # x coordinate history (3 fingers)
my @yHist3 = ();              # y coordinate history (3 fingers)
my @xHist4 = ();              # x coordinate history (4 fingers)
my @yHist4 = ();              # y coordinate history (4 fingers)
my @xHist5 = ();              # x coordinate history (5 fingers)
my @yHist5 = ();              # y coordinate history (5 fingers)


my $axis="0";
my $rate="0";
my $lastTime = 0;             # time monitor for TouchPad event reset
my $eventTime = 0;            # ensure enough time has passed between events
my $eventString = "default";  # the event to execute
my $synCmd = qq{synclient TapButton3=2 ClickFinger3=1 && synclient TouchpadOff=1 -m 10};
my $currWind = GetInputFocus();
die "couldn't get input window" unless $currWind;
open(INFILE," $synCmd |") or die "can't read from synclient";

#debug#
#my $windowName = GetWindowName($currWind);

#設定ファイル読込

my $command = qq{update-alternatives --display x-session-manager};
open (fileHundle, " $command |");
my @data = <fileHundle>;
my $sessionName = (split " ",(split "/", $data[1])[3])[0];
close(fileHundle);

### $sessionName got:$sessionName

my $script_dir = $FindBin::Bin;
#CurrentPath
my $confFileName="eventKey.cfg";
my $conf = require $script_dir."/".$confFileName;

### $conf= got:$conf

my $swipeRight3=$conf->{$sessionName}->{finger3}->{right};
my $swipeLeft3=$conf->{$sessionName}->{finger3}->{left};
my $swipeDown3=$conf->{$sessionName}->{finger3}->{down};
my $swipeUp3=$conf->{$sessionName}->{finger3}->{up};

my $swipeRight4=$conf->{$sessionName}->{finger4}->{right};
my $swipeLeft4=$conf->{$sessionName}->{finger4}->{left};
my $swipeDown4=$conf->{$sessionName}->{finger4}->{down};
my $swipeUp4=$conf->{$sessionName}->{finger4}->{up};

my $swipeRight5=$conf->{$sessionName}->{finger5}->{right};
my $swipeLeft5=$conf->{$sessionName}->{finger5}->{left};
my $swipeDown5=$conf->{$sessionName}->{finger5}->{down};
my $swipeUp5=$conf->{$sessionName}->{finger5}->{up};

while( my $line  = <INFILE>){

    #$currWind = GetInputFocus();
    #$windowName=GetWindowName(GetInputFocus()-1)|| "NoWindowName";
    ## got:$currWind
    ## got:$windowName

    #~ foreach(@WindowIds){
        #~ if($_==$currWind-1){
            #~ print "this Window is gedit's";
        #~ }
    #~ }

    chomp($line);
    my($time, $x, $y, $z, $f, $w) = split " ", $line;
    next if( $time =~ /time/ ); #ignore header lines

    if( $time - $lastTime > 0.5 ){
        @xHist3 = ();
        @yHist3 = ();
        @xHist4 = ();
        @yHist4 = ();
        @xHist5 = ();
        @yHist5 = ();
    }#if time reset

    $lastTime = $time;

	$axis="0";
	$rate="0";
	
	
	if($f==3){
		cleanHist(4,5);
        push @xHist3, $x;
        push @yHist3, $y;
        ### $axis before = got:$axis 
        $axis=getAxis(\@xHist3,\@yHist3);
        ### $axis after = got:$axis
        if($axis eq "x"){
			### x got:$axis
			$rate=getRate(@xHist3);
		}elsif($axis eq "y"){
			### y got:$axis
			$rate=getRate(@yHist3);	
		}

	}elsif($f==4){
		cleanHist(3,5);	
		push @xHist4, $x;
        push @yHist4, $y;
        $axis=getAxis(\@xHist4,\@yHist4);
        if($axis eq "x"){
			$rate=getRate(@xHist4);
			
		}elsif($axis eq "y"){
			$rate=getRate(@yHist4);	
		}
    
	}elsif($f==5){
		cleanHist(3,4);
		push @xHist5, $x;
        push @yHist5, $y;
        $axis=getAxis(\@xHist5,\@yHist5);
        if($axis eq "x"){
			$rate=getRate(@xHist5);
			
		}elsif($axis eq "y"){
			$rate=getRate(@yHist5);	
		}
	}else{
		#clean all history;
		cleanHist(3,4,5)
		
		}

	if ($axis ne "0" and $rate ne "0"){
		swipe($f,$axis,$rate);
		cleanHist($f);

	}
	
    # only process one event per time window
    if( $eventString ne "default" ){
        if( abs(time - $eventTime) > 0.5 ){
            $eventTime = time;
            SendKeys( "$eventString");
        }#if enough time has passed
        $eventString = "default";
    }#if non default event

}#synclient line in

close(INFILE);


sub getRate{
	my @hist=@_;
    my $rtn="0";
    my @srt = sort @hist;
    my @revSrt = reverse sort @hist;
    ## @hist = got:@hist
    ## @srt = got:@srt
    ## @revSrt = got:@revSrt
    
    if( "@srt" eq "@hist" ){
        $rtn = "+";
    }elsif( "@revSrt" eq "@hist" ){ 
        $rtn = "-";
    }#if forward or backward

	### $rate got:$rtn	
	return $rtn;
}

sub getAxis{
	###getAxis start
	my($xHist, $yHist)=@_;
	my $rtn ="0";
	if(@$xHist>5 or @$yHist>5){
		if( abs( @$xHist[0] - @$xHist[4] ) > abs( @$yHist[0] - @$yHist[4] )){
			## @$xHist[0] got:@$xHist[0]
			$rtn="x";
		}else{
			## @$yHist[0] got:@$yHist[0]
			$rtn="y";
		}
	}
	### getAxis rtn got:$rtn
	return $rtn;
}



sub cleanHist{
	if($_[0]==3 or $_[1]==3 or $_[2]==3){
        @xHist3 = ();
        @yHist3 = ();
	}elsif($_[0]==4 or $_[1]==4 or $_[2]==4){
        @xHist4 = ();
        @yHist4 = ();
	}elsif($_[0]==5 or $_[1]==5 or $_[2]==5){
        @xHist5 = ();
        @yHist5 = ();
	}
}


#decide to send event
sub swipe{
	if($_[0]==3){
		if($_[1] eq "x"){
			if($_[2] eq"+"){
				$eventString = $swipeRight3;
			}elsif($_[2] eq "-"){
				$eventString = $swipeLeft3;
			}
		}elsif($_[1] eq "y"){
			if($_[2] eq "+"){
				$eventString = $swipeDown3;
			}elsif($_[2] eq "-"){
				$eventString = $swipeUp3;
			}
		}
	}elsif($_[0]==4){
		if($_[1] eq "x"){
			if($_[2] eq "+"){
				$eventString = $swipeRight4;
			}elsif($_[2] eq "-"){
				$eventString = $swipeLeft4;
			}
		}elsif($_[1] eq "y"){
			if($_[2] eq "+"){
				$eventString = $swipeDown4;
			}elsif($_[2] eq "-"){
				$eventString = $swipeUp4;
			}
		}
	}elsif($_[0]==5){
		if($_[1] eq "x"){
			if($_[2] eq "+"){
				$eventString = $swipeRight5;
			}elsif($_[2] eq "-"){
				$eventString = $swipeLeft5;
			}
		}elsif($_[1] eq "y"){
			if($_[2] eq "+"){
				$eventString = $swipeDown5;
			}elsif($_[2] eq "-"){
				$eventString = $swipeUp5;
			}
		}
	}
	return $eventString;
}
