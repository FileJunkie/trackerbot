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
	# checking if tracking # is OK
	if(!defined $header[1]){
		print "$track Error parsing page: second header not found.\n";
		$tree->delete;
		return undef;
	}
	my $header_text = $header[1]->as_text;

	# checking if tracking # is OK
	if($header_text !~ /РЕЗУЛЬТАТЫ ПОИСКА/){
		print "$track Error parsing page: incorrent heading content. Maybe incorrect tracking number?\n";
		$tree->delete;
		return undef;
	}
	
	# looking for results table
	my @tables = $tree->look_down("_tag", "table", "width", "");
	if(@tables != 1){
		print "$track Error parsing page: too much tables found.\n";
		$tree->delete;
		return undef;
	}
	
	# extracting data rows
	my @rows = $tables[0]->look_down("_tag", "tr", sub {
		$_[0]->attr('class') =~ /row_[01]_light/;
	});
	
	# extracting data
	my @data = ();
	foreach my $row (@rows){
		my @cells = $row->look_down("_tag", "td");
		$data[@data] = $cells[1]->as_text . "\t" . $cells[0]->as_text . "\t" . $cells[3]->as_text;
	}
	
	$tree->delete;
}

foreach my $track (@tracks){
	parse_russian_post($track);
}
