#
#  UserDCC.pl: User Commands, DCC CHAT.
#      Author: dms
#     Version: v0.1 (20000707)
#     Created: 20000707 (from UserExtra.pl)
#

if (&IsParam("useStrict")) { use strict; }

sub userDCC {
    # hrm...
    $message =~ s/\s+$//;

    ### for all users.
    # quit.
    if ($message =~ /^(exit|quit)$/i) {
	# do ircII clients support remote close? if so, cool!
	&status("userDCC: quit called. FIXME");
###	$irc->removeconn($dcc{'CHAT'}{lc $who});

	return 'NOREPLY';
    }

    # who.
    if ($message =~ /^who$/i) {
	my $count = scalar(keys %{$dcc{'CHAT'}});
	&performStrictReply("Start of who ($count users).");
	foreach (keys %{$dcc{'CHAT'}}) {
	    &performStrictReply("=> $_");
	}
	&performStrictReply("End of who.");

	return 'NOREPLY';
    }

    ### for those users with enough flags.

    # 4op.
    if ($message =~ /^4op(\s+($mask{chan}))?$/i) {
	return 'NOREPLY' unless (&hasFlag("o"));

	my $chan = $2;

	if ($chan eq "") {
	    &help("4op");
	    return 'NOREPLY';
	}

	if (!$channels{$chan}{'o'}{$ident}) {
	    &msg($who, "i don't have ops on $chan to do that.");
	    return 'NOREPLY';
	}

	# on non-4mode(<4) servers, this may be exploited.
	if ($channels{$chan}{'o'}{$who}) {
	    rawout("MODE $chan -o+o-o+o". (" $who" x 4));
	} else {
	    rawout("MODE $chan +o-o+o-o". (" $who" x 4));
	}

	return 'NOREPLY';
    }

    # backlog.
    if ($message =~ /^backlog(\s+(.*))?$/i) {
	return 'NOREPLY' unless (&hasFlag("o"));
	return 'NOREPLY' unless (&hasParam("backlog"));
	my $num = $2;
	my $max = $param{'backlog'};

	if (!defined $num) {
	    &help("backlog");
	    return 'NOREPLY';
	} elsif ($num !~ /^\d+/) {
	    &msg($who, "error: argument is not positive integer.");
	    return 'NOREPLY';
	} elsif ($num > $max or $num < 0) {
	    &msg($who, "error: argument is out of range (max $max).");
	    return 'NOREPLY';
	}

	&msg($who, "Start of backlog...");
	for (0..$num-1) {
	    sleep 1 if ($_ % 4 == 0 and $_ != 0);
	    $conn->privmsg($who, "[".($_+1)."]: $backlog[$max-$num+$_]");
	}
	&msg($who, "End of backlog.");

	return 'NOREPLY';
    }

    # dump variables.
    if ($message =~ /^dumpvars$/i) {
	return 'NOREPLY' unless (&hasFlag("o"));
	return '' unless (&IsParam("dumpvars"));

	&status("Dumping all variables...");
	&dumpallvars();

	return 'NOREPLY';
    }

    # kick.
    if ($message =~ /^kick(\s+(\S+)(\s+(\S+))?)?/) {
	return 'NOREPLY' unless (&hasFlag("o"));
	my ($nick,$chan) = (lc $2,lc $4);

	if ($nick eq "") {
	    &help("kick");
	    return 'NOREPLY';
	}

	if (&validChan($chan) == 0) {
	    &msg($who,"error: invalid channel \002$chan\002");
	    return 'NOREPLY';
	}

	if (&IsNickInChan($nick,$chan) == 0) {
	    &msg($who,"$nick is not in $chan.");
	    return 'NOREPLY';
	}

	&kick($nick,$chan);

	return 'NOREPLY';
    }

    # ignore.
    if ($message =~ /^ignore(\s+(\S+))?$/i) {
	return 'NOREPLY' unless (&hasFlag("o"));
	my $what = lc $2;

	if ($what eq "") {
	    &help("ignore");
	    return 'NOREPLY';
	}

	my $expire = $param{'ignoreTempExpire'} || 60;
	$ignoreList{$what} = time() + ($expire * 60);
	&status("ignoring $what at $who's request");
	&msg($who, "added $what to the ignore list");

	return 'NOREPLY';
    }

    # unignore.
    if ($message =~ /^unignore(\s+(\S+))?$/i) {
	return 'NOREPLY' unless (&hasFlag("o"));
	my $what = $2;

	if ($what eq "") {
	    &help("unignore");
	    return 'NOREPLY';
	}

	if ($ignoreList{$what}) {
	    &status("unignoring $what at $userHandle's request");
	    delete $ignoreList{$what};
	    &msg($who, "removed $what from the ignore list");
	} else {
	    &status("unignore FAILED for $1 at $who's request");
	    &msg($who, "no entry for $1 on the ignore list");
	}
	return 'NOREPLY';
    }

    # clear unignore list.
    if ($message =~ /^clear ignorelist$/i) {
	return 'NOREPLY' unless (&hasFlag("o"));
	undef %ignoreList;
	&status("unignoring all ($who said the word)");

	return 'NOREPLY';
    }

    # lobotomy. sometimes we want the bot to be _QUIET_.
    if ($message =~ /^(lobotomy|bequiet)$/i) {
	return 'NOREPLY' unless (&hasFlag("o"));

	if ($lobotomized) {
	    &performReply("i'm already lobotomized");
	} else {
	    &performReply("i have been lobotomized");
	    $lobotomized = 1;
	}

	return 'NOREPLY';
    }

    # unlobotomy.
    if ($message =~ /^(unlobotomy|benoisy)$/i) {
	return 'NOREPLY' unless (&hasFlag("o"));
	if ($lobotomized) {
	    &performReply("i have been unlobotomized, woohoo");
	    $lobotomized = 0;
	} else {
	    &performReply("i'm not lobotomized");
	}
	return 'NOREPLY';
    }

    # op.
    if ($message =~ /^op(\s+(.*))?$/i) {
	return 'NOREPLY' unless (&hasFlag("o"));
	my ($opee) = lc $2;
	my @chans;

	if ($opee =~ / /) {
	    if ($opee =~ /^(\S+)\s+(\S+)$/) {
		$opee  = $1;
		@chans = ($2);
		if (!&validChan($2)) {
		    &msg($who,"error: invalid chan ($2).");
		    return 'NOREPLY';
		}
	    } else {
		&msg($who,"error: invalid params.");
		return 'NOREPLY';
	    }
	} else {
	    @chans = keys %channels;
	}

	my $found = 0;
	my $op = 0;
	foreach (@chans) {
	    next unless (&IsNickInChan($opee,$_));
	    $found++;
	    if ($channels{$_}{'o'}{$opee}) {
		&status("op: $opee already has ops on $_");
		next;
	    }
	    $op++;

	    &status("opping $opee on $_ at ${who}'s request");
	    &op($_, $opee);
	}

	if ($found != $op) {
	    &status("op: opped on all possible channels.");
	} else {
	    &DEBUG("found => '$found'.");
	    &DEBUG("op => '$op'.");
	}

	return 'NOREPLY';
    }

    # deop.
    if ($message =~ /^deop(\s+(.*))?$/i) {
	return 'NOREPLY' unless (&hasFlag("o"));
	my ($opee) = lc $2;
	my @chans;

	if ($opee =~ / /) {
	    if ($opee =~ /^(\S+)\s+(\S+)$/) {
		$opee  = $1;
		@chans = ($2);
		if (!&validChan($2)) {
		    &msg($who,"error: invalid chan ($2).");
		    return 'NOREPLY';
		}
	    } else {
		&msg($who,"error: invalid params.");
		return 'NOREPLY';
	    }
	} else {
	    @chans = keys %channels;
	}

	my $found = 0;
	my $op = 0;
	foreach (@chans) {
	    next unless (&IsNickInChan($opee,$_));
	    $found++;
	    if (!exists $channels{$_}{'o'}{$opee}) {
		&status("deop: $opee already has no ops on $_");
		next;
	    }
	    $op++;

	    &status("deopping $opee on $_ at ${who}'s request");
	    &deop($_, $opee);
	}

	if ($found != $op) {
	    &status("deop: deopped on all possible channels.");
	} else {
	    &DEBUG("deop: found => '$found'.");
	    &DEBUG("deop: op => '$op'.");
	}

	return 'NOREPLY';
    }

    # say.
    if ($message =~ s/^say\s+(\S+)\s+(.*)//) {
	return 'NOREPLY' unless (&hasFlag("o"));
	my ($chan,$msg) = (lc $1, $2);
	&DEBUG("chan => '$1', msg => '$msg'.");

	if (&validChan($chan)) {
	    &msg($chan, $2);
	} else {
	    &msg($who,"i'm not on \002$1\002, sorry.");
	}
	return 'NOREPLY';
    }

    # die.
    if ($message =~ /^die$/) {
	return 'NOREPLY' unless (&hasFlag("n"));

	&doExit();

	status("Dying by $who\'s request");
	exit 0;
    }

    # jump.
    if ($message =~ /^jump(\s+(\S+))?$/i) {
	return 'NOREPLY' unless (&hasFlag("n"));

	if ($2 eq "") {
	    &help("jump");
	    return 'NOREPLY';
	}

	my ($server,$port);
	if ($2 =~ /^(\S+)(:(\d+))?$/) {
	    $server = $1;
	    $port   = $3 || 6667;
	} else {
	    &msg($who,"invalid format.");
	    return 'NOREPLY';
	}

	&status("jumping servers... $server...");
	&rawout("QUIT :jumping to $server");

	if (&irc($server,$port) == 0) {
	    &ircloop();
	}
    }

    # reload.
    if ($message =~ /^reload$/i) {
	return 'NOREPLY' unless (&hasFlag("n"));

	&status("USER reload $who");
	&msg($who,"reloading...");
	&reloadModules();
	&msg($who,"reloaded.");

	return 'NOREPLY';
    }

    # rehash.
    if ($message =~ /^rehash$/) {
	return 'NOREPLY' unless (&hasFlag("n"));

	&msg($who,"rehashing...");
	&restart("REHASH");
	&status("USER rehash $who");
	&msg($who,"rehashed");

	return 'NOREPLY';
    }

    # set.
    if ($message =~ /^set(\s+(\S+)?(\s+(.*))?)?$/i) {
	return 'NOREPLY' unless (&hasFlag("n"));
	my ($param,$what) = ($2,$4);

	if ($param eq "" and $what eq "") {
	    &msg($who,"\002Usage\002: set <param> [what]");
	    return 'NOREPLY';
	}

	if (!exists $param{$param}) {
	    &msg($who,"error: param{$param} cannot be set");
	    return 'NOREPLY';
	}

	if ($what eq "") {
	    if ($param{$param} eq "") {
		&msg($who,"param{$param} has \002no value\002.");
	    } else {
		&msg($who,"param{$param} has value of '\002$param{$param}\002'.");
	    }
	    return 'NOREPLY';
	}

	if ($param{$param} eq $what) {
	    &msg($who,"param{$param} already has value of '\002$what\002'.");
	    return 'NOREPLY';
	}

	$param{$param} = $what;
	&msg($who,"setting param{$param} to '\002$what\002'.");

	return 'NOREPLY';
    }

    # unset.
    if ($message =~ /^unset(\s+(\S+))?$/i) {
	return 'NOREPLY' unless (&hasFlag("n"));
	my ($param) = $2;

	if ($param eq "") {
	    &msg($who,"\002Usage\002: unset <param>");
	    return 'NOREPLY';
	}

	if (!exists $param{$param}) {
	    &msg($who,"error: \002$param\002 cannot be unset");
	    return 'NOREPLY';
	}

	if ($param{$param} == 0) {
	    &msg($who,"\002param{$param}\002 has already been unset.");
	    return 'NOREPLY';
	}

	$param{$param} = 0;
	&msg($who,"unsetting \002param{$param}\002.");

	return 'NOREPLY';
    }

    # more...
}

1;
