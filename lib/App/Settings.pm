package Settings;

use strict;
use warnings;
use diagnostics;

use REST::Client;
use JSON::PP;

# at the moment, the only item that can be modified is email address.
sub get_user_settings {

    my $author_name  = User::get_logged_in_author_name(); 
    my $session_id   = User::get_logged_in_session_id(); 
    my $query_string = "/?author=$author_name&session_id=$session_id";

    my $api_url = Config::get_value_for("api_url") . "/users/" . $author_name . "/" . $query_string; 
    my $rest = REST::Client->new();
    $rest->GET($api_url);
 
    my $rc = $rest->responseCode();
    my $json = decode_json $rest->responseContent();

    if ( $rc >= 200 and $rc < 300 ) {
        my $t = Page->new("settings");
        $t->set_template_variable("name",      $json->{'name'});
        $t->set_template_variable("old_email", $json->{'email'});
        $t->set_template_variable("id",        $json->{'_id'});
        $t->set_template_variable("rev",       $json->{'_rev'});
        $t->display_page("Update User Settings");
    } elsif ( $rc >= 400 and $rc < 500 ) {
        Page->report_error("user", $json->{'user_message'}, $json->{'system_message'}); 
    } else  {
        Page->report_error("user", "Unable to complete request.", "Invalid response code returned from API.");
    }
}

sub update_settings {

    my $q = new CGI;
    my $old_email = Utils::trim_spaces($q->param("old_email"));
    my $new_email = Utils::trim_spaces($q->param("new_email"));
    my $rev       = Utils::trim_spaces($q->param("rev"));
    my $id        = Utils::trim_spaces($q->param("id"));

    if ( !$old_email ) {
        Page->report_error("user", "Invalid input.", "Old email address was missing.");
    }

    if ( !$new_email ) {
        Page->report_error("user", "Invalid input.", "New email address was missing.");
    }

    my $headers = {
        'Content-type' => 'application/json'
    };

    my $rest = REST::Client->new( {
           host => Config::get_value_for("api_url"),
    } );

    my %hash;
    $hash{old_email}  = $old_email;
    $hash{new_email}  = $new_email;
    $hash{rev}        = $rev;
    $hash{id}         = $id;
    $hash{author}     = User::get_logged_in_author_name(); 
    $hash{session_id} = User::get_logged_in_session_id(); 

    my $json_input = encode_json \%hash;
    $rest->PUT( "/users" , $json_input , $headers );

    my $rc = $rest->responseCode();
    my $json = decode_json $rest->responseContent();

    if ( $rc >= 200 and $rc < 300 ) {
        Page->success("Updating user settings.", "Updating user settings.", "Changes were saved.");
    } elsif ( $rc >= 400 and $rc < 500 ) {
        Page->report_error("user", $json->{user_message}, $json->{system_message});
    } else  {
        Page->report_error("user", "Unable to complete request.", "Invalid response code returned from API. $json->{user_message} - $json->{system_message}");
    }
}

1;

