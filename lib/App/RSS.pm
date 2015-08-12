package RSS;

use strict;
use warnings;
use diagnostics;

use HTML::Entities;

use App::DateTimeFormatter;

# the home page stream in rss format
sub __create_rss {
    my $stream = shift;

    my $app_name         = Config::get_value_for("app_name");
    my $home_page        = "http://" . Config::get_value_for("domain_name");
    my $site_name        = Config::get_value_for("site_name");
    my $site_description = Config::get_value_for("site_description");

    # Mon, 16 Jun 2014 17:37:35 GMT
    my $current_date_time = DateTimeFormatter::create_date_time_stamp_utc("(dayname), (0daynum) (monthname) (yearfull) (24hr):(0min):(0sec) GMT");

    my @rss_articles = ();
    foreach my $hash_ref ( @$stream ) {
        my %hash = ();

        $hash{posttext} = $hash_ref->{text_intro};


#        if ( $hash_ref->{text_intro} =~ m{^\s*<span class="streamtitle"><a href="(.*?)">(.*?)</a></span> -\s*(.*?)$}m ) {
#            $hash{title}    = encode_entities($2);
#            $hash{posttext} = $3;
#        } else {
#            $hash{title} = $hash_ref->{slug};
#        }

        $hash{title} = $hash_ref->{title}; 
        if ( $hash_ref->{post_type} eq "note" ) {
            $hash{title} = $hash_ref->{slug};
        }

        $hash{posttext} = Utils::trim_spaces($hash{posttext});
        $hash{posttext} = Utils::remove_newline($hash{posttext}); # not working?? - todo - verify - plus why remove newline?
        $hash{posttext} = Utils::remove_html($hash{posttext});
        $hash{posttext} = encode_entities($hash{posttext});

        $hash{modified_date} = DateTimeFormatter::create_date_time_stamp_utc(Utils::convert_date_to_epoch($hash_ref->{updated_at}), "(dayname), (0daynum) (monthname) (yearfull) (24hr):(0min):(0sec) GMT");
        
        $hash{articleid}    = $hash_ref->{slug};

#        $hash{author}       = $hash_ref->{author};
        $hash{home_page}    = $home_page;

        push(@rss_articles, \%hash);
    }

    my $t = Page->new("rss");
    $t->set_template_loop_data("article_loop", \@rss_articles);

    $t->set_template_variable("description", "Stream by Updated Date");
    $t->set_template_variable("app_name", $app_name);
    $t->set_template_variable("site_name", $site_name);
    $t->set_template_variable("site_description", $site_description);
    $t->set_template_variable("current_date_time", $current_date_time);
    $t->set_template_variable("link", $home_page);

    $t->print_template("Content-type: text/xml");
}


1;
