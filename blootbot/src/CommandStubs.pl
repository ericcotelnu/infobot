#
# User Command Extension Stubs
#

if (&IsParam("useStrict")) { use strict; }

use vars qw(@W3Search_engines $W3Search_regex);
@W3Search_engines = qw(AltaVista Dejanews Excite Gopher HotBot Infoseek
			Lycos Magellan PLweb SFgate Simple Verity Google);
$W3Search_regex = join '|', @W3Search_engines;
$babel::lang_regex = "";	# lame fix.

### PROPOSED COMMAND HOOK IMPLEMENTATION.
# addCmdHook('TEXT_HOOK', $code_ref,
#	(Forker		=> 1,
#	CheckModule	=> 1,
#	Identifier	=> 'config_label',
#	Help		=> 'help_label',
#	Cmdstats	=> 'text_label',)
#}
### EXAMPLE
# addCmdHook('d?find', (
#	CODEREF => \&debianFind(),
#	CheckModule => 1,
#	Forker => 1,		# if simple function.
#	Identifier => "debian",
#	Help => "dfind",
#	Cmdstats => "Debian Search",) );
### NOTES:
#   * viable solution?
###

sub addCmdHook {
    my ($ident, %hash) = @_;

    &DEBUG("aCH: added $ident to command hooks.");
    $cmdhooks{$ident} = \%hash;
}

# RUN IF ADDRESSED.
sub parseCmdHook {
    my @args = split(' ', $message);

    &shmFlush();

    foreach (keys %cmdhooks) {
	my $ident = $_;
	&DEBUG("cmdhooks{$ident} => ...");

	next unless ($args[0] =~ /^$ident$/i);
	shift(@args);	# just gotta do it.

	&DEBUG("pCH: MATCHED!");
	my %hash = %{ $cmdhooks{$ident} };

	### DEBUG.
	foreach (keys %hash) {
	    &DEBUG(" $ident->$_ => '$hash{$_}'.");
	}

	### IDENTIFIER.
	if (exists $hash{'Identifier'}) {
	    return $noreply unless (&hasParam($hash{'Identifier'}));
	}

	### FORKER,IDENTIFIER,CODEREF.
	if (exists $hash{'Forker'}) {
	    &Forker($hash{'Identifier'}, sub { \&{$hash{'CODEREF'}}(@args) } );
	}

	### CMDSTATS.
	if (exists $hash{'Cmdstats'}) {
	    $cmdstats{$hash{'Cmdstats'}}++;
	}

	return 1;
    }

    &DEBUG("pCH: ended.");
    return 0;
}

&addCmdHook('d?bugs', ('CODEREF' => 'debianBugs',
	'Forker' => 1, 'Identifier' => 'debianExtra',
	'Cmdstats' => 'Debian Bugs') );
&addCmdHook('dauthor', ('CODEREF' => 'Debian::searchAuthor',
	'Forker' => 1, 'Identifier' => 'debian',
	'Cmdstats' => 'Debian Author Search', 'Help' => "dauthor" ) );
&addCmdHook('(d|search)desc', ('CODEREF' => 'Debian::searchDesc',
	'Forker' => 1, 'Identifier' => 'debian',
	'Cmdstats' => 'Debian Desc Search', 'Help' => "ddesc" ) );
&addCmdHook('dincoming', ('CODEREF' => 'Debian::generateIncoming',
	'Forker' => 1, 'Identifier' => 'debian' ) );
&addCmdHook('dstats', ('CODEREF' => 'Debian::infoStats',
	'Forker' => 1, 'Identifier' => 'debian',
	'Cmdstats' => 'Debian Statistics' ) );
&addCmdHook('d?contents', ('CODEREF' => 'Debian::searchContents',
	'Forker' => 1, 'Identifier' => 'debian',
	'Cmdstats' => 'Debian Contents Search', 'Help' => "contents" ) );
&addCmdHook('d?find', ('CODEREF' => 'Debian::DebianFind',
	'Forker' => 1, 'Identifier' => 'debian',
	'Cmdstats' => 'Debian Search', 'Help' => "find" ) );


sub Modules {
    if (!defined $message) {
	&WARN("Modules: message is undefined. should never happen.");
	return;
    }

    # babel bot: Jonathan Feinberg++
    if (&IsParam("babelfish") and $message =~ m{
		^\s*
		(?:babel(?:fish)?|x|xlate|translate)
		\s+
		(to|from)		# direction of translation (through)
		\s+
		($babel::lang_regex)\w*	# which language?
		\s*
		(.+)			# The phrase to be translated
	}xoi) {

	&Forker("babelfish", sub { &babel::babelfish(lc $1, lc $2, $3); } );

	$cmdstats{'BabelFish'}++;
	return $noreply;
    }

    # cookie (random). xk++
    if ($message =~ /^(cookie|random)(\s+(.*))?$/i) {
	return $noreply unless (&hasParam("cookie"));

	my $arg = $3;

	# lets find that secret cookie.
	my $target	= $talkchannel;
	$target		= $who 		if ($msgType ne 'public');

	my $cookiemsg	= &getRandom(keys %{$lang{'cookie'}});
	my ($key,$value);
	### WILL CHEW TONS OF MEM.
	### TODO: convert this to a Forker function!
	if ($arg) {
	    my @list = &searchTable("factoids", "factoid_key", "factoid_value", $arg);
	    $key  = &getRandom(@list);
	    $val  = &getFactInfo("factoids", $key, "factoid_value");
	} else {
	    ($key,$value) = &randKey("factoids","factoid_key,factoid_value");
	}

	$cookiemsg	=~ s/##KEY/\002$key\002/;
	$cookiemsg	=~ s/##VALUE/$value/;
	$cookiemsg	=~ s/##WHO/$who/;
	$cookiemsg	=~ s/\$who/$who/;	# cheap fix.
	$cookiemsg	=~ s/(\S+)?\s*<\S+>/$1 /;
	$cookiemsg	=~ s/\s+/ /g;

	if ($cookiemsg =~ s/^ACTION //i) {
	    &action($target, $cookiemsg);
	} else {
	    &msg($target, $cookiemsg);
	}

	$cmdstats{'Random Cookie'}++;
	return $noreply;
    }

    if (&IsParam("debian")) {
	my $debiancmd	 = 'conflicts?|depends?|desc|file|info|provides?';
	$debiancmd	.= '|recommends?|suggests?|maint|maintainer';
	if ($message =~ /^($debiancmd)(\s+(.*))?$/i) {
	    my $package = lc $3;

	    if (defined $package) {
		&Forker("debian", sub { &Debian::infoPackages($1, $package); } );
	    } else {
		&help($1);
	    }

	    return $noreply;
	}
    }

    # Dict. xk++
    if ($message =~ /^dict(\s+(.*))?$/i) {
	return $noreply unless (&hasParam("dict"));

	my $query = $2;
	$query =~ s/^[\s\t]+//;
	$query =~ s/[\s\t]+$//;
	$query =~ s/[\s\t]+/ /;

	if (!defined $query) {
	    &help("dict");
	    return $noreply;
	}

	if (length $query > 30) {
	    &msg($who,"dictionary word is too long.");
	    return $noreply;
	}

	&Forker("dict", sub { &Dict::Dict($query); } );

	$cmdstats{'Dict'}++;
	return $noreply;
    }

    # Freshmeat. xk++
    if ($message =~ /^(fm|freshmeat)(\s+(.*))?$/i) {
	return $noreply unless (&hasParam("freshmeat"));

	my $query = $3;

	if (!defined $query) {
	    &help("freshmeat");
	    &msg($who, "I have \002".&countKeys("freshmeat")."\002 entries.");
	    return $noreply;
	}

	&loadMyModule($myModules{'freshmeat'});
	&Freshmeat::Freshmeat($query);

	$cmdstats{'Freshmeat'}++;
	return $noreply;
    }

    # google searching. Simon++
    if (&IsParam("wwwsearch") and $message =~ /^(?:search\s+)?($W3Search_regex)\s+for\s+['"]?(.*?)['"]?\s*\?*$/i) {
	return $noreply unless (&hasParam("wwwsearch"));

	&Forker("wwwsearch", sub { &W3Search::W3Search($1,$2,$param{'wwwsearch'}); } );

	$cmdstats{'WWWSearch'}++;
	return $noreply;
    }

    # insult server. patch thanks to michael@limit.org
    if ($message =~ /^insult(\s+(\S+))?$/) {
	return $noreply unless (&hasParam("insult"));

	my $person	= $2;
	if (!defined $person) {
	    &help("insult");
	    return $noreply;
	}

	&Forker("insult", sub { &Insult::Insult($person); } );

	return $noreply;
    }

    # Kernel. xk++
    if ($message =~ /^kernel$/i) {
	return $noreply unless (&hasParam("kernel"));

	&Forker("kernel", sub { &Kernel::Kernel(); } );

	$cmdstats{'Kernel'}++;
	return $noreply;
    }

    # LART. originally by larne/cerb.
    if ($message =~ /^lart(\s+(.*))?$/i) {
	return $noreply unless (&hasParam("lart"));
	my ($target) = &fixString($2);

	if (!defined $target) {
	    &help("lart");
	    return $noreply;
	}
	my $extra = 0;

	my $chan = $talkchannel;
	if ($msgType eq 'private') {
	    if ($target =~ /^($mask{chan})\s+(.*)$/) {
		$chan	= $1;
		$target = $2;
		$extra	= 1;
	    } else {
		&msg($who, "error: invalid format or missing arguments.");
		&help("lart");
		return $noreply;
	    }
	}

	my $line = &getRandomLineFromFile($bot_misc_dir. "/blootbot.lart");
	if (defined $line) {
	    if ($target =~ /^(me|you|itself|\Q$ident\E)$/i) {
		$line =~ s/WHO/$who/g;
	    } else {
		$line =~ s/WHO/$target/g;
	    }
	    $line .= ", courtesy of $who" if ($extra);

	    &action($chan, $line);
	} else {
	    &status("lart: error reading file?");
	}

	return $noreply;
    }

    # Search factoid extensions by 'author'. xk++
    if ($message =~ /^listauth(\s+(\S+))?$/i) {
	return $noreply unless (&hasParam("search"));

	my $query = $2;

	if (!defined $query) {
	    &help("listauth");
	    return $noreply;
	}

	&loadMyModule($myModules{'factoids'});
	&performStrictReply( &CmdListAuth($query) );
	return $noreply;
    }

    # list{keys|values}. xk++. Idea taken from #linuxwarez@EFNET
    if ($message =~ /^list(\S+)( (.*))?$/i) {
	return $noreply unless (&hasParam("search"));

	my $thiscmd	= lc($1);
	my $args	= $3;

	$thiscmd =~ s/^vals$/values/;
	return $noreply if ($thiscmd ne "keys" && $thiscmd ne "values");

	# Usage:
	if (!defined $args) {
	    &help("list". $thiscmd);
	    return $noreply;
	}

	if (length $args == 1) {
	    &msg($who,"search string is too short.");
	    return $noreply;
	}

	&Forker("search", sub { &Search::Search($thiscmd, $args); } );

	$cmdstats{'Factoid Search'}++;
	return $noreply;
    }

    # Nickometer. Adam Spiers++
    if ($message =~ /^(?:lame|nick)ometer(?: for)? (\S+)/i) {
	return $noreply unless (&hasParam("nickometer"));

	my $term = (lc $1 eq 'me') ? $who : $1;
	$term =~ s/\?+\s*//;

	&loadMyModule($myModules{'nickometer'});
	my $percentage = &nickometer($term);

	if ($percentage =~ /NaN/) {
	    $percentage = "off the scale";
	} else {
	    $percentage = sprintf("%0.4f", $percentage);
	    $percentage =~ s/\.?0+$//;
	    $percentage .= '%';
	}

	if ($msgType eq 'public') {
	    &say("'$term' is $percentage lame, $who");
	} else {
	    &msg($who, "the 'lame nick-o-meter' reading for $term is $percentage, $who");
	}

	return $noreply;
    }

    # Quotes. mu++
    if ($message =~ /^quote(\s+(\S+))?$/i) {
	return $noreply unless (&hasParam("quote"));

	my $query = $2;

	if ($query eq "") {
	    &help("quote");
	    return $noreply;
	}

	&Forker("quote", sub { &Quote::Quote($query); } );

	$cmdstats{'Quote'}++;
	return $noreply;
    }

    # rootWarn. xk++
    if ($message =~ /^rootWarn$/i) {
	return $noreply unless (&hasParam("rootWarn"));

	&loadMyModule($myModules{'rootwarn'});
	&performStrictReply( &CmdrootWarn() );
	return $noreply;
    }

    # seen.
    if ($message =~ /^seen(\s+(\S+))?$/) {
	return $noreply unless (&hasParam("seen"));

	my $person = $2;
	if (!defined $person) {
	    &help("seen");

	    my $i = &countKeys("seen");
	    &msg($who,"there ". &fixPlural("is",$i) ." \002$i\002 ".
		"seen ". &fixPlural("entry",$i) ." that I know of.");

	    return $noreply;
	}

	my @seen;
	$person =~ s/\?*$//;

	&seenFlush();	# very evil hack. oh well, better safe than sorry.

	### TODO: Support &dbGetRowInfo(); like in &FactInfo();
	my $select = "nick,time,channel,host,message";
	if ($person eq "random") {
	    @seen = &randKey("seen", $select);
	} else {
	    @seen = &dbGet("seen", "nick", $person, $select);
	}

	if (scalar @seen < 2) {
	    foreach (@seen) {
		&DEBUG("seen: _ => '$_'.");
	    }
	    &performReply("i haven't seen '$person'");
	    return $noreply;
	}

	# valid seen.
	my $reply;
	### TODO: multi channel support. may require &IsNick() to return
	###	all channels or something.
	my @chans = &GetNickInChans($seen[0]);
	if (scalar @chans) {
	    $reply = "$seen[0] is currently on";

	    foreach (@chans) {
		$reply .= " ".$_;
		next unless (exists $userstats{lc $seen[0]}{'Join'});
		$reply .= " (".&Time2String(time() - $userstats{lc $seen[0]}{'Join'}).")";
	    }

	    if (&IsParam("seenStats")) {
		my $i;
		$i = $userstats{lc $seen[0]}{'Count'};
		$reply .= ".  Has said a total of \002$i\002 messages" if (defined $i);
		$i = $userstats{lc $seen[0]}{'Time'};
		$reply .= ".  Is idling for ".&Time2String(time() - $i) if (defined $i);
	    }
	} else {
	    my $howlong = &Time2String(time() - $seen[1]);
	    $reply = "$seen[0] <$seen[3]> was last seen on IRC ".
			"in channel $seen[2], $howlong ago, ".
			"saying\002:\002 '$seen[4]'.";
	}

	&performStrictReply($reply);
	return $noreply;
    }

    # slashdot headlines: from Chris Tessone.
    if ($message =~ /^slashdot$/i) {
	return $noreply unless (&hasParam("slashdot"));

	&Forker("slashdot", sub { &Slashdot::Slashdot() });

	$cmdstats{'Slashdot'}++;
	return $noreply;
    }

    # Topic management. xk++
    # may want to add a flag(??) for topic in the near future. -xk
    if ($message =~ /^topic(\s+(.*))?$/i) {
	return $noreply unless (&hasParam("topic"));

	my $chan	= $talkchannel;
	my @args	= split(/ /, $2);

	if (!scalar @args) {
	    &msg($who,"Try 'help topic'");
	    return $noreply;
	}

	$chan		= lc(shift @args) if ($msgType eq 'private');
	my $thiscmd	= shift @args;

	# topic over public:
	if ($msgType eq 'public' && $thiscmd =~ /^#/) {
	    &msg($who, "error: channel argument is not required.");
	    &msg($who, "\002Usage\002: topic <CMD>");
	    return $noreply;
	}

	# topic over private:
	if ($msgType eq 'private' && $chan !~ /^#/) {
	    &msg($who, "error: channel argument is required.");
	    &msg($who, "\002Usage\002: topic #channel <CMD>");
	    return $noreply;
	}

	if (&validChan($chan) == 0) {
	    &msg($who,"error: invalid channel \002$chan\002");
	    return $noreply;
	}

	# for semi-outsiders.
	if (!&IsNickInChan($who,$chan)) {
	    &msg($who, "Failed. You ($who) are not in $chan, hey?");
	    return $noreply;
	}

	# now lets do it.
	&loadMyModule($myModules{'topic'});
	&Topic($chan, $thiscmd, join(' ', @args));
	$cmdstats{'Topic'}++;
	return $noreply;
    }

    # Countdown.
    if ($message =~ /^countdown(\s+(\S+))?$/i) {
	return $noreply unless (&hasParam("countdown"));

	my $query = $2;

	&loadMyModule($myModules{'countdown'});
	&Countdown($query);

	$cmdstats{'Countdown'}++;

	return $noreply;
    }

    # User Information Services. requested by Flugh.
    if ($message =~ /^u(ser)?info(\s+(.*))?$/i) {
	return $noreply unless (&hasParam("userinfo"));
	&loadMyModule($myModules{'userinfo'});

	my $arg = $3;
	if (!defined $arg or $arg eq "") {
	    &help("userinfo");
	    return $noreply;
	}

	if ($arg =~ /^set(\s+(.*))?$/i) {
	    $arg = $2;
	    if (!defined $arg) {
		&help("userinfo set");
		return $noreply;
	    }

	    &UserInfoSet(split /\s+/, $arg, 2);
	} elsif ($arg =~ /^unset(\s+(.*))?$/i) {
	    $arg = $2;
	    if (!defined $arg) {
		&help("userinfo unset");
		return $noreply;
	    }

	    &UserInfoSet($arg, "");
	} else {
	    &UserInfoGet($arg);
	}

	$cmdstats{'UIS'}++;
	return $noreply;
    }

    # Uptime. xk++
    if ($message =~ /^uptime$/i) {
	return $noreply unless (&hasParam("uptime"));

	my $count = 1;
 	&msg($who, "- Uptime for $ident -");
	&msg($who, "Now: ". &Time2String(&uptimeNow()) ." running $bot_version");
	foreach (&uptimeGetInfo()) {
	    /^(\d+)\.\d+ (.*)/;
	    my $time = &Time2String($1);
	    my $info = $2;

	    &msg($who, "$count: $time $2");
	    $count++;
	}

	$cmdstats{'Uptime'}++;
	return $noreply;
    }

    # wingate.
    if ($message =~ /^wingate$/i) {
	return $noreply unless (&hasParam("wingate"));

	my $reply = "Wingate statistics: scanned \002"
			.scalar(keys %wingate)."\002 hosts";
	my $queue = scalar(keys %wingateToDo);
	if ($queue) {
	    $reply .= ".  I have \002$queue\002 hosts in the queue";
	    $reply .= ".  Started the scan ".&Time2String(time() - $wingaterun)." ago";
	}

	&performStrictReply("$reply.");

	return $noreply;
    }

    # convert.
    if ($message =~ /^convert(\s+(.*))?$/i) {
	return $noreply unless (&hasParam("units"));

	my $str = $2;
	if (!defined $str) {
	    &help("convert");
	    return $noreply;
	}

	my ($from,$to);
	($from,$to) = ($1,$2) if ($str =~ /^(.*) to (.*)$/);
	($from,$to) = ($2,$1) if ($str =~ /^(.*) from (.*)$/);
	if (!defined $from or !defined $to or $to eq "" or $from eq "") {
	    &msg($who, "Invalid format!");
	    &help("convert");
	    return $noreply;
	}

	&Forker("units", sub { &Units::convertUnits($from, $to); } );

	return $noreply;
    }

    # do nothing and let the other routines have a go
    return '';
}

1;
