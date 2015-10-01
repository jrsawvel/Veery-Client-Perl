package CacheHtml;

use strict;
use warnings;
use diagnostics;

use CGI qw(:standard);
use REST::Client;
use JSON::PP;
use Cache::Memcached::libmemcached;
use App::ShowPost;
use App::ShowStream;

sub cache_page {
    my $html    = shift;
    my $post_id = shift;

    my $key;
    my $hashname =  Config::get_value_for("memcached_prefix");
    my $port     = Config::get_value_for("memcached_port");

    $key  = $hashname . "-" . $post_id;

    my $memd = Cache::Memcached::libmemcached->new( { 'servers' => [ "127.0.0.1:$port" ] } );

    $html .= "\n<!-- memcached -->\n";

    my $rc   = $memd->set($key, $html);

    return $rc;
}

sub create_and_cache_page {
    my $post_id = shift;

    my $tmp_hash;
    $tmp_hash->{function} = $post_id;
    
    my $html = ShowPost::show_post($tmp_hash, "private");
    cache_page($html, $post_id);    

    my $tmp_hash;
    $tmp_hash->{one}=1;
    $html = ShowStream::show_stream($tmp_hash, "private");
    cache_page($html, "homepage");
}

# used or called by the JavaScript editor to inform the server-side client code to update the cache.
sub cacheit {
    my $tmp_hash = shift;
    
    my $post_id = $tmp_hash->{one};

    my $q = new CGI;
    my $author_name = $q->param("author");
    my $session_id  = $q->param("session_id");


    my $query_string = "/?author=$author_name&session_id=$session_id";

    my $api_url      = Config::get_value_for("api_url") . '/users/' . $author_name;
    my $rest = REST::Client->new();
    $api_url .= $query_string;
    $rest->GET($api_url); 
    my $rc = $rest->responseCode();
    my $json = decode_json $rest->responseContent();

    if ( $rc >= 200 and $rc < 300 and $json->{'is_logged_in'} ) {
        create_and_cache_page($post_id);
        response("200", "success", "page cached");
    } elsif ( $rc >= 400 and $rc < 500 ) {
        response("401", "Unable to peform action.", "You are not logged in.");
    } else  {
        response("500", $json->{'user_message'}, $json->{'system_message'});
    }
}


sub response {
    my $status         = shift;
    my $user_message   = shift;
    my $system_message = shift;

    my %http_status_codes;
    $http_status_codes{200} = "OK";
    $http_status_codes{201} = "Created";
    $http_status_codes{204} = "No Content";
    $http_status_codes{400} = "Bad Request";
    $http_status_codes{401} = "Not Authorized";
    $http_status_codes{403} = "Forbidden";
    $http_status_codes{404} = "Not Found";
    $http_status_codes{500} = "Internal Server Error";

    my %hash;
    $hash{status}         = $status;
    $hash{description}    = $http_status_codes{$status};
    $hash{user_message}   = $user_message;
    $hash{system_message} = $system_message;

    my $json_str = encode_json \%hash;
    print header('application/json', "$status Accepted");
    print $json_str;
    exit;
}

1;
