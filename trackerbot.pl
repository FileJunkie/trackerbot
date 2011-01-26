#!/usr/bin/perl

use strict;
use warnings;

use Encode;
use HTML::TreeBuilder;
use HTTP::Request::Common qw(POST);
use LWP::UserAgent;
use utf8;

# Tracking numbers
my @tracks = ("CJ216818892US");

binmode STDOUT, ":utf8";

sub parse_russian_post{
	my $track = $_[0];
	
	my $ua = LWP::UserAgent->new;
	my $req = POST 'http://info.russianpost.ru/servlet/post_item',
		[ action => 'search', searchType => 'barCode', show_form => 'yes', barCode => $track ];

	my $tree = HTML::TreeBuilder->new;
	$tree->parse(decode("CP1251", $ua->request($req)->as_string));
	
	my @header = $tree->look_down("_tag", "p", "class", "page_TITLE");
	if(!defined $header[1]){
		print "Error parsing page: second header not found.\n";
		return;
	}
	my $header_text = $header[1]->as_text;

	if($header_text !~ /РЕЗУЛЬТАТЫ ПОИСКА/){
		print "Error parsing page: incorrent heading content. Maybe incorrect tracking number?\n";
	}
	
	$tree->delete;
}

foreach my $track (@tracks){
	parse_russian_post($track);
}
