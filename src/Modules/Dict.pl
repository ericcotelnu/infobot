#
#  Dict.pl: Frontend to dict.org.
#   Author: dms
#  Version: v0.6b (19991224).
#  Created: 19990914.
#

package Dict;

use IO::Socket;
use strict;

my $server	= "dict.org";	# need a specific host||ip.
my $port	= 2628;
my $proto	= getprotobyname('tcp');

###local $SIG{ALRM} = sub { die "alarm\n" };

sub Dict {
    my ($query) = @_;
###    return unless &main::loadPerlModule("IO::Socket");
    my $socket = new IO::Socket;
    my @results;

    # connect.
    socket($socket, PF_INET, SOCK_STREAM, $proto) or return "error: socket: $!";
    eval {
	alarm 15;
	connect($socket, sockaddr_in($port, inet_aton($server))) or return "error: connect: $!";
	alarm 0;
    };

    my $retval;
    if ($@ && $@ ne "alarm\n") {	# failure.
	$retval = "i could not get info from dict.org";
    } else {				# success.
	$socket->autoflush(1);	# required.

	my $num;
	if ($query =~ /^(\d+)\s+/) {
	    $num = $1;
	}

	# body.
	push(@results, &Dict_Wordnet($socket,$query));
	push(@results, &Dict_Foldoc($socket,$query));
	# end.

	print $socket "QUIT\n";
	close $socket;

	my $total = scalar @results;

	if (defined $num and ($num > $total or $num < 0)) {
	    &msg($main::who, "error: choice in definition is out of range.");
	    return;
	}

	# parse the results.
	if ($total > 1) {
	    if (defined $num) {
		$retval = sprintf("[%d/%d] %s", $num, $total, $results[$num]);
	    } else {
		# suggested by larne and others.
		my $prefix = "Dictionary '$query' ";
		$retval = &main::formListReply(1, $prefix, @results);
	    }
	} elsif ($total == 1) {
	    $retval = "Dictionary '$query' ".$results[0];
	} else {
	    $retval = "could not find definition for \002$query\002";
	}
    }

    &main::performStrictReply($retval);
}

sub Dict_Wordnet {
    my ($socket, $query) = @_;
    my @results;

    &main::status("Dict: asking Wordnet.");
    print $socket "DEFINE wn \"$query\"\n";

    my $def		= "";
    my $wordtype	= "";

    while (<$socket>) {
	chop;	# remove \n
	chop;	# remove \r

	if ($_ eq ".") {				# end of def.
	    push(@results, $def);
	} elsif (/^250 /) {				# stats.
	    last;
	} elsif (/^552 no match/) {			# no match.
	    return;
	} elsif (/^\s+(\S+ )?(\d+)?: (.*)/) {	# start of sub def.
	    my $text = $3;
	    $def =~ s/\s+$//;
###	    &main::DEBUG("def => '$def'.");
	    push(@results, $def)		if ($def ne "");
	    $def = $text;

	    if (0) {	# old non-fLR format.
		$def = "$query $wordtype: $text" if (defined $text);
		$wordtype = substr($1,0,-1)	if (defined $1);
###		&main::DEBUG("_ => '$_'.") if (!defined $text);
	    }

	} elsif (/^\s+(.*)/) {
	    s/^\s{2,}/ /;
	    $def	.= $_;
	    $def =~ s/\[.*?\]$//g;
	}
    }

    &main::status("Dict: wordnet: found ". scalar(@results) ." defs.");

    return if (!scalar @results);

    return @results;
}

sub Dict_Foldoc {
    my ($socket,$query) = @_;
    my @results;

    &main::status("Dict: asking Foldoc.");
    print $socket "DEFINE foldoc \"$query\"\n";

    my $firsttime = 1;
    my $string;
    while (<$socket>) {
	chop;	# remove \n
	chop;	# remove \r

	return if /^552 /;		# no match.

	if ($firsttime) {
	    $firsttime-- if ($_ eq "");
	    next;
	}

	last if (/^250/ or /^\.$/);	# stats; end of def.

	s/^\s+|\s+$//g;			# each line.

	if ($_ eq "") {			# sub def separator.
	    $string =~ s/^\s+|\s+$//g;	# sub def.
	    $string =~ s/[{}]//g;

	    next if ($string eq "");

	    push(@results, $string);
	    $string = "";
	}

	$string .= $_." ";
    }

    &main::status("Dict: foldoc: found ". scalar(@results) ." defs.");

    return if (!scalar @results);
    pop @results;	# last def is date of entry.

    return @results;
}

1;
