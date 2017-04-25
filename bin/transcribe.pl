#!/usr/bin/perl

use lib './lib/';
use Google::Cloud::Speech;
use Data::Dumper;

my $speech = Google::Cloud::Speech->new( file => $ARGV[0], secret_file => $ARGV[1] );

print Dumper $speech->syncrecognize->results;
