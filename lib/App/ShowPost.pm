package ShowPost;

use strict;
use warnings;
use diagnostics;

use JSON::PP;
use LWP::UserAgent;
use App::DateTime;
use App::CacheHtml;

sub show_post {
    my $tmp_hash      = shift;  
    my $creation_type =  shift;

    my $author_name  = User::get_logged_in_author_name(); 
    my $session_id   = User::get_logged_in_session_id(); 
    my $query_string = "/?author=$author_name&session_id=$session_id&text=html";

    my $post_id = $tmp_hash->{function};  # since not using an id number, then 'function' equals slug or id for post

    my $api_url = Config::get_value_for("api_url") . "/posts/" . $post_id;

    $api_url .= $query_string;

    # todo decide whether to use the REST module or use LWP

    #my $rest = REST::Client->new();
    #$rest->GET($api_url);
    #my $rc = $rest->responseCode();
    #my $hash_ref = JSON::PP::decode_json $rest->responseContent();

    my $ua = LWP::UserAgent->new;
    my $response = $ua->get($api_url);
    my $hash_ref = decode_json $response->content;
    my $rc = $hash_ref->{'status'};

    if ( $rc >= 200 and $rc < 300 ) {
        my $post = $hash_ref->{'post'};
        my $t = Page->new("post");
        $t->set_template_variable("loggedin",        User::get_logged_in_flag());
        $t->set_template_variable("html",            $post->{'html'});
        $t->set_template_variable("author",          $post->{'author'});
        $t->set_template_variable("created_at",      DateTime::format_date_time($post->{'created_at'}));
        $t->set_template_variable("updated_at",      DateTime::format_date_time($post->{'updated_at'}));
        $t->set_template_variable("reading_time",    $post->{'reading_time'});
        $t->set_template_variable("word_count",      $post->{'word_count'});
        $t->set_template_variable("post_type",       $post->{'post_type'});
        $t->set_template_variable("slug",            $post->{'slug'});
        $t->set_template_variable("title",           $post->{'title'});
        $t->set_template_variable("author_profile",  Config::get_value_for("author_profile"));

        if ( $post->{'post_type'} eq "article" ) {
            $t->set_template_variable("show_title", 1);
        }

        if ( $post->{'created_at'} ne $post->{'updated_at'} ) {
            $t->set_template_variable("modified", 1);
        }

        if ( !User::get_logged_in_flag() and Config::get_value_for("write_html_to_memcached") ) {
            CacheHtml::cache_page($t->create_html($post->{'title'}), $post_id);
        } elsif ( $creation_type eq "private" ) {
            return $t->create_html($post->{'title'});
        } 

        $t->display_page($post->{'title'}); 
    } elsif ( $rc >= 400 and $rc < 500 ) {
            Page->report_error("user", "$hash_ref->{user_message}", $hash_ref->{system_message});
    } else  {
        Page->report_error("user", "Unable to complete request.", "Invalid response code returned from API.");
    }

}

1;
