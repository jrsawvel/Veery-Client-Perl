package Utils;

use strict;
use warnings;
use diagnostics;

use Time::Local;

sub is_numeric {
    my $str = shift;
    my $rc = 0;
    return $rc if !$str;
    if ( $str =~ m|^[0-9]+$| ) {
        $rc = 1;
    }
    return $rc;
}

sub trim_spaces {
    my $str = shift;
    if ( !defined($str) ) {
        return "";
    }
    # remove leading spaces.   
    $str  =~ s/^\s+//;
    # remove trailing spaces.
    $str  =~ s/\s+$//;
    return $str;
}

sub remove_html {
    my $str = shift;
    # remove ALL html
    $str =~ s/<([^>])+>|&([^;])+;//gsx;
    return $str;
}

sub remove_newline {
    my $str = shift;
#    $str =~ s/[\r][\n]//gs;
#    $str =~ s/\n.*//s;
#    $str =~ s/\s.*//s;
    $str =~ s/\n//gs;
    return $str;
}

# receives date string as: YYYY-MM-DD HH-MM-SS
# date format used in database date field
# code from: http://stackoverflow.com/users/4234/dreeves
# in post: http://stackoverflow.com/questions/95492/how-do-i-convert-a-date-time-to-epoch-time-aka-unix-time-seconds-since-1970
# I changed timelocal to timegm
sub convert_date_to_epoch {
  my($s) = @_;
  my($year, $month, $day, $hour, $minute, $second);

  if($s =~ m{^\s*(\d{1,4})\W*0*(\d{1,2})\W*0*(\d{1,2})\W*0*
                 (\d{0,2})\W*0*(\d{0,2})\W*0*(\d{0,2})}x) {
    $year = $1;  $month = $2;   $day = $3;
    $hour = $4;  $minute = $5;  $second = $6;
    $hour |= 0;  $minute |= 0;  $second |= 0;  # defaults.
    $year = ($year<100 ? ($year<70 ? 2000+$year : 1900+$year) : $year);
    return timegm($second,$minute,$hour,$day,$month-1,$year);  
  }
  return -1;

}

1;
