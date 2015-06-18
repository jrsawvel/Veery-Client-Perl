package EditPost;

use strict;
use warnings;
use diagnostics;

use REST::Client;
use JSON::PP;
use HTML::Entities;
use Encode;
use App::CacheHtml;

sub show_post_to_edit {
    my $tmp_hash = shift; 

    my $author_name  = User::get_logged_in_author_name(); 
    my $session_id   = User::get_logged_in_session_id(); 

    my $post_id = $tmp_hash->{one};

    my $query_string = "/?author=$author_name&session_id=$session_id&text=markup";

    my $api_url = Config::get_value_for("api_url") . "/posts/" . $post_id;

    my $rest = REST::Client->new();
    $api_url .= $query_string;
    $rest->GET($api_url);

    my $rc = $rest->responseCode();

    my $json = decode_json $rest->responseContent();

    if ( $rc >= 200 and $rc < 300 ) {
        my $post = $json->{'post'};
        my $t = Page->new("editpostform");
        $t->set_template_variable("slug",       $post->{'slug'});
        $t->set_template_variable("title",      $post->{'title'});
        $t->set_template_variable("rev",        $post->{'_rev'});
        # $t->set_template_variable("markup_text", decode_entities($json->{markup_text}, '<>&'));
        $t->set_template_variable("markup",     $post->{'markup'});
        $t->display_page("Updating " . $post->{'title'});
    } elsif ( $rc >= 400 and $rc < 500 ) {
            Page->report_error("user", "$json->{user_message}", $json->{system_message});
    } else  {
        # Page->report_error("user", "Unable to complete request.", "Invalid response code returned from API.");
        Page->report_error("user", "Unable to complete request. Invalid response code returned from API.", "$json->{user_message} $json->{system_message}");
    }
}

sub update_post {
    my $author_name  = User::get_logged_in_author_name(); 
    my $session_id   = User::get_logged_in_session_id(); 

    my $q = new CGI;
    my $submit_type     = $q->param("sb"); # Preview or Post 
    my $post_id         = $q->param("post_id"); # the slug. example: this-is-a-test
    my $rev             = $q->param("rev"); # the slug. example: this-is-a-test
    my $original_markup = $q->param("markup");

    my $markup = Encode::decode_utf8($original_markup);
    $markup = HTML::Entities::encode($markup,'^\n^\r\x20-\x25\x27-\x7e');

    my $api_url = Config::get_value_for("api_url");

    my $json_input;

    my $hash = {
        'author'      => $author_name,
        'session_id'  => $session_id,
        'submit_type' => $submit_type,
        'markup'      => $markup,
        'post_id'     => $post_id,
        'rev'         => $rev
    };

    my $json_input = encode_json $hash;

    my $headers = {
        'Content-type' => 'application/json'
    };

    my $rest = REST::Client->new( {
        host => $api_url,
    } );

    $rest->PUT( "/posts" , $json_input , $headers );

    my $rc = $rest->responseCode();

    my $json = decode_json $rest->responseContent();

    if ( $rc >= 200 and $rc < 300 ) {
        if ( $submit_type eq "Update" ) {
            CacheHtml::create_and_cache_page($post_id);
            my $home_page = Config::get_value_for("home_page");
            print $q->redirect( -url => $home_page . "/" . $post_id );
            exit;
        } elsif ( $submit_type eq "Preview" ) {
            my $t = Page->new("editpostform");
            $t->set_template_variable("previewingpost", 1);
            $t->set_template_variable("slug",     $post_id);
            $t->set_template_variable("rev",      $rev);
            $t->set_template_variable("title",    $json->{'title'});
            $t->set_template_variable("html",     $json->{'html'});
            $t->set_template_variable("markup",   $original_markup);
            $t->display_page("Editing " . $json->{'title'});
            exit;
        } else {
            Page->report_error("user", $json->{description}, "$json->{user_message} $json->{system_message}");
        }
    } elsif ( $rc >= 400 and $rc < 500 ) {
         Page->report_error("user", $json->{description}, "$json->{user_message} $json->{system_message}");
#        my $t = Page->new("errorpage");
#        $t->set_template_variable("errmsg", "Error: $json->{description} - $json->{user_message}");
#        # $t->set_template_variable("post_text",    $json->{markup_content});
#        $t->set_template_variable("post_text",    $post_text);
#        $t->display_page("Message error"); 
    } else  {
        Page->report_error("user", "Unable to complete request. Invalid response code returned from API.", "$json->{user_message} $json->{system_message}");
    }
}


sub splitscreen_edit {
    my $tmp_hash = shift;  

    my $author_name  = User::get_logged_in_author_name(); 
    my $session_id   = User::get_logged_in_session_id(); 

    my $post_id = $tmp_hash->{one};

    my $query_string = "/?author=$author_name&session_id=$session_id&text=markup";

    my $api_url = Config::get_value_for("api_url") . "/posts/" . $post_id;

    my $rest = REST::Client->new();
    $api_url .= $query_string;
    $rest->GET($api_url);

    my $rc = $rest->responseCode();

    my $json = decode_json $rest->responseContent();

    if ( $rc >= 200 and $rc < 300 ) {
        my $post = $json->{'post'};
        my $t = Page->new("splitscreenform");
        $t->set_template_variable("action",   "updateblog");
        $t->set_template_variable("api_url",  Config::get_value_for("api_url"));
        #   $t->set_template_variable("markup",   decode_entities($post->{markup_text}, '<>&'));
        $t->set_template_variable("markup",   $post->{'markup'});
        $t->set_template_variable("post_id",  $post->{'slug'});
        $t->set_template_variable("post_rev", $post->{_rev});
        $t->display_page_min("Editing - Split Screen " . $post->{title});
    } elsif ( $rc >= 400 and $rc < 500 ) {
            Page->report_error("user", "$json->{user_message}", $json->{system_message});
    } else  {
        # Page->report_error("user", "Unable to complete request.", "Invalid response code returned from API.");
        Page->report_error("user", "Unable to complete request. Invalid response code returned from API.", "$json->{user_message} $json->{system_message}");
    }

}

1;
