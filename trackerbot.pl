#!/usr/bin/perl

# Written by Ilya Ershov, filejunkie@gmail.com, http://github.com/FileJunkie/trackerbot/
# Licensed under AGPL 3.0

use strict;
use warnings;

use Encode;
use HTML::TreeBuilder;
use HTTP::Request::Common qw(POST);
use LWP::UserAgent;
use Net::Jabber::Bot;
use utf8;

# Tracking numbers
my @tracks = ("CJ216818892US", "RR881780782CN");

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
		#print "$track Error parsing page: second header not found.\n";
		$tree->delete;
		return undef;
	}
	my $header_text = $header[1]->as_text;

	# checking if tracking # is OK
	if($header_text !~ /РЕЗУЛЬТАТЫ ПОИСКА/){
		#print "$track Error parsing page: incorrent heading content. Maybe incorrect tracking number?\n";
		$tree->delete;
		return;
	}
	
	# looking for results table
	my @tables = $tree->look_down("_tag", "table", "width", "");
	if(@tables != 1){
		print "$track Error parsing page: too much tables found.\n";
		$tree->delete;
		return;
	}
	
	# extracting data rows
	my @rows = $tables[0]->look_down("_tag", "tr", sub {
		$_[0]->attr('class') =~ /row_[01]_light/;
	});
	
	# extracting data
	my @data = ();
	foreach my $row (@rows){
		my @cells = $row->look_down("_tag", "td");
		$data[@data] = $cells[1]->as_text . "\t" . $cells[0]->as_text;
		for(my $i = 2; $i < scalar(@cells); $i++){
			$data[@data - 1] .= "\t" . $cells[$i]->as_text;
		}
	}
	
	$tree->delete;
	
	return @data;
}

sub init;
sub new_bot_message;

my %forum_list = ();

my $bot = Net::Jabber::Bot->new(
	server => 'filejunkie.name',
	conference_server => 'conference.filejunkie.name',
	port => 5222,
	username => 'parcelbot',
	password => '',
	alias => 'parcelbot',
	safety_mode => 1,
	loop_sleep_time => 5 * 60,
	message_function => \&new_bot_message,
	background_function => \&work,
	forums_and_responses => \%forum_list ,
);

sub new_bot_message{
	$bot->SendPersonalMessage('filejunkie@filejunkie.name', "Wait a sec...\n");
	init;
}

$bot->AddUser('filejunkie@filejunkie.name');
my (@sent, $i);

sub init{
	$i = 0;
	foreach my $track (@tracks){
		$sent[$i] = 0;
	
		my $message = "$track:\n";
		foreach my $line (parse_russian_post($track)){
			$sent[$i]++;
			$message .= $line."\n";
		}
		chomp $message;
		$bot->SendPersonalMessage('filejunkie@filejunkie.name', $message);
		
		$i++;
	}
}

sub work{
	$i = 0;
	foreach my $track (@tracks){
		my @data = parse_russian_post($track);
		if(scalar(@data) > $sent[$i]){
			my $message = "$track new line:\n";
			for(my $j = $sent[$i]; $j < scalar(@data); $j++){
				$sent[$i]++;
 				$message .= $data[$j]."\n";
			}
			chomp $message;
 			$bot->SendPersonalMessage('filejunkie@filejunkie.name', $message);
		}
	
		$i++;
	}
	
}

init();
$bot->Start();

$bot->Disconnect;
