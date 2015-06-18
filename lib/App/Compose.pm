package Compose;

use strict;
use warnings;
use diagnostics;

use REST::Client;
use JSON::PP;

sub show_new_post_form {

    my $author_name  = User::get_logged_in_author_name(); 
    my $session_id   = User::get_logged_in_session_id(); 

    my $query_string = "/?author=$author_name&session_id=$session_id";
    my $api_url      = Config::get_value_for("api_url") . '/users/' . $author_name;
    my $rest = REST::Client->new();
    $api_url .= $query_string;
    $rest->GET($api_url); 
    my $rc = $rest->responseCode();
    my $json = decode_json $rest->responseContent();
    if ( $rc >= 200 and $rc < 300 and $json->{'is_logged_in'} ) {
        my $t = Page->new("newpostform");
        $t->display_page("Compose new post");
    } elsif ( $rc >= 400 and $rc < 500 ) {
        Page->report_error("user", "Unable to peform action.", "You are not logged in.");
    } else  {
        Page->report_error("user", "Unable to complete request.", "Invalid response code returned from API.");
    }
}

sub show_splitscreen_form {
    my $author_name  = User::get_logged_in_author_name(); 
    my $session_id   = User::get_logged_in_session_id(); 

    my $query_string = "/?author=$author_name&session_id=$session_id";
    my $api_url      = Config::get_value_for("api_url") . '/users/' . $author_name;
    my $rest = REST::Client->new();
    $api_url .= $query_string;
    $rest->GET($api_url); 
    my $rc = $rest->responseCode();
    my $json = decode_json $rest->responseContent();
    if ( $rc >= 200 and $rc < 300 and $json->{'is_logged_in'} ) {
        my $t = Page->new("splitscreenform");
        $t->set_template_variable("action", "addarticle");
        $t->set_template_variable("api_url", Config::get_value_for("api_url"));
        $t->set_template_variable("post_id", 0);
        $t->set_template_variable("post_rev", "undef");
        $t->display_page_min("Creating Post - Split Screen");
    } elsif ( $rc >= 400 and $rc < 500 ) {
        Page->report_error("user", "Unable to peform action.", "You are not logged in.");
    } else  {
        Page->report_error("user", "Unable to complete request.", "Invalid response code returned from API.");
    }
}

1;
