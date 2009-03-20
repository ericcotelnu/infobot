# W3Search drastically altered back to GoogleSearch as Search::Google 
# was deprecated and requires a key that google no longer provides. 
# This new module uses REST::Google::Search 
# Modified by db <db@cave.za.net> 12-01-2008. 
#
# Usage: 'chanset _default +Google' in query window with your bot
#        to enable it in all channels
#        /msg botnick google <query> OR <addressCharacter>google <query> to use

package Google;

use strict;

my $maxshow = 5;

sub GoogleSearch {
    my ( $what, $type ) = @_;
    # $where set to official google colors ;)
    my $where  = "\00312G\0034o\0038o\00312g\0033l\0034e\003";
    my $retval = "$where can't find \002$what\002";
    my $Search;
    my $referer = "irc://$::server/$::chan/$::who";

    return unless &::loadPerlModule("REST::Google::Search");

    &::DEBUG( "Google::GoogleSearch->referer = $referer" );
    &::status( "Google::GoogleSearch> Searching Google for: $what");
    REST::Google::Search->http_referer( $referer );
    $Search = REST::Google::Search->new( q => $what );

    if ( !defined $Search ) {
        &::msg( $::who, "$where is invalid search." );
        &::WARN( "Google::GoogleSearch> $::who generated an invalid search: $where");
        return;
    }

    if ( $Search->responseStatus != 200 ) {
        &::msg( $::who, "http error returned." );
        &::WARN( "Google::GoogleSearch> http error returned: $Search->responseStatus");
        return;
    }

    # No results found
    if ( not $Search->responseData->results ) {
        &::DEBUG( "Google::GoogleSearch> $retval" );
        &::msg( $::who, $retval);
        return;
    }

    my $data    = $Search->responseData;
    my $cursor  = $data->cursor;
    my @results = $data->results;
    my $count;

    $retval = "$where says \"\002$what\002\" is at ";
    foreach my $r (@results) {
        my $url = $r->url;

        # Returns a string with each %XX sequence replaced with the actual byte
        # (octet). From URI::Escape uri_unescape()
        $url =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg;

        $retval .= " \002or\002 " if ( $count > 0 );
        $retval .= $url;
        last if ++$count >= $maxshow; # Only seems to return max of 4?
    }

    &::performStrictReply($retval);
}

1;
 
# vim:ts=4:sw=4:expandtab:tw=80 
# Local Variables:
# mode: cperl
# tab-width: 4
# fill-column: 80
# indent-tabs-mode: nil
# End:
