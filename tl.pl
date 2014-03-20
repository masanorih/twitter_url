#!/usr/bin/perl

use strict;
use warnings;
use lib qw(
    /app/twitter_url
    /home/haram/git/net-twitter-lite/lib
);
use Config::Pit;
use HTML::Entities qw(decode_entities);
use HTTP::Date;
use LWP::UserAgent;
use Net::Twitter::Lite;
use POSIX qw(strftime);
use Term::ANSIColor qw(:constants);
use TwitterURL;
use Regexp::Common qw(URI);

$Term::ANSIColor::AUTORESET = 1;
binmode STDOUT, ':utf8';
binmode STDERR, ':utf8';

######################################################################
# Twitter
my $config  = pit_get('stream2twitter');
my $twitter = Net::Twitter::Lite->new(
    legacy_lists_api => 0,
    consumer_key     => $config->{consumer_key},
    consumer_secret  => $config->{consumer_secret},
);
$twitter->access_token( $config->{access_token} );
$twitter->access_token_secret( $config->{access_token_secret} );

######################################################################
# TwitterURL
my $turl = TwitterURL->new;

######################################################################
# Main
my( $ids, $since_id );
while (1) {
    my $args;
    $args->{include_entities} = 'true';
    $since_id ? $args->{since_id} = $since_id : $args->{count} = 100;
    my $tl = $twitter->friends_timeline($args);
    for my $t ( reverse @$tl ) {
        my $name = $t->{user}->{screen_name};
        my $text = $t->{text};
        my $time = date2epoc( $t->{created_at} );
        my $date = strftime "%H:%M:%S", localtime $time;
        for my $urls ( @{ $t->{entities}->{urls} } ) {
            my $t_co = $urls->{url};
            my $exp  = $urls->{expanded_url};
            $text =~ s/$t_co/$exp/;
        }
        my $id = $t->{id};
        next if $ids->{$id};
        $ids->{$id}++;
        $text = expand_shorten_url( $text, $name, $turl );
        printf "%s %s %s\n", $date, color_text( YELLOW, $name ),
            conv_name( decode_entities $text );
        $since_id = $id;
    }
    printf STDERR "%s%s entries found%s\n", GREEN, scalar @$tl, RESET;
    sleep $config->{sleep_sec};
}

######################################################################
# Sub
sub date2epoc {
    my($timestring) = @_;
    $timestring =~ s/\+0000//go;
    return str2time($timestring) + 32400;    # +0900 JST
}

sub conv_name {
    my($text) = @_;
    $text =~ s!(\@[a-zA-z0-9_]+)!&color_text( CYAN, $1 )!ge;
    return $text;
}

sub color_text {
    my( $color, $name ) = @_;
    return sprintf "%s%s%s%s", BOLD, $color, $name, RESET;
}

sub expand_shorten_url {
    my( $text, $name, $turl ) = @_;
    my $expanded;
    for my $host ( @{ $config->{expand_url} } ) {
        if ( $text =~ m!(http://$host/\w+)! ) {
            my $url = $1;
            my $conv = do_expand($url);
            $text =~ s!$url!$conv!g;
            $expanded = $conv;
        }
    }
    if ( not $expanded ) {
        if ( $text =~ /($RE{URI}{HTTP})/ ) {
            $expanded = $1;
        }
    }
    if ($expanded) {
        for my $ignore ( @{ $config->{ignore_name} } ) {
            return $text if $ignore eq $name;
        }
        for my $ignore ( @{ $config->{ignore_url} } ) {
            return $text if $expanded =~ /^$ignore/;
        }
        $turl->insert_url( $text, $name, $expanded );
    }
    return $text;
}

sub do_expand {
    my($url) = @_;
    my $ua = LWP::UserAgent->new( timeout => 5 );
    my $res = $ua->head($url);
    if ( $res->request->uri ) {
        $url = $res->request->uri;
    }
    return $url;
}
