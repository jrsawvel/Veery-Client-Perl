package ChangeStatus;

use strict;
use warnings;

use REST::Client;
use JSON::PP;

sub delete_post {
    my $tmp_hash = shift; # ref to hash
    my $post_id = $tmp_hash->{one};
    _change_post_status("delete", $post_id);
}

sub undelete_post {
    my $tmp_hash = shift; # ref to hash
    my $post_id = $tmp_hash->{one};
    _change_post_status("undelete", $post_id);
}

sub _change_post_status {
    my $action  = shift;
    my $post_id = shift;

    my $author_name  = User::get_logged_in_author_name(); 
    my $session_id   = User::get_logged_in_session_id(); 
    my $query_string = "/?author=$author_name&session_id=$session_id";

    my $api_url = Config::get_value_for("api_url") . "/posts/" . $post_id;
    my $rest = REST::Client->new();
    $api_url .= $query_string . "&action=$action";
    $rest->GET($api_url);
 
    my $rc = $rest->responseCode();
    my $json = decode_json $rest->responseContent();

    if ( $rc >= 200 and $rc < 300 ) {
        my $url = Config::get_value_for("home_page");
        my $q = new CGI;
        print $q->redirect( -url => $url);
        exit;
    } elsif ( $rc >= 400 and $rc < 500 ) {
        if ( $rc == 401 ) {
            Page->report_error("user", "Unable to complete action.", "You are not logged in.");
        } else {
            Page->report_error("user", "$json->{user_message}", $json->{system_message});
        }
    } else  {
        Page->report_error("user", "Unable to complete request.", "Invalid response code returned from API.");
    }
}

1;

