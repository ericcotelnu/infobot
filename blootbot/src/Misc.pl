#
#   Misc.pl: Miscellaneous stuff.
#    Author: xk <xk@leguin.openprojects.net>
#   Version: 20000124
#      NOTE: Based on code by Kevin Lenzo & Patrick Cole  (c) 1997
#

if (&IsParam("useStrict")) { use strict; }

sub help {
    my $topic = $_[0];
    my $file  = $infobot_misc_dir."/infobot.help";
    my %help  = ();

    if (!open(FILE, $file)) {
	&ERROR("FAILED loadHelp ($file): $!");
	return;
    }

    while (defined(my $help = <FILE>)) {
	$help =~ s/^[\# ].*//;
	chomp $help;
	next unless $help;
	my ($key, $val) = split(/:/, $help, 2);

	$val =~ s/^\s+//;
	$val =~ s/^D:/\002   Desc\002:/;
	$val =~ s/^E:/\002Example\002:/;
	$val =~ s/^N:/\002   NOTE\002:/;
	$val =~ s/^U:/\002  Usage\002:/;
	$val =~ s/##/$key/;
	$val =~ s/__/\037/g;
	$val =~ s/==/        /;

	$help{$key}  = ""		 if (!exists $help{$key});
	$help{$key} .= $val."\n";
    }
    close FILE;

    if (!defined $topic) {
	&msg($who, $help{'main'});

	my $i = 0;
	my @array;
	my $count = scalar(keys %help);
	my $reply;
	foreach (sort keys %help) {
	    push(@array,$_);
	    $reply = scalar(@array) ." topics: ".
			join("\002,\002 ", @array);
	    $i++;

	    if (length $reply > 400 or $count == $i) {
		&msg($who,$reply);
		undef @array;
	    }
	}

	return '';
    }

    $topic = &fixString(lc $topic);

    if (exists $help{$topic}) {
	foreach (split /\n/, $help{$topic}) {
	    &msg($who,$_);
	}
    } else {
	&msg($who, "no help on $topic.  Use 'help' without arguments.");
    }

    return '';
}

sub gettimeofday {
    if ($no_syscall) {		# fallback.
	return time();
    } else {			# the real thing.
	my $time = pack("LL", 0);

	syscall(&SYS_gettimeofday, $time, 0);
	my @time = unpack("LL",$time);

	return sprintf("%d.%d", @time);
    }
}

###
### FORM Functions.
###

###
# Usage; &formListReply($rand, $prefix, @list);
sub formListReply {
    my($rand, $prefix, @list) = @_;
    my $total	= scalar @list;
    my $maxshow = $param{'maxListReplyCount'}  || 10;
    my $maxlen	= $param{'maxListReplyLength'} || 400;
    my $reply;

    # no results.
    return $prefix ."returned no results." unless ($total);

    # random.
    if ($rand) {
	my @rand;
	foreach (&makeRandom($total)) {
	    push(@rand, $list[$_]);
	    last if (scalar @rand == $maxshow);
	}
	@list = @rand;
    } elsif ($total > $maxshow) {
	&status("formListReply: truncating list.");

	@list = @list[0..$maxshow-1];
    }

    # form the reply.
    while () {
	$reply  = $prefix ."(\002". scalar(@list). "\002 shown";
	$reply .= "; \002$total\002 total" if ($total != scalar @list);
	$reply .= "): ". join(" \002;;\002 ",@list) .".";

	last if (length($reply) < $maxlen and scalar(@list) <= $maxshow);
	last if (scalar(@list) == 1);

	pop @list;
    }

    return $reply;
}

### Intelligence joining of arrays.
# Usage: &IJoin(@array);
sub IJoin {
    if (!scalar @_) {
	return "NULL";
    } elsif (scalar @_ == 1) {
	return $_[0];
    } else {
	return join(', ',@{_}[0..$#_-1]) . " and $_[$#_]";
    }
}

#####
# Usage: &Time2String(seconds);
sub Time2String {
    my $time = shift;
    my $retval;

    return("0s")	if ($time !~ /\d+/ or $time <= 0);

    my $s = int($time) % 60;
    my $m = int($time / 60) % 60;
    my $h = int($time / 3600) % 24;
    my $d = int($time / 86400);

    $retval .= sprintf(" \002%d\002d", $d) if ($d != 0);
    $retval .= sprintf(" \002%d\002h", $h) if ($h != 0);
    $retval .= sprintf(" \002%d\002m", $m) if ($m != 0);
    $retval .= sprintf(" \002%d\002s", $s) if ($s != 0);

    return substr($retval, 1);
}

###
### FIX Functions.
###

# Usage: &fixFileList(@files);
sub fixFileList {
    my @files = @_;
    my %files;

    # generate a hash list.
    foreach (@files) {
	if (/^(.*\/)(.*?)$/) {
	    $files{$1}{$2} = 1;
	}
    }
    @files = ();	# reuse the array.

    # sort the hash list appropriately.
    foreach (sort keys %files) {
	my $file = $_;
	my @keys = sort keys %{$files{$file}};
	my $i	 = scalar(@keys);

	if ($i > 1) {
	    $file .= "\002{\002". join("\002|\002", @keys) ."\002}\002";
	} else {
	    $file .= $keys[0];
	}

	push(@files,$file);
    }

    return @files;
}

# Usage: &fixString($str);
sub fixString {
    my ($str, $level) = @_;
    if (!defined $str) {
	&WARN("fixString: str == NULL.");
	return '';
    }

    for ($str) {
	s/^\s+//;		# remove start whitespaces.
	s/\s+$//;		# remove end whitespaces.
	s/\s+/ /g;		# remove excessive whitespaces.

	next unless (defined $level);
	s/[\cA-\c_]//ig		# remove control characters.
    }

    return $str;
}

# Usage: &fixPlural($str,$int);
sub fixPlural {
    my ($str,$int) = @_;

    if ($str eq "has") {
	$str = "have"	if ($int > 1);
    } elsif ($str eq "is") {
	$str = "are"	if ($int > 1);
    } elsif ($str eq "was") {
	$str = "were"	if ($int > 1);
    } elsif ($str eq "this") {
	$str = "these"	if ($int > 1);
    } elsif ($str =~ /y$/) {
	if ($int > 1) {
	    if ($str =~ /ey$/) {
		$str .= "s";	# eg: "money" => "moneys".
	    } else {
		$str =~ s/y$/ies/;
	    }
	}
    } else {
	$str .= "s"	if ($int != 1);
    }

    return $str;
}



##########
### get commands.
###

sub getRandomLineFromFile {
    my($file) = @_;

    if (! -f $file) {
	&WARN("gRLfF: file '$file' does not exist.");
	return;
    }

    if (open(IN,$file)) {
	my @lines = <IN>;

	if (!scalar @lines) {
	    &ERROR("GRLF: nothing loaded?");
	    return;
	}

	while (my $line = &getRandom(@lines)) {
	    chop $line;

	    next if ($line =~ /^\#/);
	    next if ($line =~ /^\s*$/);

	    return $line;
	}
    } else {
	&WARN("gRLfF: could not open file '$file'.");
	return;
    }
}

sub getLineFromFile {
    my($file,$lineno) = @_;

    if (! -f $file) {
	&ERROR("getLineFromFile: file '$file' does not exist.");
	return 0;
    }

    if (open(IN,$file)) {
	my @lines = <IN>;
	close IN;

	if ($lineno > scalar @lines) {
	    &ERROR("getLineFromFile: lineno exceeds line count from file.");
	    return 0;
	}

	my $line = $lines[$lineno-1];
	chop $line;
	return $line;
    } else {
	&ERROR("getLineFromFile: could not open file '$file'.");
	return 0;
    }
}

# Usage: &getRandom(@array);
sub getRandom {
    my @array = @_;

    srand();
    return $array[int(rand(scalar @array))];
}

# Usage: &getRandomInt("30-60");
sub getRandomInt {
    my $str = $_[0];

    srand();

    if ($str =~ /^(\d+)$/) {
	my $i = $1;
	my $fuzzy = int(rand 5);
	if ($i < 10) {
	    return $i*60;
	}
	if (rand > 0.5) {
	    return ($i - $fuzzy)*60;
	} else {
	    return ($i + $fuzzy)*60;
	}
    } elsif ($str =~ /^(\d+)-(\d+)$/) {
	return ($2 - $1)*int(rand $1)*60;
    } else {
	return $str;	# hope we're safe.
    }

    &ERROR("getRandomInt: invalid arg '$str'.");
    return 1800;
}

##########
### Is commands.
###

sub iseq {
    my ($left,$right) = @_;
    return 0 unless defined $right;
    return 0 unless defined $left;
    return 1 if ($left =~ /^\Q$right$/i);
}

sub isne {
    my $retval = &iseq(@_);
    return 1 unless ($retval);
    return 0;
}

# Usage: &IsHostMatch($nuh);
sub IsHostMatch {
    my ($thisnuh) = @_;
    my (%this,%local);

    if ($nuh =~ /^(\S+)!(\S+)@(\S+)/) {
	$local{'nick'} = lc $1;
	$local{'user'} = lc $2;
	$local{'host'} = &makeHostMask(lc $3);
    }

    if ($thisnuh =~ /^(\S+)!(\S+)@(\S+)/) {
	$this{'nick'} = lc $1;
	$this{'user'} = lc $2;
	$this{'host'} = &makeHostMask(lc $3);
    } else {
	&WARN("IHM: thisnuh is invalid '$thisnuh'.");
	return 1 if ($thisnuh eq "");
	return 0;
    }

    # auth if 1) user and host match 2) user and nick match.
    # this may change in the future.

    if ($this{'user'} =~ /^\Q$local{'user'}$/i) {
	return 2 if ($this{'host'} eq $local{'host'});
	return 1 if ($this{'nick'} eq $local{'nick'});
    }
    return 0;
}

####
# Usage: &isStale($file, $age);
sub isStale {
    my ($file, $age) = @_;

    return 1 unless ( -f $file);
    return 1 if (time() - (stat($file))[8] > $age*60*60*24);
    my $delta = time() - (stat($file))[8];
    my $hage  = $age*60*60*24;
    &DEBUG("isStale: not stale! $delta < $hage ($age) ?");
    return 0;
}

##########
### make commands.
###

# Usage: &makeHostMask($host);
sub makeHostMask {
    my ($host) = @_;

    if ($host =~ /^$mask{ip}$/) {
	return "$1.$2.$3.*";
    }

    my @array = split(/\./, $host);
    return $host if (scalar @array <= 3);
    return "*.".join('.',@{array}[1..$#array]);
}

# Usage: &makeRandom(int);
sub makeRandom {
    my ($max) = @_;
    my @retval;
    my %done;

    if ($max =~ /^\D+$/) {
	&ERROR("makeRandom: arg ($max) is not integer.");
	return 0;
    }

    if ($max < 1) {
	&ERROR("makeRandom: arg ($max) is not positive.");
	return 0;
    }

    srand();
    while (scalar keys %done < $max) {
	my $rand = int(rand $max);
	next if (exists $done{$rand});

	push(@retval,$rand);
	$done{$rand} = 1;
    }

    return @retval;
}

sub checkMsgType {
    my ($reply) = @_;
    return unless (&IsParam("minLengthBeforePrivate"));
    return if ($force_public_reply);

    if (length $reply > $param{'minLengthBeforePrivate'}) {
	&status("Reply: len reply > minLBP ($param{'minLengthBeforePrivate'}); msgType now private.");
	$msgType = 'private';
    }
}

###
### Valid.
###

# Usage: &validExec($string);
sub validExec {
    my ($str) = @_;

    if ($str =~ /[\'\"\|]/) {	# invalid.
	return 0;
    } else {			# valid.
	return 1;
    }
}

# Usage: &validFactoid($lhs,$rhs);
sub validFactoid {
    my ($lhs,$rhs) = @_;
    my $valid = 0;

    for (lc $lhs) {
	# allow the following only if they have been made on purpose.
	if ($rhs ne "" and $rhs !~ /^</) {
	    / \Q$ident$/i and last;	# someone said i'm something.
	    /^i('m)? / and last;
	    /^(it|that|there|what)('s)?(\s+|$)/ and last;
	    /^you('re)?(\s+|$)/ and last;

	    /^(where|who|why|when|how)(\s+|$)/ and last;
	    /^(this|that|these|those|they)(\s+|$)/ and last;
	    /^(every(one|body)|we) / and last;

	    /^say / and last;
	}

	# uncaught commands.
	/^add topic / and last;		# topic management.
	/( add$| add |^add )/ and last;	# borked teach statement.
	/^learn / and last;		# teach. damn morons.
	/^tell (\S+) about / and last;	# tell.
	/\=\~/ and last;		# substituition.
	/^\S+ to \S+ \S+/ and last;	# babelfish.

	# symbols.
	/(\"\*)/ and last;
	/, / and last;
	/^\'/ and last;

	# delimiters.
	/\=\>/ and last;		# '=>'.
	/\;\;/ and last;		# ';;'.
	/\|\|/ and last;		# '||'.

	/^\Q$ident\E[\'\,\: ]/ and last;# dupe addressed.
	/^[\-\, ]/ and last;
	/\\$/ and last;			# forgot shift for '?'.
	/^all / and last;
	/^also / and last;
	/ also$/ and last;
	/ and$/ and last;
	/^because / and last;
	/^gives / and last;
	/^h(is|er) / and last;
	/^if / and last;
	/ is,/ and last;
	/ it$/ and last;
	/ says$/ and last;
	/^should / and last;
	/^so / and last;
	/^supposedly/ and last;
	/^to / and last;
	/^was / and last;
	/ which$/ and last;

	# nasty bug I introduced _somehow_, probably by fixMySQLBug().
	/\\\%/ and last;
	/\\\_/ and last;

	# weird/special stuff. also old (stock) infobot bugs.
	$rhs =~ /( \Q$ident\E's|\Q$ident\E's )/i and last; # ownership.

	# duplication.
	$rhs =~ /^\Q$lhs /i and last;
	last if ($rhs =~ /^is /i and / is$/);

	$valid++;
    }

    return $valid;
}

# Usage: &hasProfanity($string);
sub hasProfanity {
    my ($string) = @_;
    my $profanity = 1;

    for (lc $string) {
	/fuck/ and last;
	/dick|dildo/ and last;
	/shit|turd|crap/ and last;
	/pussy|[ck]unt/ and last;
	/wh[0o]re|bitch|slut/ and last;

	$profanity = 0;
    }

    return $profanity;
}

sub hasParam {
    my ($param) = @_;

    if (&IsParam($param)) {
	return 1;
    } else {
	&msg($who, "unfortunately, \002$param\002 is disabled in my configuration") unless ($addrchar);
	return 0;
    }
}

sub Forker {
    my ($label, $code) = @_;
    my $pid;

    &shmFlush();
    &status("double fork detected; not forking.") if ($$ != $infobot_pid);

    if (&IsParam("forking") and $$ == $infobot_pid) {
	return 'NOREPLY' unless (&addForked($label));
	$SIG{CHLD} = 'IGNORE';
	$pid = eval { fork() };  # catch non-forking OSes and other errors
	return 'NOREPLY' if $pid;   # parent does nothing
	&status("fork starting for '$label', PID == $$.");
    }

    if (!&loadMyModule($myModules{$label})) {
	&DEBUG("Forker: failed?");
	return;
    }

    if (defined $code) {
	$code->();			# weird, hey?
    } else {
	&WARN("Forker: code not defined!");
    }

    if (defined $pid) {		# child.
	&delForked($label);
	&status("fork finished for '$label'.");
	exit 0;
    }
}

sub checkPing {
    &DEBUG("checkPing() called.");
    $conn->schedule(60, \&checkPing, "this is a test");
    $conn->sl("PING $server :".time());
}

sub closePID {
    return 1 unless (exists $file{PID});
    return 1 unless ( -f $file{PID});
    return 1 if (unlink $file{PID});
    return 0 if ( -f $file{PID});
}
1;
