###
### Reply.pl: Kevin Lenzo   (c) 1997
###

##
# x is y === $lhs $mhs $rhs
#
#   lhs - factoid.
#   mhs - verb.
#   rhs - factoid message.
##

if (&IsParam("useStrict")) { use strict; }

use vars qw($msgType $uh $lastWho $ident);
use vars qw(%lang %lastWho);

sub getReply {
    my($message) = @_;
    my($lhs,$mhs,$rhs);
    my($result,$reply);
    $orig{message} = $message;

    if (!defined $message or $message =~ /^\s*$/) {
	&WARN("getR: message == NULL.");
	return '';
    }

    $message =~ tr/A-Z/a-z/;

    my ($result, $fauthor, $count) = &dbGet("factoids", 
	"factoid_value,created_by,requested_count", "factoid_key=".&dbQuote($message) );
    if ($result) {
	$lhs = $message;
	$mhs = "is";
	$rhs = $result;

	return "$lhs $mhs $rhs" if ($literal);
    } else {
	return '';
    }

    # if there was a head...
    my(@poss) = split '\|\|', $result;
    $poss[0] =~ s/^\s//;
    $poss[$#poss] =~ s/\s$//;

    if (@poss > 1) {
	$result = &getRandom(@poss);
	$result =~ s/^\s*//;
    }

    $result	= &SARit($result);

    $reply	= $result;
    if ($result ne "") {
	### AT LAST, REPEAT PREVENTION CODE REMOVED IN FAVOUR OF GLOBAL
	### FLOOD REPETION AND PROTECTION. -20000124

	# stats code.
	### FIXME: old mysql doesn't support
	### "requested_count=requested_count+1".
	$count++;
	### BROKEN!!! - Tim Riker <Tim@Rikers.org> says it's fixed now
	if (0) {	# old code.
	    &setFactInfo($lhs,"requested_by", $nuh);
	    &setFactInfo($lhs,"requested_time", time());
	    &setFactInfo($lhs,"requested_count", $count);
	} else {
	    &dbSet("factoids", {'factoid_key' => $lhs}, {
		requested_by	=> $nuh,
		requested_time	=> time(),
		requested_count	=> $count
	    } );
	}

	# todo: rename $real to something else!
	my $real   = 0;
#	my $author = &getFactInfo($lhs,"created_by") || '';
#	$real++ if ($author =~ /^\Q$who\E\!/);
#	$real++ if (&IsFlag("n"));
	$real = 0 if ($msgType =~ /public/);

	### fix up the reply.
	# only remove '<reply>'
	if (!$real and $reply =~ s/^\s*<reply>\s*//i) {
	    # 'are' fix.
	    if ($reply =~ s/^are /$lhs are /i) {
		&VERB("Reply.pl: el-cheapo 'are' fix executed.",2);
	    }

	} elsif (!$real and $reply =~ s/^\s*<action>\s*(.*)/\cAACTION $1\cA/i) {
	    # only remove '<action>' and make it an action.
	} else {		# not a short reply

	    ### bot->bot reply.
	    if (exists $bots{$nuh} and $rhs !~ /^\s*$/) {
		return "$lhs $mhs $rhs";
	    }

	    ### bot->person reply.
	    # result is random if separated by '||'.
	    # rhs is full factoid with '||'.
	    if ($mhs eq "is") {
		$reply = &getRandom(keys %{ $lang{'factoid'} });
		$reply =~ s/##KEY/$lhs/;
		$reply =~ s/##VALUE/$result/;
	    } else {
		$reply = "$lhs $mhs $result";
	    }

	    if ($reply =~ s/^\Q$who\E is/you are/i) {
		# fix the person.
	    } else {
		if ($reply =~ /^you are / or $reply =~ / you are /) {
		    return if ($addressed);
		}
	    }
	}
    }

    return $reply if ($literal);

    # remove excessive beginning and end whitespaces.
    $reply	=~ s/^\s+|\s+$//g;

    if ($reply =~ /^\s+$/) {
	&DEBUG("Reply: Null factoid ($message)");
	return '';
    }

    return $reply unless ($reply =~ /\$/);

    ###
    ### $ SUBSTITUTION.
    ###

    # don't evaluate if it has factoid arguments.
    if ($message =~ /^CMD:/i) {
	&status("Reply: not doing substVars (eval dollar vars)");
    } else {
	$reply = &substVars($reply,1);
    }

    $reply;
}

sub smart_replace {
    my ($string) = @_;
    my ($l,$r)	= (0,0);	# l = left,  r = right.
    my ($s,$t)	= (0,0);	# s = start, t = marker.
    my $i	= 0;
    my $old	= $string;
    my @rand;

    foreach (split //, $string) {

	if ($_ eq "(") {
###	    print "( l=>$l, r=>$r\n";

	    if (!$l and !$r) {
#		print "STARTING at $i\n";
		$s = $i;
		$t = $i;
	    }

	    $l++;
	    $r--;
	}

	if ($_ eq ")") {
###	    print ") l=>$l, r=>$r\n";

	    $r++;
	    $l--;

	    if (!$l and !$r) {
		my $substr = substr($old,$s,$i-$s+1);
#		print "STOP at $i $substr\n";
		push(@rand, substr($old,$t+1,$i-$t-1) );

		my $rand = $rand[rand @rand];
		&status("SARing '$substr' to '$rand'.");
		$string =~ s/\Q$substr\E/$rand/;
		undef @rand;
	    }
	}

	if ($_ eq "|" and $l+$r== 0 and $l==1) {
#	    print "| at $i (l=>$l,r=>$r)\n";
	    push(@rand, substr($old,$t+1,$i-$t-1) );
	    $t = $i;
	}

	$i++;
    }

    if ($old eq $string) {
	&WARN("smart_replace: no subst made. (string => $string)");
    }

    return $string;
}

sub SARit {
    my($txt) = @_;
    my $done = 0;

    # (blah1|blah2)?
    while ($txt =~ /\((.*?)\)\?/) {
	my $str = $1;
	if (rand() > 0.5) {		# fix.
	    &status("Factoid transform: keeping '$str'.");
	    $txt =~ s/\(\Q$str\E\)\?/$str/;
	} else {			# remove
	    &status("Factoid transform: removing '$str'.");
	    $txt =~ s/\(\Q$str\E\)\?\s?//;
	}
	$done++;
	last if ($done >= 10);	# just in case.
    }
    $done = 0;

    # EG: (0-32768) => 6325
    ### TODO: (1-10,20-30,40) => 24
    while ($txt =~ /\((\d+)-(\d+)\)/) {
	my ($lower,$upper) = ($1,$2);
	my $new = int(rand $upper-$lower) + $lower;

	&status("SARing '$&' to '$new' (2).");
	$txt =~ s/$&/$new/;
	$done++;
	last if ($done >= 10);	# just in case.
    }
    $done = 0;

    # EG: (blah1|blah2|blah3|) => blah1
    while ($txt =~ /.*\((.*\|.*?)\).*/) {
	$txt = &smart_replace($txt);

	$done++;
	last if ($done >= 10);	# just in case.
    }
    &status("Reply.pl: $done SARs done.") if ($done);

    return $txt;
}

sub substVars {
    my($reply,$flag) = @_;

    # $date, $time.
    my $date	=  scalar(localtime());
    $date	=~ s/\:\d+(\s+\w+)\s+\d+$/$1/;
    $reply	=~ s/\$date/$date/gi;
    $date	=~ s/\w+\s+\w+\s+\d+\s+//;
    # todo: support UTC.
    $reply	=~ s/\$time/$date/gi;

    # dollar variables.
    if ($flag) {
	$reply	=~ s/\$nick/$who/g;
	$reply	=~ s/\$who/$who/g;	# backward compat.
    }

    if ($reply =~ /\$(user(name)?|host)/) {
	my ($username, $hostname) = split /\@/, $uh;
	$reply	=~ s/\$user(name)?/$username/g;
	$reply	=~ s/\$host(name)?/$hostname/g;
    }
    $reply	=~ s/\$chan(nel)?/$talkchannel/g;
    if ($msgType =~ /public/) {
	$reply	=~ s/\$lastspeaker/$lastWho{$talkchannel}/g;
    } else {
	$reply	=~ s/\$lastspeaker/$lastWho/g;
    }

    if ($reply =~ /\$rand/) {
	my $rand  = rand();

	# $randnick.
	if ($reply =~ /\$randnick/) {
	    my @nicks = keys %{ $channels{$chan}{''} };
	    my $randnick = $nicks[ int($rand*$#nicks) ];
	    $reply =~ s/\$randnick/$randnick/g;
	}

	# eg: $rand100.3
	### TODO: number of digits. 'x.y'
	# too hard.
	if ($reply =~ /\$rand(\d+)(\.(\d+))?/) {
	    my $max = $1;
	    my $dot = $3 || 0;
	    &status("dot => $dot, max => $max, rand=>$rand");
	    $rand = sprintf("%.*f", $dot, $rand*$max);
	    my $orig = $&;

	    &status("swapping $orig to $rand");
	    &status("reply => $reply");
	    $reply =~ s/$orig/$rand/eg;
	    &status("reply => $reply");
	}

	$reply =~ s/\$rand/$rand/g;
    }

    $reply	=~ s/\$ident/$ident/g;

    if ($reply =~ /\$startTime/) {
	my $time = scalar(localtime $^T);
	$reply =~ s/\$startTime/$time/;
    }

    if ($reply =~ /\$uptime/) {
	my $uptime = &Time2String(time() - $^T);
	$reply =~ s/\$uptime/$uptime/;
    }

    if ($reply =~ /\$factoids/) {
	my $count = &countKeys("factoids");
	$reply =~ s/\$factoids/$factoids/;
    }

    if ($reply =~ /\$Fupdate/) {
	my $x = "\002$count{'Update'}\002 ".
		&fixPlural("modification", $count{'Update'});
	$reply =~ s/\$Fupdate/$x/;
    }

    if ($reply =~ /\$Fquestion/) {
	my $x = "\002$count{'Question'}\002 ".
		&fixPlural("question", $count{'Question'});
	$reply =~ s/\$Fquestion/$x/;
    }

    if ($reply =~ /\$Fdunno/) {
	my $x = "\002$count{'Dunno'}\002 ".
		&fixPlural("dunno", $count{'Dunno'});
	$reply =~ s/\$Fdunno/$x/;
    }

    $reply	=~ s/\$memusage/$memusage/;

    return $reply;
}

1;
