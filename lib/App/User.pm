package User;

use strict;
use warnings;
use diagnostics;

use REST::Client;
use JSON::PP;
use LWP::UserAgent;

my %user_hash           = _get_user_cookie_settings();

sub _get_user_cookie_settings {
    my $q = new CGI;
    my %h;
    my $cookie_prefix = Config::get_value_for("cookie_prefix");
    if ( defined($q->cookie($cookie_prefix. "session_id")) ) {
        $h{session_id}        = $q->cookie($cookie_prefix . "session_id");
        $h{author_name}       = $q->cookie($cookie_prefix . "author_name");
        $h{loggedin}          = 1;
    } else {
        $h{loggedin}          = 0;
        $h{session_id}        = -1;
    }
    return %h;
}

sub get_logged_in_flag {
    return $user_hash{loggedin};
}

sub get_logged_in_author_name {
    return $user_hash{author_name};
}

sub get_logged_in_session_id {
    return $user_hash{session_id};
}

sub show_login_form {
    my $t = Page->new("loginform");
    $t->display_page("Login Form");
}

sub do_login {

    my $q = new CGI;
    my $user_submitted_email = Utils::trim_spaces($q->param("email"));

    if ( !$user_submitted_email ) {
        Page->report_error("user", "Invalid input.", "No data was submitted.");
    }

    my $headers = {
        'Content-type' => 'application/json'
    };

    my $rest = REST::Client->new( {
           host => Config::get_value_for("api_url"),
    } );

    my %hash;
    $hash{email} = $user_submitted_email;
    $hash{url}   = Config::get_value_for("home_page") . "/nopwdlogin";

    my $json_input = encode_json \%hash;
    $rest->POST( "/users/login" , $json_input , $headers );

    my $rc = $rest->responseCode();
    my $json = decode_json $rest->responseContent();

    if ( $rc >= 200 and $rc < 300 ) {
        Page->success("Creating New Login Link", "A new login link has been created and sent.", "");
    } elsif ( $rc >= 400 and $rc < 500 ) {
        Page->report_error("user", "Unable to complete request.", "Invalid data provided.");
    } else  {
        Page->report_error("user", "Unable to complete request.", "Invalid response code returned from API. $json->{user_message} - $json->{system_message}");
    }
}

sub no_password_login {
    my $tmp_hash = shift; 

    my $error_exists = 0;

    my $q   = new CGI;
    my $rev = $tmp_hash->{one};

    if ( !$rev) {
        Page->report_error("user", "Unable to login.", "Insufficient data provided.");
    }

    my $api_url = Config::get_value_for("api_url") . "/users/login/?rev=$rev";

    my $ua = LWP::UserAgent->new;
    my $response = $ua->get($api_url);
    my $hash_ref = decode_json $response->content;
    my $rc       = $hash_ref->{'status'};

    if ( $rc >= 200 and $rc < 300 ) {
        my $savepassword    = "no";

        my $cookie_prefix = Config::get_value_for("cookie_prefix");
        my $cookie_domain = Config::get_value_for("domain_name");
        my $author_name   = $hash_ref->{'author_name'};
        my $session_id    = $hash_ref->{'session_id'};

        my ($c1, $c2);

        if ( $savepassword eq "yes" ) {
            $c1 = $q->cookie( -name => $cookie_prefix . "author_name",  -value => "$author_name", -path => "/",  -expires => "+10y",  -domain => ".$cookie_domain");
            $c2 = $q->cookie( -name => $cookie_prefix . "session_id",   -value => "$session_id",  -path => "/",  -expires => "+10y",  -domain => ".$cookie_domain");
        } else {
            $c1 = $q->cookie( -name => $cookie_prefix . "author_name",  -value => "$author_name", -path => "/",  -domain => ".$cookie_domain");
            $c2 = $q->cookie( -name => $cookie_prefix . "session_id",   -value => "$session_id",  -path => "/",  -domain => ".$cookie_domain");
        }

        my $url = Config::get_value_for("home_page");
        print $q->redirect( -url => $url, -cookie => [$c1,$c2] );
    } elsif ( $rc >= 400 and $rc < 500 ) {
        Page->report_error("user", $hash_ref->{'user_message'},  $hash_ref->{'system_message'}); 
    } else  {
        Page->report_error("user", "Unable to complete request.", "Invalid response code returned from API.");
    }
}

sub logout {

    my $author_name  = get_logged_in_author_name(); 
    my $session_id   = get_logged_in_session_id(); 
    my $query_string = "/?author=$author_name&session_id=$session_id";

    my $api_url = Config::get_value_for("api_url") . "/users/logout";
    my $rest = REST::Client->new();
    $api_url .= $query_string;

    $rest->GET($api_url);

    my $rc = $rest->responseCode();

    my $json = decode_json $rest->responseContent();

    if ( $rc >= 400 and $rc < 500 ) {
        Page->report_error("user", "$json->{user_message}", $json->{system_message});
    } elsif ( $rc >= 200 and $rc < 300 ) {
        my $q = new CGI;

        my $cookie_prefix = Config::get_value_for("cookie_prefix");
        my $cookie_domain = Config::get_value_for("domain_name");

        my $c1 = $q->cookie( -name => $cookie_prefix . "author_name",   -value => "0", -path => "/", -expires => "-10y", -domain => ".$cookie_domain");
        my $c2 = $q->cookie( -name => $cookie_prefix . "session_id",    -value => "0", -path => "/", -expires => "-10y", -domain => ".$cookie_domain");

        my $url = Config::get_value_for("home_page"); 
        print $q->redirect( -url => $url, -cookie => [$c1,$c2] );
    } else  {
        Page->report_error("user", "Unable to complete request.", "Invalid response code returned from API.");
    }
}

1;

