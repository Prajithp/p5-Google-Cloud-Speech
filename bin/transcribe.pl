#!/usr/bin/perl

use lib './lib/';
use Google::Cloud::Speech;
use Data::Dumper;

my $speech = Google::Cloud::Speech->new( file => $ARGV[0], secret_file => $ARGV[1] );

print Dumper $speech->syncrecognize->results;

my $operation = $speech->asyncrecognize();
my $is_done = $operation->is_done;

until($is_done) {
    if ($is_done = $operation->is_done) {
        print Dumper $operation->results;
    }
}
