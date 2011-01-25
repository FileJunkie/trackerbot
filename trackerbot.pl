#!/usr/bin/perl

use strict;
use warnings;

use Encode;
use HTTP::Request::Common qw(POST);
use LWP::UserAgent;

# Tracking numbers
my @tracks = ("CJ216818892US");

sub parse_russian_post{
	my $track = $_[0];
	
	my $ua = LWP::UserAgent->new;

	my $req = POST 'http://info.russianpost.ru/servlet/post_item',
		[ action => 'search', searchType => 'barCode', show_form => 'yes', barCode => $track ];

	print decode("CP1251", $ua->request($req)->as_string);
}

foreach my $track (@tracks){
	parse_russian_post($track);
}
