#
# IrcHooks.pl: IRC Hooks stuff.
#      Author: dms
#     Version: 20000126
#        NOTE: Based on code by Kevin Lenzo & Patrick Cole  (c) 1997
#

if (&IsParam("useStrict")) { use strict; }

# GENERIC. TO COPY.
sub on_generic {
    my ($self, $event) = @_;
    my $nick = $event->nick();
    my $chan = ($event->to)[0];

    &DEBUG("on_generic: nick => '$nick'.");
    &DEBUG("on_generic: chan => '$chan'.");

    foreach ($event->args) {
	&DEBUG("on_generic: args => '$_'.");
    }
}

sub on_action {
    my ($self, $event) = @_;
    my ($nick, @args) = ($event->nick, $event->args);
    my $chan = ($event->to)[0];

    shift @args;

    if ($chan eq $ident) {
	&status("* [$nick] @args");
    } else {
	&status("* $nick/$chan @args");
    }
}

sub on_chat {
    my ($self, $event) = @_;
    my $msg  = ($event->args)[0];
    my $sock = ($event->to)[0];
    my $nick = lc $event->nick();

    if (!exists $nuh{$nick}) {
	&DEBUG("chat: nuh{$nick} doesn't exist; trying WHOIS .");
	$self->whois($nick);
	return;
    }

    ### set vars that would have been set in hookMsg.
    $userHandle		= "";	# reset.
    $who		= lc $nick;
    $message		= $msg;
    $orig{who}		= $nick;
    $orig{message}	= $msg;
    $nuh		= $nuh{$who};
    $uh			= (split /\!/, $nuh)[1];
    $addressed		= 1;
    $msgType		= 'chat';

    if (!exists $dcc{'CHATvrfy'}{$nick}) {
	$userHandle	= &verifyUser($who, $nuh);
	my $crypto	= $users{$userHandle}{PASS};
	my $success	= 0;

	### TODO: prevent users without CRYPT chatting.
	if (!defined $crypto) {
	    &DEBUG("todo: dcc close chat");
	    &msg($who, "nope, no guest logins allowed...");
	    return;
	}

	if (&ckpasswd($msg, $crypto)) {
	    # stolen from eggdrop.
	    $self->privmsg($sock, "Connected to $ident");
	    $self->privmsg($sock, "Commands start with '.' (like '.quit' or '.help')");
	    $self->privmsg($sock, "Everything else goes out to the party line.");

	    &dccStatus(2) unless (exists $sched{"dccStatus"}{RUNNING});

	    $success++;

	} else {
	    &status("DCC CHAT: incorrect pass; closing connection.");
	    &DEBUG("chat: sock => '$sock'.");
###	    $sock->close();
	    delete $dcc{'CHAT'}{$nick};
	    &DEBUG("chat: after closing sock. FIXME");
	    ### BUG: close seizes bot. why?
	}

	if ($success) {
	    &status("DCC CHAT: user $nick is here!");
	    &DCCBroadcast("*** $nick ($uh) joined the party line.");

	    $dcc{'CHATvrfy'}{$nick} = $userHandle;

	    return if ($userHandle eq "_default");

	    &dccsay($nick,"Flags: $users{$userHandle}{FLAGS}");
	}

	return;
    }

    &status("$b_red=$b_cyan$who$b_red=$ob $message");

    if ($message =~ s/^\.//) {	# dcc chat commands.
	### TODO: make use of &Forker(); here?
	&loadMyModule( $myModules{'ircdcc'} );

	&DCCBroadcast("#$who# $message","m");

	my $retval	= &userDCC();
	return unless (defined $retval);
	return if ($retval eq $noreply);

	$conn->privmsg($dcc{'CHAT'}{$who}, "Invalid command.");

    } else {			# dcc chat arena.

	foreach (keys %{$dcc{'CHAT'}}) {
	    $conn->privmsg($dcc{'CHAT'}{$_}, "<$who> $orig{message}");
	}
    }

    return 'DCC CHAT MESSAGE';
}

sub on_endofmotd {
    my ($self) = @_;

    # what's the following for?
    $ident			= $param{'ircNick'};
    # update IRCStats.
    $ircstats{'ConnectTime'}	= time();
    $ircstats{'ConnectCount'}++;
    $ircstats{'OffTime'}	+= time() - $ircstats{'DisconnectTime'}
			if (defined $ircstats{'DisconnectTime'});

    # first time run.
    if (!exists $users{_default}) {
	&status("First time run... adding _default user.");
	$users{_default}{FLAGS}	= "mrt";
	$users{_default}{HOSTS} = "*!*@*";
    }

    if (scalar keys %users < 2) {
	&status("Ok... now /msg $ident PASS <pass> to get master access through DCC CHAT.");
    }
    # end of first time run.

    if (&IsChanConf("wingate")) {
	my $file = "$bot_base_dir/$param{'ircUser'}.wingate";
	open(IN, $file);
	while (<IN>) {
	    chop;
	    next unless (/^(\S+)\*$/);
	    push(@wingateBad, $_);
	}
	close IN;
    }

    if ($firsttime) {
	&ScheduleThis(1, \&setupSchedulers);
	$firsttime = 0;
    }

    if (&IsParam("ircUMode")) {
	&status("Attempting change of user modes to $param{'ircUMode'}.");
	&rawout("MODE $ident $param{'ircUMode'}");
    }

    &status("End of motd. Now lets join some channels...");
    if (!scalar @joinchan) {
	&WARN("joinchan array is empty!!!");
	@joinchan = &getJoinChans();
    }

    &joinNextChan();
}

sub on_dcc {
    my ($self, $event) = @_;
    my $type = uc( ($event->args)[1] );
    my $nick = lc $event->nick();

    # pity Net::IRC doesn't store nuh. Here's a hack :)
    if (!exists $nuh{lc $nick}) {
	$self->whois($nick);
	$nuh{$nick}	= "GETTING-NOW";	# trying.
    }
    $type ||= "???";

    if ($type eq 'SEND') {	# GET for us.
	# incoming DCC SEND. we're receiving a file.
	my $get = ($event->args)[2];
	open(DCCGET,">$get");

	$self->new_get($nick,
		($event->args)[2],
		($event->args)[3],
		($event->args)[4],
		($event->args)[5],
		\*DCCGET
	);
    } elsif ($type eq 'GET') {	# SEND for us?
	&status("DCC: Initializing SEND for $nick.");
	$self->new_send($event->args);
    } elsif ($type eq 'CHAT') {
	&status("DCC: Initializing CHAT for $nick.");
	$self->new_chat($event);
    } else {
	&WARN("${b_green}DCC $type$ob (1)");
    }
}

sub on_dcc_close {
    my ($self, $event) = @_;
    my $nick = $event->nick();
    my $sock = ($event->to)[0];

    # DCC CHAT close on fork exit workaround.
    if ($bot_pid != $$) {
	&WARN("run-away fork; exiting.");
	&delForked($forker);
    }

    if (exists $dcc{'SEND'}{$nick} and -f "$param{tempDir}/$nick.txt") {
	&status("${b_green}DCC SEND$ob close from $b_cyan$nick$ob");

	&status("dcc_close: purging $nick.txt from Debian.pl");
	unlink "$param{tempDir}/$nick.txt";

	delete $dcc{'SEND'}{$nick};
    } elsif (exists $dcc{'CHAT'}{$nick} and $dcc{'CHAT'}{$nick} eq $sock) {
	&status("${b_green}DCC CHAT$ob close from $b_cyan$nick$ob");
	delete $dcc{'CHAT'}{$nick};
	delete $dcc{'CHATvrfy'}{$nick};
    } else {
	&status("${b_green}DCC$ob UNKNOWN close from $b_cyan$nick$ob (2)");
    }
}

sub on_dcc_open {
    my ($self, $event) = @_;
    my $type = uc( ($event->args)[0] );
    my $nick = lc $event->nick();
    my $sock = ($event->to)[0];

    $msgType = 'chat';
    $type ||= "???";
    ### BUG: who is set to bot's nick?

    # lets do it.
    if ($type eq 'SEND') {
	&status("${b_green}DCC lGET$ob established with $b_cyan$nick$ob");

    } elsif ($type eq 'CHAT') {
	# very cheap hack.
	### TODO: run ScheduleThis inside on_dcc_open_chat recursively
	###	1,3,5,10 seconds then fail.
	if ($nuh{$nick} eq "GETTING-NOW") {
	    &ScheduleThis(3/60, "on_dcc_open_chat", $nick, $sock);
	} else {
	    on_dcc_open_chat(undef, $nick, $sock);
	}

    } elsif ($type eq 'SEND') {
	&DEBUG("Starting DCC receive.");
	foreach ($event->args) {
	    &DEBUG("  => '$_'.");
	}

    } else {
	&WARN("${b_green}DCC $type$ob (3)");

    }
}

# really custom sub to get NUH since Net::IRC doesn't appear to support
# it.
sub on_dcc_open_chat {
    my(undef, $nick, $sock) = @_;

    if ($nuh{$nick} eq "GETTING-NOW") {
	&DEBUG("getting nuh for $nick failed. FIXME.");
	return;
    }

    &status("${b_green}DCC CHAT$ob established with $b_cyan$nick$ob $b_yellow($ob$nuh{$nick}$b_yellow)$ob");

    &verifyUser($nick, $nuh{lc $nick});

    if (!exists $users{$userHandle}{HOSTS}) {
	&pSReply("you have no hosts defined in my user file; rejecting.");
	### TODO: $sock->close();
	return;
    }

    my $crypto	= $users{$userHandle}{PASS};
    $dcc{'CHAT'}{$nick} = $sock;

    if (defined $crypto) {
	&dccsay($nick,"Enter your password.");
    } else {
	&dccsay($nick,"Welcome to blootbot DCC CHAT interface, $userHandle.");
    }
}

sub on_disconnect {
    my ($self, $event) = @_;
    my $from = $event->from();
    my $what = ($event->args)[0];

    &status("disconnect from $from ($what).");
    $ircstats{'DisconnectTime'}		= time();
    $ircstats{'DisconnectReason'}	= $what;
    $ircstats{'DisconnectCount'}++;
    $ircstats{'TotalTime'}	+= time() - $ircstats{'ConnectTime'};

    # clear any variables on reconnection.
    $nickserv = 0;

    &clearIRCVars();
    if (!$self->connect()) {
	&WARN("not connected? help me. gonna call ircCheck() in 1800s");
	&ScheduleThis(30, "ircCheck");
    }
}

sub on_endofnames {
    my ($self, $event) = @_;
    my $chan = ($event->args)[1];

    if (exists $cache{jointime}{$chan}) {
	my $delta_time = sprintf("%.03f", &gettimeofday() - $cache{jointime}{$chan});
	$delta_time    = 0	if ($delta_time < 0);

	&status("$b_blue$chan$ob: sync in ${delta_time}s.");
    }

    rawout("MODE $chan");

    my $txt;
    my @array;
    foreach ("o","v","") {
	my $count = scalar(keys %{ $channels{$chan}{$_} });
	next unless ($count);

	$txt = "total" if ($_ eq "");
	$txt = "voice" if ($_ eq "v");
	$txt = "ops"   if ($_ eq "o");

	push(@array, "$count $txt");
    }
    my $chanstats = join(' || ', @array);
    &status("$b_blue$chan$ob: [$chanstats]");

    if (scalar @joinchan) {	# remaining channels to join.
	&joinNextChan();
    } else {
	&DEBUG("running ircCheck to get chanserv ops.");
	&ircCheck();
    }

    return unless (&IsChanConf("chanServ_ops") > 0);
    return unless ($nickserv);

    if (!exists $channels{$chan}{'o'}{$ident}) {
	&status("ChanServ ==> Requesting ops for $chan.");
	&rawout("PRIVMSG ChanServ :OP $chan $ident");
    }
}

sub on_init {
    my ($self, $event) = @_;
    my (@args) = ($event->args);
    shift @args;

    &status("@args");
}

sub on_invite {
    my ($self, $event) = @_;
    my $chan = lc( ($event->args)[0] );
    my $nick = $event->nick;

    if ($nick =~ /^\Q$ident\E$/) {
	&DEBUG("on_invite: self invite.");
	return;
    }

    ### TODO: join key.
    if (exists $chanconf{$chan}) {
	if (&validChan($chan)) {
	    &msg($who, "i'm already in \002$chan\002.");
	    next;
	}

	&status("invited to $b_blue$_$ob by $b_cyan$who$ob");
	&joinchan($self, $_);
    }
}

sub on_join {
    my ($self, $event) = @_;
    my ($user,$host) = split(/\@/, $event->userhost);
    $chan	= lc( ($event->to)[0] );	# CASING!!!!
    $who	= $event->nick();

    $chanstats{$chan}{'Join'}++;
    $userstats{lc $who}{'Join'} = time() if (&IsChanConf("seenStats"));

    &joinfloodCheck($who, $chan, $event->userhost);

    # netjoin detection.
    my $netsplit = 0;
    if (exists $netsplit{lc $who}) {
	delete $netsplit{lc $who};
	$netsplit = 1;
    }

    if ($netsplit and !$netsplittime) {
	&DEBUG("on_join: ok.... re-running chanlimitCheck in 60.");
	$conn->schedule(60, sub {
		&chanlimitCheck();
		$netsplittime = undef;
	} );

	$netsplittime = time();
    }

    # how to tell if there's a netjoin???

    my $netsplitstr = "";
    $netsplitstr = " $b_yellow\[${ob}NETSPLIT VICTIM$b_yellow]$ob" if ($netsplit);
    &status(">>> join/$b_blue$chan$ob $b_cyan$who$ob $b_yellow($ob$user\@$host$b_yellow)$ob$netsplitstr");

    $channels{$chan}{''}{$who}++;
    $nuh	  = $who."!".$user."\@".$host;
    $nuh{lc $who} = $nuh unless (exists $nuh{lc $who});

    ### on-join bans.
    my @bans;
    push(@bans, keys %{ $bans{$chan} }) if (exists $bans{$chan});
    push(@bans, keys %{ $bans{"*"} })  if (exists $bans{"*"});
    foreach (@bans) {
	my $ban	= $_;
	s/\?/./g;
	s/\*/\\S*/g;
	my $mask	= $_;
	next unless ($nuh =~ /^$mask$/i);

	### TODO: check $channels{$chan}{'b'} if ban already exists.
	foreach (keys %{ $channels{$chan}{'b'} }) {
	    &DEBUG(" bans_on_chan($chan) => $_");
	}

	my $reason = "no reason";
	foreach ($chan, "*") {
	    next unless (exists $bans{$_});
	    next unless (exists $bans{$_}{$ban});

	    my @array	= @{ $bans{$_}{$ban} };

	    $reason	= $array[4] if ($array[4]);
	    last;
	}

	&ban($ban, $chan);
	&kick($who, $chan, $reason);

	last;
    }

    ### ROOTWARN:
    &rootWarn($who,$user,$host,$chan)
		if (&IsChanConf("rootWarn") &&
		    $user =~ /^r(oo|ew|00)t$/i &&
		    $channels{$chan}{'o'}{$ident});

    ### NEWS:
    if (&IsChanConf("news") && &IsChanConf("newsKeepRead")) {
	# todo: what if it hasn't been loaded?
	&News::latest($chan);
    }

    ### chanlimit check.
    &chanLimitVerify($chan);

    # used to determine sync time.
    if ($who =~ /^$ident$/i) {
	if (defined( my $whojoin = $cache{join}{$chan} )) {
	    &msg($chan, "Okay, I'm here. (courtesy of $whojoin)");
	    delete $cache{join}{$chan};
	}

	### TODO: move this to &joinchan()?
	$cache{jointime}{$chan} = &gettimeofday();
	rawout("WHO $chan");
    } else {
	### TODO: this may go wild on a netjoin :)
	### WINGATE:
	&wingateCheck();
    }
}

sub on_kick {
    my ($self, $event) = @_;
    my ($chan,$reason) = $event->args;
    my $kicker	= $event->nick;
    my $kickee	= ($event->to)[0];
    my $uh	= $event->userhost();

    &status(">>> kick/$b_blue$chan$ob [$b$kickee!$uh$ob] by $b_cyan$kicker$ob $b_yellow($ob$reason$b_yellow)$ob");

    $chan = lc $chan;	# forgot about this, found by xsdg, 20001229.
    $chanstats{$chan}{'Kick'}++;

    if ($kickee eq $ident) {
	&clearChanVars($chan);

	&status("SELF attempting to rejoin lost channel $chan");
	&joinchan($chan);
    } else {
	&DeleteUserInfo($kickee,$chan);
    }
}

sub on_mode {
    my ($self, $event)	= @_;
    my ($user, $host)	= split(/\@/, $event->userhost);
    my @args = $event->args();
    my $nick = $event->nick();
    my $chan = ($event->to)[0];

    $args[0] =~ s/\s$//;

    if ($nick eq $chan) {	# UMODE
	&status(">>> mode $b_yellow\[$ob$b@args$b_yellow\]$ob by $b_cyan$nick$ob");
    } else {			# MODE
	&status(">>> mode/$b_blue$chan$ob $b_yellow\[$ob$b@args$b_yellow\]$ob by $b_cyan$nick$ob");
	&hookMode($chan, @args);
    }
}

sub on_modeis {
    my ($self, $event) = @_;
    my $nick = $event->nick();
    my ($myself,$chan,@args) = $event->args();

    &hookMode(lc $chan, @args);		# CASING.
}

sub on_msg {
    my ($self, $event) = @_;
    my $nick = $event->nick;
    my $msg  = ($event->args)[0];

    ($user,$host) = split(/\@/, $event->userhost);
    $uh		= $event->userhost();
    $nuh	= $nick."!".$uh;
    $msgtime	= time();

    if ($nick eq $ident) { # hopefully ourselves.
	if ($msg eq "TEST") {
	    &status("IRCTEST: Yes, we're alive.");
	    delete $cache{connect};
	    return;
	}
    }

    &hookMsg('private', undef, $nick, $msg);
}

sub on_names {
    my ($self, $event) = @_;
    my @args = $event->args;
    my $chan = lc $args[2];		# CASING, the last of them!

    foreach (split / /, @args[3..$#args]) {
	$channels{$chan}{'o'}{$_}++	if s/\@//;
	$channels{$chan}{'v'}{$_}++	if s/\+//;
	$channels{$chan}{''}{$_}++;
    }
}

sub on_nick {
    my ($self, $event) = @_;
    my $nick = $event->nick();
    my $newnick = ($event->args)[0];

    if (exists $netsplit{lc $newnick}) {
	&status("Netsplit: $newnick/$nick came back from netsplit and changed to original nick! removing from hash.");
	delete $netsplit{lc $newnick};
    }

    my ($chan,$mode);
    foreach $chan (keys %channels) {
	foreach $mode (keys %{$channels{$chan}}) {
	    next unless (exists $channels{$chan}{$mode}{$nick});

	    $channels{$chan}{$mode}{$newnick} = $channels{$chan}{$mode}{$nick};
	}
    }
    &DeleteUserInfo($nick,keys %channels);
    $nuh{lc $newnick} = $nuh{lc $nick};
    delete $nuh{lc $nick};

    # successful self-nick change.
    if ($nick eq $ident) {
	&status(">>> I materialized into $b_green$newnick$ob from $nick");
	$ident = $newnick;
    } else {
	&status(">>> $b_cyan$nick$ob materializes into $b_green$newnick$ob");
    }
}

sub on_nick_taken {
    my ($self) = @_;
    my $nick = $self->nick;
    my $newnick = substr($nick,0,7)."-";

    &status("nick taken; changing to temporary nick.");
    &nick($newnick);
    &getNickInUse(1);
}

sub on_notice {
    my ($self, $event) = @_;
    my $nick = $event->nick();
    my $chan = ($event->to)[0];
    my $args = ($event->args)[0];

    if ($nick =~ /^NickServ$/i) {		# nickserv.
	&status("NickServ: <== '$args'");

	my $check	= 0;
	$check++	if ($args =~ /^This nickname is registered/i);
	$check++	if ($args =~ /nickname.*owned/i);

	if ($check) {
	    &status("nickserv told us to register; doing it.");
	    if (&IsParam("nickServ_pass")) {
		&status("NickServ: ==> Identifying.");
		&rawout("PRIVMSG NickServ :IDENTIFY $param{'nickServ_pass'}");
		return;
	    } else {
		&status("We can't tell nickserv a passwd ;(");
	    }
	}

	# password accepted.
	if ($args =~ /^Password a/i) {
	    $nickserv++;
	}
    } elsif ($nick =~ /^ChanServ$/i) {		# chanserv.
	&status("ChanServ: <== '$args'.");
    } else {
	if ($chan =~ /^$mask{chan}$/) {	# channel notice.
	    &status("-$nick/$chan- $args");
	} else {
	    $server = $nick unless (defined $server);
	    &status("-$nick- $args");	# private or server notice.
	}
    }
}

sub on_other {
    my ($self, $event) = @_;
    my $chan = ($event->to)[0];
    my $nick = $event->nick;

    &status("!!! other called.");
    &status("!!! $event->args");
}

sub on_part {
    my ($self, $event) = @_;
    my $chan = lc( ($event->to)[0] );	# CASING!!!
    my $nick = $event->nick;
    my $userhost = $event->userhost;

    if (exists $floodjoin{$chan}{$nick}{Time}) {
	delete $floodjoin{$chan}{$nick};
    }

    $chanstats{$chan}{'Part'}++;
    &DeleteUserInfo($nick,$chan);
    &clearChanVars($chan) if ($nick eq $ident);
    if (!&IsNickInAnyChan($nick) and &IsChanConf("seenStats")) {
	delete $userstats{lc $nick};
    }

    &status(">>> part/$b_blue$chan$ob $b_cyan$nick$ob $b_yellow($ob$userhost$b_yellow)$ob");
}

sub on_ping {
    my ($self, $event) = @_;
    my $nick = $event->nick;

    $self->ctcp_reply($nick, join(' ', ($event->args)));
    &status(">>> ${b_green}CTCP PING$ob request from $b_cyan$nick$ob received.");
}

sub on_ping_reply {
    my ($self, $event) = @_;
    my $nick = $event->nick;
    my $lag = time() - ($event->args)[1];

    &status(">>> ${b_green}CTCP PING$ob reply from $b_cyan$nick$ob: $lag sec.");
}

sub on_public {
    my ($self, $event) = @_;
    my $msg  = ($event->args)[0];
    my $chan = lc( ($event->to)[0] );	# CASING.
    my $nick = $event->nick;
    $uh      = $event->userhost();
    $nuh     = $nick."!".$uh;
    ($user,$host) = split(/\@/, $uh);

    if ($bot_pid != $$) {
	&ERROR("run-away fork; exiting.");
	&delForked($forker);
    }

    ### DEBUGGING.
    if ($statcount < 200) {
	foreach $chan (grep /[A-Z]/, keys %channels) {
	    &DEBUG("leak: chan => '$chan'.");
	    my ($i,$j);
	    foreach $i (keys %{$channels{$chan}}) {  
		foreach (keys %{$channels{$chan}{$i}}) {
		    &DEBUG("leak:   \$channels{$chan}{$i}{$_} ...");
		}
	    }
	}
    }

    $msgtime = time();
    $lastWho{$chan} = $nick;
    ### TODO: use $nick or lc $nick?
    if (&IsChanConf("seenStats")) {
	$userstats{lc $nick}{'Count'}++;
	$userstats{lc $nick}{'Time'} = time();
    }

#    if (&IsChanConf("hehCounter")) {
#	#...
#    }

    &hookMsg('public', $chan, $nick, $msg);
    $chanstats{$chan}{'PublicMsg'}++;
}

sub on_quit {
    my ($self, $event) = @_;
    my $nick = $event->nick();
    my $reason = ($event->args)[0];

    my $count	= 0;
    foreach (keys %channels) {
	# fixes inconsistent chanstats bug #1.
	if (!&IsNickInChan($nick,$_)) {
	    $count++;
	    next;
	}
	$chanstats{$_}{'SignOff'}++;
    }

    if ($count == scalar keys %channels) {
	&DEBUG("on_quit: nick $nick was not found in any chan.");
    }

    &DeleteUserInfo($nick, keys %channels);

    if (exists $nuh{lc $nick}) {
	delete $nuh{lc $nick};
    } else {
	&DEBUG("on_quit: nuh{lc $nick} does not exist! FIXME");
    }
    delete $userstats{lc $nick} if (&IsChanConf("seenStats"));

    # should fix chanstats inconsistencies bug #2.
    if ($reason=~/^($mask{host})\s($mask{host})$/) {	# netsplit.
	$reason = "NETSPLIT: $1 <=> $2";

	if (&ChanConfList("chanlimitcheck") and !scalar keys %netsplit) {
	    &DEBUG("on_quit: netsplit detected; disabling chan limit.");
	    &rawout("MODE $chan -l");
	}

	$netsplit{lc $nick} = time();
	if (!exists $netsplitservers{$1}{$2}) {
	    &status("netsplit detected between $1 and $2.");
	    $netsplitservers{$1}{$2} = time();
	}
    }

    &status(">>> $b_cyan$nick$ob has signed off IRC $b_red($ob$reason$b_red)$ob");
    if ($nick =~ /^\Q$ident\E$/) {
	&DEBUG("^^^ THIS SHOULD NEVER HAPPEN.");
    }

    if ($nick !~ /^\Q$ident\E$/ and $nick =~ /^\Q$param{'ircNick'}\E$/i) {
	&status("own nickname became free; changing.");
	&nick($param{'ircNick'});
    }
}

sub on_targettoofast {
    my ($self, $event) = @_;
    my $nick = $event->nick();
    my($me,$chan,$why) = $event->args();

    ### TODO: incomplete.
###    .* wait (\d+) second/) {
	&status("on_ttf: X1 $msg") if (defined $msg);
	my $sleep = 5;
	&status("going to sleep for $sleep...");
	sleep $sleep;
	&joinNextChan();
### }
}

sub on_topic {
    my ($self, $event) = @_;

    if (scalar($event->args) == 1) {	# change.
	my $topic = ($event->args)[0];
	my $chan  = ($event->to)[0];
	my $nick  = $event->nick();

	###
	# WARNING:
	#	race condition here. To fix, change '1' to '0'.
	#	This will keep track of topics set by bot only.
	###
	# UPDATE:
	#	this may be fixed at a later date with topic queueing.
	###

	$topic{$chan}{'Current'} = $topic if (1);
	$chanstats{$chan}{'Topic'}++;

	&status(">>> topic/$b_blue$chan$ob by $b_cyan$nick$ob -> $topic");
    } else {						# join.
	my ($nick, $chan, $topic) = $event->args;
	if (&IsChanConf("topic")) {
	    $topic{$chan}{'Current'}	= $topic;
	    &topicAddHistory($chan,$topic);
	}

	$topic = &fixString($topic, 1);
	&status(">>> topic/$b_blue$chan$ob is $topic");
    }
}

sub on_topicinfo {
    my ($self, $event) = @_;
    my ($myself,$chan,$setby,$time) = $event->args();

    my $timestr;
    if (time() - $time > 60*60*24) {
	$timestr	= "at ". localtime $time;
    } else {
	$timestr	= &Time2String(time() - $time) ." ago";
    }

    &status(">>> set by $b_cyan$setby$ob $timestr");
}

sub on_crversion {
    my ($self, $event) = @_;
    my $nick	= $event->nick();
    my $ver;

    if (scalar $event->args() != 1) {	# old.
	$ver	= join ' ', $event->args();
	$ver	=~ s/^VERSION //;
    } else {				# new.
	$ver	= ($event->args())[0];
    }

    if (grep /^\Q$nick\E$/i, @vernick) {
	&WARN("nick $nick found in vernick; skipping.");
	return;
    }
    push(@vernick, $nick);

    if ($ver =~ /bitchx/i) {
	$ver{bitchx}{$nick}	= $ver;
    } elsif ($ver =~ /xc\!|xchat/i) {
	$ver{xchat}{$nick}	= $ver;
    } elsif ($ver =~ /irssi/i) {
	$ver{irssi}{$nick}	= $ver;
    } elsif ($ver =~ /epic/i) {
	$ver{epic}{$nick}	= $ver;
    } elsif ($ver =~ /mirc/i) {
	$ver{mirc}{$nick}	= $ver;
    } elsif ($ver =~ /ircle/i) {
	$ver{ircle}{$nick}	= $ver;
    } elsif ($ver =~ /ircII/i) {
	$ver{ircII}{$nick}	= $ver;
    } elsif ($ver =~ /sirc /i) {
	$ver{sirc}{$nick}	= $ver;
    } elsif ($ver =~ /kvirc/i) {
	$ver{kvirc}{$nick}	= $ver;
    } elsif ($ver =~ /eggdrop/i) {
	$ver{eggdrop}{$nick}	= $ver;
    } elsif ($ver =~ /xircon/i) {
	$ver{xircon}{$nick}	= $ver;
    } else {
	$ver{other}{$nick}	= $ver;
    }
}

sub on_version {
    my ($self, $event) = @_;
    my $nick = $event->nick;

    &status(">>> ${b_green}CTCP VERSION$ob request from $b_cyan$nick$ob");
    $self->ctcp_reply($nick, "VERSION $bot_version");
}

sub on_who {
    my ($self, $event) = @_;
    my @args	= $event->args;

    $nuh{lc $args[5]} = $args[5]."!".$args[2]."\@".$args[3];
}

sub on_whoisuser {
    my ($self, $event) = @_;
    my @args	= $event->args;

    &DEBUG("on_whoisuser: @args");

    $nuh{lc $args[1]} = $args[1]."!".$args[2]."\@".$args[3];
}

1;
