package ShowStream;

use strict;
use warnings;
use diagnostics;

use JSON::PP;
use LWP::UserAgent;
use URI::Escape;
use App::DateTime;
use App::RSS;
use App::CacheHtml;

sub create_rss {
    my $tmp_hash = shift;
    RSS::__create_rss(show_stream($tmp_hash, "rss"));
}


sub show_search_form {
    my $t = Page->new("searchform");
    $t->display_page("Search form");
}

sub show_stream {
    my $tmp_hash = shift;
    my $creation_type = shift;

    my $max_entries = Config::get_value_for("max_entries_on_page");

    my $query_string = "/";

    my $page_num = 1;
    if ( Utils::is_numeric($tmp_hash->{one}) ) {
        $page_num = $tmp_hash->{one};
        if ( $page_num > 1 ) {
            $query_string .= "?page=$page_num";
        }
    } 

    my $api_url = Config::get_value_for("api_url") . "/posts";

    $api_url .= $query_string;

    my $ua = LWP::UserAgent->new;
    my $response = $ua->get($api_url);
    my $hash_ref = decode_json $response->content;
    my $rc             = $hash_ref->{'status'};
    my $next_link_bool = $hash_ref->{'next_link_bool'};
    my $stream         = $hash_ref->{'posts'};

    if ( $creation_type eq "rss" ) {
        return $stream;
    }

    my $len = @$stream;

    my @posts;

# todo remove this code block. this should be done on the API side at create/update article time.
    my $ctr=0;
    foreach my $hash_ref ( @$stream ) {
        if ( $hash_ref->{'post_type'} eq "article" ) {
            $hash_ref->{'show_title'} = 1;
        }

        my $tags = $hash_ref->{'tags'};
        if ( $tags->[0] ) {
            my $tag_list = "";
            foreach my $tag_ref ( @$tags ) {
                $tag_list .= "<a href=\"/tag/$tag_ref\">#" . $tag_ref . "</a> ";
            }

            $hash_ref->{'tag_list'} = $tag_list;

        }
        delete($hash_ref->{'tags'});
        push(@posts, $hash_ref);
        last if ++$ctr == $max_entries;
    }

    my $t = Page->new("stream");

    $t->set_template_variable("loggedin", User::get_logged_in_flag());

    $t->set_template_loop_data("stream_loop", \@posts);

    if ( $page_num == 1 ) {
        $t->set_template_variable("not_page_one", 0);
    } else {
        $t->set_template_variable("not_page_one", 1);
    }

    if ( $len >= $max_entries && $next_link_bool ) {
        $t->set_template_variable("not_last_page", 1);
    } else {
        $t->set_template_variable("not_last_page", 0);
    }
    my $previous_page_num = $page_num - 1;
    my $next_page_num = $page_num + 1;
    my $next_page_url = "/stream/$next_page_num";
    my $previous_page_url = "/stream/$previous_page_num";
    $t->set_template_variable("next_page_url", $next_page_url);
    $t->set_template_variable("previous_page_url", $previous_page_url);

    if ( $page_num == 1 and !User::get_logged_in_flag() and Config::get_value_for("write_html_to_memcached") ) {
        CacheHtml::cache_page($t->create_html("Stream of Posts", "homepage"));
    } elsif ( $creation_type eq "private" ) {
       return $t->create_html("Stream of Posts");
    }

    $t->display_page("Stream of Posts");
}

sub tag_search {
    my $tmp_hash = shift;

    my $doing_rss = 0;

    my $tag_name = $tmp_hash->{one};

    if ( $tmp_hash->{two} eq "rss" ) {
        $doing_rss = 1;
    }

    my $max_entries = Config::get_value_for("max_entries_on_page");

    my $query_string = "/";

    my $page_num = 1;
    if ( Utils::is_numeric($tmp_hash->{two}) ) {
        $page_num = $tmp_hash->{two};
        if ( $page_num > 1 ) {
            $query_string .= "?page=$page_num";
        }
    } 

    my $api_url = Config::get_value_for("api_url") . "/searches/tag/$tag_name";

    $api_url .= $query_string;

    my $ua = LWP::UserAgent->new;
    my $response = $ua->get($api_url);
    my $hash_ref = decode_json $response->content;
    my $rc             = $hash_ref->{'status'};
    my $next_link_bool = $hash_ref->{'next_link_bool'};
    my $stream         = $hash_ref->{'posts'};

    if ( $doing_rss ) {
        RSS::__create_rss($stream);
    }

    my $len = @$stream;

    my $stream = $hash_ref->{'posts'};

    if ( !$stream ) {
        Page->success("Search results for $tag_name", "No matches found.", "");
    }

    my $number_of_matches = @$stream;
    if ( $number_of_matches < 1 ) {
        Page->success("Search results for $tag_name", "No matches found.", "");
    }

    my @posts;

# todo remove this code block. this should be done on the API side at create/update article time.
    my $ctr=0;
    foreach my $hash_ref ( @$stream ) {
        my $tags = $hash_ref->{'tags'};
        if ( $tags->[0] ) {
            my $tag_list = "";
            foreach my $tag_ref ( @$tags ) {
                $tag_list .= "<a href=\"/tag/$tag_ref\">#" . $tag_ref . "</a> ";
            }

            $hash_ref->{'tag_list'} = $tag_list;
        }
        delete($hash_ref->{'tags'});
        push(@posts, $hash_ref);
        last if ++$ctr == $max_entries;
    }
    my $t = Page->new("stream");
    $t->set_template_loop_data("stream_loop", \@posts);
    $t->set_template_variable("search", 1);
    $t->set_template_variable("keyword", $tag_name);
    $t->set_template_variable("search_uri_str", $tag_name);
    $t->set_template_variable("search_type_text", "Tag search");
    $t->set_template_variable("search_type", "tag");
    if ( $page_num == 1 ) {
        $t->set_template_variable("not_page_one", 0);
    } else {
        $t->set_template_variable("not_page_one", 1);
    }
    if ( $len >= $max_entries && $next_link_bool ) {
        $t->set_template_variable("not_last_page", 1);
    } else {
        $t->set_template_variable("not_last_page", 0);
    }

    my $previous_page_num = $page_num - 1;
    my $next_page_num = $page_num + 1;
    my $next_page_url = "/tag/$tag_name/$next_page_num";
    my $previous_page_url = "/tag/$tag_name/$previous_page_num";
    $t->set_template_variable("next_page_url", $next_page_url);
    $t->set_template_variable("previous_page_url", $previous_page_url);
    $t->display_page("Tag search results for $tag_name");
}

sub string_search {
    my $tmp_hash = shift;

    my $doing_rss = 0;

    my $search_string= $tmp_hash->{one};

    if ( $tmp_hash->{two} eq "rss" ) {
        $doing_rss = 1;
    }

    if ( !defined($search_string) ) {
        my $q = new CGI;
        $search_string = $q->param("keywords");

        if ( !defined($search_string) ) {
            Page->report_error("user", "Missing data.", "Enter keyword(s) to search on.");
        }
        
        $search_string = Utils::trim_spaces($search_string);
        if ( length($search_string) < 1 ) {
            Page->report_error("user", "Missing data.", "Enter keyword(s) to search on.");
        }
        
    }

    my $search_uri_str = $search_string;
    $search_uri_str =~ s/ /\+/g;
    $search_uri_str = uri_escape($search_uri_str);

    my $max_entries = Config::get_value_for("max_entries_on_page");

    my $query_string = "/";

    my $page_num = 1;
    if ( Utils::is_numeric($tmp_hash->{two}) ) {
        $page_num = $tmp_hash->{two};
        if ( $page_num > 1 ) {
            $query_string .= "?page=$page_num";
        }
    } 

    my $api_url = Config::get_value_for("api_url") . "/searches/string/$search_uri_str";

    $api_url .= $query_string;

    my $ua = LWP::UserAgent->new;
    my $response = $ua->get($api_url);
    my $hash_ref = decode_json $response->content;
    my $rc             = $hash_ref->{'status'};

    if ( $rc >= 400 and $rc < 500 ) {
        Page->report_error("user", "$hash_ref->{user_message}", $hash_ref->{system_message});
    }

    my $next_link_bool = $hash_ref->{'next_link_bool'};
    my $stream         = $hash_ref->{'posts'};

    if ( $doing_rss ) {
        RSS::__create_rss($stream);
    }

    my $len = @$stream;

    my $stream = $hash_ref->{'posts'};

    if ( !$stream ) {
        Page->success("Search results for $search_string", "No matches found.", "");
    }

    my $number_of_matches = @$stream;
    if ( $number_of_matches < 1 ) {
        Page->success("Search results for $search_string", "No matches found.", "");
    }

    my @posts;

# todo remove this code block. this should be done on the API side at create/update article time.
    my $ctr=0;
    foreach my $hash_ref ( @$stream ) {
        my $tags = $hash_ref->{'tags'};
        if ( $tags->[0] ) {
            my $tag_list = "";
            foreach my $tag_ref ( @$tags ) {
                $tag_list .= "<a href=\"/tag/$tag_ref\">#" . $tag_ref . "</a> ";
            }

            $hash_ref->{'tag_list'} = $tag_list;
        }
        delete($hash_ref->{'tags'});
        push(@posts, $hash_ref);
        last if ++$ctr == $max_entries;
    }

    my $t = Page->new("stream");
    $t->set_template_loop_data("stream_loop", \@posts);
    $t->set_template_variable("search", 1);
    $t->set_template_variable("keyword", $search_string);
    $t->set_template_variable("search_uri_str", $search_uri_str);
    $t->set_template_variable("search_type_text", "Search");
    $t->set_template_variable("search_type", "search");
    if ( $page_num == 1 ) {
        $t->set_template_variable("not_page_one", 0);
    } else {
        $t->set_template_variable("not_page_one", 1);
    }
    if ( $len >= $max_entries && $next_link_bool ) {
        $t->set_template_variable("not_last_page", 1);
    } else {
        $t->set_template_variable("not_last_page", 0);
    }

    my $previous_page_num = $page_num - 1;
    my $next_page_num = $page_num + 1;
    my $next_page_url     = "/search/$search_uri_str/$next_page_num";
    my $previous_page_url = "/search/$search_uri_str/$previous_page_num";
    $t->set_template_variable("next_page_url", $next_page_url);
    $t->set_template_variable("previous_page_url", $previous_page_url);
    $t->display_page("Search results for $search_string");
}

sub show_deleted_posts {

    my $author_name  = User::get_logged_in_author_name(); 
    my $session_id   = User::get_logged_in_session_id(); 
    my $query_string = "/?author=$author_name&session_id=$session_id&deleted=yes";

    my $api_url = Config::get_value_for("api_url") . "/posts" . $query_string; 
    my $rest = REST::Client->new();
    $rest->GET($api_url);
 
    my $rc = $rest->responseCode();
    my $json = decode_json $rest->responseContent();

    if ( $rc >= 200 and $rc < 300 ) {
        my $t = Page->new("deleted");
        $t->set_template_loop_data("deleted_loop", $json->{'posts'});
        $t->display_page("Deleted Posts");
    } elsif ( $rc >= 400 and $rc < 500 ) {
        Page->report_error("user", $json->{'user_message'}, $json->{'system_message'}); 
    } else  {
        Page->report_error("user", "Unable to complete request.", "Invalid response code returned from API.");
    }
}

1;
