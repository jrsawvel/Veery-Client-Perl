package CreatePost;

use strict;

use REST::Client;
use JSON::PP;
use HTML::Entities;
use Encode;
use App::CacheHtml;

sub create_post {

    my $logged_in_author_name  = User::get_logged_in_author_name(); 
    my $session_id             = User::get_logged_in_session_id(); 

    my $q = new CGI;
    my $submit_type     = $q->param("sb"); # Preview or Post 
    my $post_location   = $q->param("post_location"); # notes_stream or ?
    my $original_markup = $q->param("markup");

    my $markup = Encode::decode_utf8($original_markup);
    $markup = HTML::Entities::encode($markup,'^\n^\r\x20-\x25\x27-\x7e');

    my $api_url = Config::get_value_for("api_url");

    my $json_input;

    my $hash = {
        'author'      => $logged_in_author_name,
        'session_id'  => $session_id,
        'submit_type' => $submit_type,
        'markup'      => $markup,
    };

    my $json_input = encode_json $hash;

    my $headers = {
        'Content-type' => 'application/json'
    };

    my $rest = REST::Client->new( {
        host => $api_url,
    } );

    $rest->POST( "/posts" , $json_input , $headers );

    my $rc = $rest->responseCode();

    my $json = decode_json $rest->responseContent();

    if ( $rc >= 200 and $rc < 300 ) {
        if ( $submit_type eq "Post" ) {
            CacheHtml::create_and_cache_page($json->{'post_id'});
            if ( $post_location eq "notes_stream" ) {
                my $home_page = Config::get_value_for("home_page");
                print $q->redirect( -url => $home_page);
                exit;
            } else {
                my $home_page = Config::get_value_for("home_page");
                print $q->redirect( -url => $home_page . "/" . $json->{'post_id'} );
                exit;
            }
        } elsif ( $submit_type eq "Preview" ) {
            my $t = Page->new("newpostform");
            my $html = $json->{html};
            $t->set_template_variable("previewingpost", 1);
            $t->set_template_variable("html", $html);
            $t->set_template_variable("markup", $original_markup);
            $t->display_page("Previewing new post");
            exit;
        }
    } elsif ( $rc >= 400 and $rc < 500 ) {
         Page->report_error("user", $json->{description}, "$json->{user_message} $json->{system_message}");
    } else  {
        Page->report_error("user", "Unable to complete request. Invalid response code returned from API.", "$json->{user_message} $json->{system_message}");
    }
}

1;
