#
# Update.pl: Add or modify factoids in the db.
#    Author: Kevin Lenzo
#	     dms
#   Version: 19991209
#   Created: 1997
#

if (&IsParam("useStrict")) { use strict; }

sub update {
    my($lhs, $mhs, $rhs) = @_;

    for ($lhs) {
	s/^i (heard|think) //i;
	s/^some(one|1|body) said //i;
	s/\s+/ /g;
    }

    # locked.
    return if (&IsLocked($lhs) == 1);

    # profanity.
    if (&IsParam("profanityCheck") and &hasProfanity($rhs)) {
	&performReply("please, watch your language.");
	return 1;
    }

    # teaching.
    if (&IsFlag("t") ne "t") {
	&msg($who, "permission denied.");
	&status("alert: $who wanted to teach me.");
	return 1;
    }

    # invalid verb.
    if ($mhs !~ /^(is|are)$/i) {
	&ERROR("UNKNOWN verb: $mhs.");
	return;
    }

    # check if the arguments are too long to be stored in our table.
    my $toolong	= 0;
    $toolong++	if (length $lhs > $param{'maxKeySize'});
    $toolong++	if (length $rhs > $param{'maxDataSize'});
    if ($toolong) {
	&performAddressedReply("that's too long");
	return 1;
    }

    # also checking.
    my $also    = ($rhs =~ s/^-?also //i);
    my $also_or = ($also and $rhs =~ s/\s+(or|\|\|)\s+//);

    # freshmeat
    if (&IsChanConf("freshmeatForFactoid")) {
	# todo: "name" is invalid for fm ][
	if ( &dbGet("freshmeat", "name", "name=".&dbQuote($lhs)) ) {
	    &msg($who, "permission denied. (freshmeat)");
	    &status("alert: $who wanted to teach me something that freshmeat already has info on.");
	    return 1;
	}
    }

    # factoid arguments handler.
    if (&IsChanConf("factoidArguments") and $lhs =~ /\$/) {
	&status("Update: Factoid Arguments found.");
	&status("Update: orig lhs => '$lhs'.");
	&status("Update: orig rhs => '$rhs'.");

	my @list;
	my $count = 0;
	$lhs =~ s/^/CMD: /;
	while ($lhs =~ s/\$(\S+)/(.*?)/) {
	    push(@list, "\$$1");
	    $count++;
	    last if ($count >= 10);
	}

	if ($count >= 10) {
	    &msg($who, "error: could not SAR properly.");
	    &DEBUG("error: lhs => '$lhs'.");
	    &DEBUG("error: rhs => '$rhs'.");
	    return;
	}

	my $z = join(',',@list);
	$rhs =~ s/^/($z): /;

	&status("Update: new  lhs => '$lhs'.");
	&status("Update: new  rhs => '$rhs'.");
    }

    # the fun begins.
    my $exists = &getFactoid($lhs);

    if (!$exists) {
	# nice 'are' hack (or work-around).
	if ($mhs =~ /^are$/i and $rhs !~ /<\S+>/) {
	    &status("Update: 'are' hack detected.");
	    $mhs = "is";
	    $rhs = "<REPLY> are ". $rhs;
	}

	&status("enter: <$who> \'$lhs\' =$mhs=> \'$rhs\'");
	$count{'Update'}++;

	&performAddressedReply("okay");

	if (0) {	# old
	    &setFactInfo($lhs, "factoid_value", $rhs);
	    &setFactInfo($lhs, "created_by",    $nuh);
	    &setFactInfo($lhs, "created_time",  time());
	} else {
	    &dbReplace("factoids", "factoid_key", (
		created_by	=> $nuh,
		created_time	=> time(),	# modified time.
		factoid_key	=> $lhs,
		factoid_value	=> $rhs,
	    ) );
	}

	if (!defined $rhs or $rhs eq "") {
	    &ERROR("Update: rhs1 == NULL.");
	}

	return 1;
    }

    # factoid exists.
    if ($exists eq $rhs) {
	# this catches the following situation: (right or wrong?)
	#    "test is test"
	#    "test is also test"
	&performAddressedReply("i already had it that way");
	return 1;
    }

    if ($also) {			# 'is also'.
	if ($exists =~ /^<REPLY> see /i) {
	    &DEBUG("Update.pl: todo: append to linked factoid.");
	}

	if ($also_or) {			# 'is also ||'.
	    $rhs = $exists.' || '.$rhs;
	} else {
#	    if ($exists =~ s/\,\s*$/,  /) {
	    if ($exists =~ /\,\s*$/) {
		&DEBUG("current has trailing comma, just append as is");
		&DEBUG("Up: exists => $exists");
		&DEBUG("Up: rhs    => $rhs");
		# $rhs =~ s/^\s+//;
		# $rhs = $exists." ".$rhs;	# keep comma.
	    }

	    if ($exists =~ /\.\s*$/) {
		&DEBUG("current has trailing period, just append as is with 2 WS");
		&DEBUG("Up: exists => $exists");
		&DEBUG("Up: rhs    => $rhs");
		# $rhs =~ s/^\s+//;
		# use ucfirst();?
		# $rhs = $exists."  ".$rhs;	# keep comma.
	    }

	    if ($rhs =~ /^[A-Z]/) {
		if ($rhs =~ /\w+\s*$/) {
		    &status("auto insert period to factoid.");
		    $rhs = $exists.".  ".$rhs;
		} else {	# '?' or '.' assumed at end.
		    &status("orig factoid already had trailing symbol; not adding period.");
		    $rhs = $exists."  ".$rhs;
		}
	    } elsif ($exists =~ /[\,\.\-]\s*$/) {
		&VERB("U: current has trailing symbols; inserting whitespace + new.",2);
		$rhs = $exists." ".$rhs;
	    } elsif ($rhs =~ /^\./) {
		&VERB("U: new text has ^.; appending directly",2);
		$rhs = $exists.$rhs;
	    } else {
		$rhs = $exists.', or '.$rhs;
	    }
	}

	# max length check again.
	if (length $rhs > $param{'maxDataSize'}) {
	    if (length $rhs > length $exists) {
		&performAddressedReply("that's too long");
		return 1;
	    } else {
		&status("Update: new length is still longer than maxDataSize but less than before, we'll let it go.");
	    }
	}

	&performAddressedReply("okay");

	$count{'Update'}++;
	&status("update: <$who> \'$lhs\' =$mhs=> \'$rhs\'; was \'$exists\'");
	&AddModified($lhs,$nuh);
	&setFactInfo($lhs, "factoid_value", $rhs);

	if (!defined $rhs or $rhs eq "") {
	    &ERROR("Update: rhs1 == NULL.");
	}
    } else {				# not "also"

	if (!$correction_plausible) {	# "no, blah is ..."
	    if ($addressed) {
		&performStrictReply("...but \002$lhs\002 is already something else...");
		&status("FAILED update: <$who> \'$lhs\' =$mhs=> \'$rhs\'");
	    }
	    return 1;
	}

	my $author = &getFactInfo($lhs, "created_by") || "";

	if (IsFlag("m") ne "m" and $author !~ /^\Q$who\E\!/i) {
	    &msg($who, "you can't change that factoid.");
	    return 1;
	}

	&performAddressedReply("okay");

	$count{'Update'}++;
	&status("update: <$who> \'$lhs\' =$mhs=> \'$rhs\'; was \'$exists\'");

	# should dbReplace be used here?
	&delFactoid($lhs);
	&setFactInfo($lhs,"created_by", $nuh);
	&setFactInfo($lhs,"created_time", time());
	&setFactInfo($lhs,"factoid_value", $rhs);

	if (!defined $rhs or $rhs eq "") {
	    &ERROR("Update: rhs1 == NULL.");
	}
    }

    return 1;
}

1;
