#
# CLI/Support.pl: Stubs for functions that are from IRC/*
#         Author: Tim Riker <Tim@Rikers.org>
#        Version: v0.1 (20021028)
#        Created: 20021028
#

sub cliloop {
    &status("Using CLI...");
    &status("Now type what you want.");

    $nuh = "local!local\@local";
    $uh  = "local\@local";
    $who = "local";
    $orig{who} = "local";
    $ident = $param{'ircNick'};
    $chan = $talkchannel = "_local";
    $addressed = 1;
    $msgType = 'public';

    # install libterm-readline-gnu-perl to get history support
    use Term::ReadLine;
    $term = new Term::ReadLine 'blootbot';
    $prompt = "$who> ";
    #$OUT = $term->OUT || STDOUT;
    while ( defined ($_ = $term->readline($prompt)) ) {
	$orig{message} = $_;
	$message = $_;
	chomp $message;
	last if ($message =~ m/^quit$/);
	$_ = &process() if $message;
    }
    &doExit();
}

sub msg {
    my ($nick, $msg) = @_;
    if (!defined $nick) {
	&ERROR("msg: nick == NULL.");
	return;
    }

    if (!defined $msg) {
	$msg ||= "NULL";
	&WARN("msg: msg == $msg.");
	return;
    }

    &status(">$nick< $msg");

    print("$nick: $msg\n");
}

# Usage: &action(nick || chan, txt);
sub action {
    my ($target, $txt) = @_;
    if (!defined $txt) {
	&WARN("action: txt == NULL.");
	return;
    }

    if (length $txt > 480) {
	&status("action: txt too long; truncating.");
	chop($txt) while (length $txt > 480);
    }

    &status("* $ident/$target $txt");
}

sub IsNickInChan {
    my ($nick,$chan) = @_;
    return 1;
}

sub performStrictReply {
    &msg($who, @_);
}

sub performReply {
    &msg($who, @_);
}

sub performAddressedReply {
    return unless ($addressed);
    &msg($who, @_);
}

sub pSReply {
    &msg($who, @_);
}

1;
