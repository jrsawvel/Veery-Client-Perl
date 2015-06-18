package DateTime;

use strict;
use warnings;
use diagnostics;

use Time::Local;

sub format_date_time{
    my $orig_dt = shift;

    my @tmp_array = split(/ /, $orig_dt);

    my $date = $tmp_array[0];
    my $time = $tmp_array[1];

    my @date_array = split(/\//, $date);

    my %hash = ();
 
    my @short_month_names = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
    
    my $formatted_dt = sprintf "%s %d, %d %s Z", $short_month_names[$date_array[1]-1], $date_array[2], $date_array[0], $time;

    return $formatted_dt;
}

1;
