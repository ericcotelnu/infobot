###
### Process.pl: Kevin Lenzo 1997-1999
###

#
# process the incoming message
#

if (&IsParam("useStrict")) { use strict; }

sub process {
    $learnok	= 0;	# Able to learn?
    $talkok	= 0;	# Able to yap?
    $force_public_reply = 0;
    $literal	= 0;

    return 'X'			if $who eq $ident;	# self-message.
    return 'addressedother set' if ($addressedother);

    $talkok	= ($param{'addressing'} =~ /^OPTIONAL$/i or $addressed);
    $learnok	= ($param{'learn'}      =~ /^HUNGRY$/i   or $addressed);

    &shmFlush();		# hack.

    # check if we have our head intact.
    if ($lobotomized) {
	if ($addressed and IsFlag("o") eq "o") {
	    my $delta_time	= time() - ($cache{lobotomy}{$who} || 0);
	    &msg($who, "give me an unlobotomy.") if ($delta_time > 60*60);
	    $cache{lobotomy}{$who} = time();
	}
	return 'LOBOTOMY';
    }

    # talkMethod.
    if ($param{'talkMethod'} =~ /^PRIVATE$/i) {
	if ($msgType =~ /public/ and $addressed) {
	    &msg($who, "sorry. i'm in 'PRIVATE' talkMethod mode ".
		  "while you sent a message to me ${msgType}ly.");

	    return 'TALKMETHOD';
	}
    }

    # join, must be done before outsider checking.
    if ($message =~ /^join(\s+(.*))?\s*$/i) {
	return 'join: not addr' unless ($addressed);

	$2 =~ /^($mask{chan})(,(\S+))?/;
	my($thischan, $key) = (lc $1, $3);
	my $chankey	= lc $thischan;
	$chankey	.= " $key"	if (defined $key);

	if ($thischan eq "") {
	    &help("join");
	    return;
	}

	if (&IsFlag("o") ne "o") {
	    if (!exists $chanconf{$thischan}) {
		&msg($who, "I am not allowed to join $thischan.");
		return;
	    }

	    if (&validChan($thischan)) {
		&msg($who,"warn: I'm already on $thischan, joining  anyway...");
#		return;
	    }
	}
	$cache{join}{$thischan} = $who;	# used for on_join self.

	&joinchan($chankey);
	&status("JOIN $chankey <$who>");
	&msg($who, "joining $chankey");
	&joinNextChan();	# hack.

	return;
    }

    # 'identify'
    if ($msgType =~ /private/ and $message =~ s/^identify//i) {
	$message =~ s/^\s+|\s+$//g;
	my @array = split / /, $message;

	if ($who =~ /^_default$/i) {
	    &pSReply("you are too eleet.");
	    return;
	}

	if (!scalar @array or scalar @array > 2) {
	    &help("identify");
	    return;
	}

	my $do_nick = $array[1] || $who;

	if (!exists $users{$do_nick}) {
	    &pSReply("nick $do_nick is not in user list.");
	    return;
	}

	my $crypt = $users{$do_nick}{PASS};
	if (!defined $crypt) {
	    &pSReply("user $do_nick has no passwd set.");
	    return;
	}

	if (!&ckpasswd($array[0], $crypt)) {
	    &pSReply("invalid passwd for $do_nick.");
	    return;
	}

	my $mask = "*!$user@".&makeHostMask($host);
	### TODO: prevent adding multiple dupe masks?
	### TODO: make &addHostMask() CMD?
	&pSReply("Added $mask for $do_nick...");
	$users{$do_nick}{HOSTS}{$mask} = 1;

	return;
    }

    # 'pass'
    if ($msgType =~ /private/ and $message =~ s/^pass//i) {
	$message =~ s/^\s+|\s+$//g;
	my @array = split ' ', $message;

	if ($who =~ /^_default$/i) {
	    &pSReply("you are too eleet.");
	    return;
	}

	if (scalar @array != 1) {
	    &help("pass");
	    return;
	}

	# todo: use &getUser()?
	my $first	= 1;
	foreach (keys %users) {
	    if ($users{$_}{FLAGS} =~ /n/) {
		$first = 0;
		last;
	    }
	}

	if (!exists $users{$who} and !$first) {
	    &pSReply("nick $who is not in user list.");
	    return;
	}

	if ($first) {
	    &pSReply("First time user... adding you as Master.");
	    $users{$who}{FLAGS} = "mrsteon";
	}

	my $crypt = $users{$who}{PASS};
	if (defined $crypt) {
	    &pSReply("user $who already has pass set.");
	    return;
	}

	if (!defined $host) {
	    &WARN("pass: host == NULL.");
	    return;
	}

	if (!scalar keys %{ $users{$who}{HOSTS} }) {
	    my $mask = "*!$user@".&makeHostMask($host);
	    &pSReply("Added hostmask '\002$mask\002' to $who");
	    $users{$who}{HOSTS}{$mask}	= 1;
	}

	$crypt			= &mkcrypt($array[0]);
	$users{$who}{PASS}	= $crypt;
	&pSReply("new pass for $who, crypt $crypt.");

	return;
    }

    # allowOutsiders.
    if (&IsParam("disallowOutsiders") and $msgType =~ /private/i) {
	my $found = 0;

	foreach (keys %channels) {
	    next unless (&IsNickInChan($who,$_));

	    $found++;
	    last;
	}

	if (!$found and scalar(keys %channels)) {
	    &status("OUTSIDER <$who> $message");
	    return 'OUTSIDER';
	}
    }

    # override msgType.
    if ($msgType =~ /public/ and $message =~ s/^\+//) {
	&status("Process: '+' flag detected; changing reply to public");
	$msgType = 'public';
	$who	 = $chan;	# major hack to fix &msg().
	$force_public_reply++;
	# notice is still NOTICE but to whole channel => good.
    }

    # User Processing, for all users.
    if ($addressed) {
	my $retval;
	return 'returned from pCH'   if &parseCmdHook("main",$message);

	$retval	= &userCommands();
	return unless (defined $retval);
	return if ($retval eq $noreply);
    }

    ###
    # once useless messages have been parsed out, we match them.
    ###

    # confused? is this for infobot communications?
    foreach (keys %{ $lang{'confused'} }) {
	my $y = $_;

	next unless ($message =~ /^\Q$y\E\s*/);
	return 'CONFUSO';
    }

    # hello. [took me a while to fix this. -xk]
    if ($orig{message} =~ /^(\Q$ident\E\S?[:, ]\S?)?\s*(h(ello|i( there)?|owdy|ey|ola))( \Q$ident\E)?\s*$/i) {
	return '' unless ($talkok);

	# 'mynick: hi' or 'hi mynick' or 'hi'.
	&status("somebody said hello");

	# 50% chance of replying to a random greeting when not addressed
	if (!defined $5 and $addressed == 0 and rand() < 0.5) {
	    &status("not returning unaddressed greeting");
	    return;
	}

	# customized random message.
	my $tmp = (rand() < 0.5) ? ", $who" : "";
	&performStrictReply(&getRandom(keys %{ $lang{'hello'} }) . $tmp);
	return;
    }

    # greetings.
    if ($message =~ /how (the hell )?are (ya|you)( doin\'?g?)?\?*$/) {
	my $reply = &getRandom(keys %{ $lang{'howareyou'} });

	&performReply($reply);
        
	return;
    }

    # praise.
    if ($message =~ /you (rock|rewl|rule|are so+ coo+l)/ ||
	$message =~ /(good (bo(t|y)|g([ui]|r+)rl))|(bot( |\-)?snack)/i)
    {
	return 'praise: no addr' unless ($addressed);

	&status("random praise detected");

	my $tmp = (rand() < 0.5) ? "thanks $who " : "";
	&performStrictReply($tmp.":)");

	return;
    }

    # thanks.
    if ($message =~ /^than(ks?|x)( you)?( \S+)?/i) {
	return 'thank: no addr' unless ($message =~ /$ident/ or $talkok);

	&performReply( &getRandom(keys %{ $lang{'welcome'} }) );
	return;
    }

    ###
    ### bot commands...
    ###

    # karma. set...
    if ($message =~ /^(\S+)(--|\+\+)\s*$/ and $addressed) {
	return '' unless (&hasParam("karma"));

	my($term,$inc) = (lc $1,$2);

	if ($msgType !~ /public/i) {
	    &msg($who, "karma must be done in public!");
	    return;
	}

	if (lc $term eq lc $who) {
	    &msg($who, "please don't karma yourself");
	    return;
	}

	my $karma = &dbGet("stats", "counter", "nick=".&dbQuote($term).
			" AND type='karma'") || 0;
	if ($inc eq '++') {
	    $karma++;
	} else {
	    $karma--;
	}

	&dbSet("stats", 
		{ nick => $term, type => "karma" },
		{ counter => $karma }
	);

	return;
    }

    # here's where the external routines get called.
    # if they return anything but null, that's the "answer".
    if ($addressed) {
	if ( &parseCmdHook("extra",$message) ) {
	    return 'DID SOMETHING IN PCH.';
	}

	my $er = &Modules();
	if (!defined $er) {
	    return 'SOMETHING 1';
	}

	if (0 and $addrchar) {
	    &msg($who, "I don't trust people to use the core commands while addressing me in a short-cut way.");
	    return;
	}
    }

    if (&IsParam("factoids") and $param{'DBType'} =~ /^(mysql|pg|postgres|dbm)/i) {
	&FactoidStuff();
    } elsif ($param{'DBType'} =~ /^none$/i) {
	return "NO FACTOIDS.";
    } else {
	&ERROR("INVALID FACTOID SUPPORT? ($param{'DBType'})");
	&shutdown();
	exit 0;
    }
}

1;
