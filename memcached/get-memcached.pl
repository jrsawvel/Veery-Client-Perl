#!/usr/bin/perl -wT

use strict;

use lib '/home/veery/Veery-Client-Perl/lib';

use App::Config;
use Cache::Memcached::libmemcached;

my $post_id = 'info';

my $port        = Config::get_value_for("memcached_port");
my $domain_name = Config::get_value_for("domain_name");

my $key         = $domain_name . "-" . $post_id; 

my $memd = Cache::Memcached::libmemcached->new( { 'servers' => [ "127.0.0.1:$port" ] } );

my $val = $memd->get($key);

print $val . "\n";
