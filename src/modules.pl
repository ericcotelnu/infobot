#
#  modules.pl: pseudo-Module handler
#      Author: dms
#     Version: v0.2 (20000629)
#     Created: 20000624
#

if (&IsParam("useStrict")) { use strict; }

###
### REQUIRED MODULES.
###

eval "use IO::Socket";
if ($@) {
    &ERROR("no IO::Socket?");
    exit 1;
}
&showProc(" (IO::Socket)");

### MODULES.
%myModules = (
	"countdown"	=> "Countdown.pl",
	"allowDNS"	=> "DNS.pl",
	"debian"	=> "Debian.pl",
	"debianExtra"	=> "DebianExtra.pl",
	"dict"		=> "Dict.pl",
	"dumpvars"	=> "DumpVars.pl",
	"factoids"	=> "Factoids.pl",
	"freshmeat"	=> "Freshmeat.pl",
	"kernel"	=> "Kernel.pl",
	"ircdcc"	=> "UserDCC.pl",
	"perlMath"	=> "Math.pl",
	"quote"		=> "Quote.pl",
	"rootwarn"	=> "RootWarn.pl",
	"search"	=> "Search.pl",
	"slashdot"	=> "Slashdot3.pl",
	"topic"		=> "Topic.pl",
	"units"		=> "Units.pl",
	"uptime"	=> "Uptime.pl",
	"userinfo"	=> "UserInfo.pl",
	"wwwsearch"	=> "W3Search.pl",
	"whatis"	=> "WhatIs.pl",
	"wingate"	=> "Wingate.pl",
	"insult"	=> "insult.pl",
	"nickometer"	=> "nickometer.pl",
);
@myModulesLoadNow	= ('topic', 'uptime',);
@myModulesReloadNot	= ('IRC/Irc.pl','IRC/Schedulers.pl');

sub loadCoreModules {
    if (!opendir(DIR, $bot_src_dir)) {
	&ERROR("can't open source directory $bot_src_dir: $!");
	exit 1;
    }

    &status("Loading CORE modules...");

    while (defined(my $file = readdir DIR)) {
	next unless $file =~ /\.pl$/;
	next unless $file =~ /^[A-Z]/;
	my $mod = "$bot_src_dir/$file";
	### TODO: use eval and exit gracefully?
	require $mod;
	$moduleAge{$mod} = (stat $mod)[9];
	&showProc(" ($file)") if (&IsParam("DEBUG"));
    }
    closedir DIR;
}

sub loadDBModules {
    &status("Loading DB modules...");

    if ($param{'DBType'} =~ /^mysql$/i) {
	eval "use DBI";
	if ($@) {
	    &ERROR("libdbd-mysql-perl is not installed!");
	    exit 1;
	}
	&showProc(" (DBI // mysql)");

	&status("  using MySQL support.");
	require "$bot_src_dir/db_mysql.pl";

    } elsif ($param{'DBType'} =~ /^pgsql$/i) {
	eval "use Pg";
	if ($@) {
	    &ERROR("libpgperl is not installed!");
	    exit 1;
	}
	&showProc(" (Pg // postgreSQLl)");

	&status("  using PostgreSQL support.");
	require "$bot_src_dir/db_pgsql.pl";
    } elsif ($param{'DBType'} =~ /^dbm$/i) {

	&status("  using Berkeley DBM 1.85/2.0 support.");
	require "$bot_src_dir/db_dbm.pl";
    } else {

	&status("DB support DISABLED.");
	return;
    }
}

sub loadFactoidsModules {
    &status("Loading Factoids modules...");

    if (!&IsParam("factoids")) {
	&status("Factoid support DISABLED.");
	return;
    }

    if (!opendir(DIR, "$bot_src_dir/Factoids")) {
	&ERROR("can't open source directory Factoids: $!");
	exit 1;
    }

    while (defined(my $file = readdir DIR)) {
	next unless $file =~ /\.pl$/;
	next unless $file =~ /^[A-Z]/;
	my $mod = "$bot_src_dir/Factoids/$file";
	### TODO: use eval and exit gracefully?
	require $mod;
	$moduleAge{$mod} = (stat $mod)[9];
	&showProc(" ($file)") if (&IsParam("DEBUG"));
    }
    closedir DIR;
}

sub loadIRCModules {
    &status("Loading IRC modules...");
    if (&whatInterface() =~ /IRC/) {
	eval "use Net::IRC";
	if ($@) {
	    &ERROR("libnet-irc-perl is not installed!");
	    exit 1;
	}
	&showProc(" (Net::IRC)");
    } else {
	&status("IRC support DISABLED.");
	return;
    }

    if (!opendir(DIR, "$bot_src_dir/IRC")) {
	&ERROR("can't open source directory Factoids: $!");
	exit 1;
    }

    while (defined(my $file = readdir DIR)) {
	next unless $file =~ /\.pl$/;
	next unless $file =~ /^[A-Z]/;
	my $mod = "$bot_src_dir/IRC/$file";
	### TODO: use eval and exit gracefully?
	require $mod;
	$moduleAge{$mod} = (stat $mod)[9];
	&showProc(" ($file)") if (&IsParam("DEBUG"));
    }
    closedir DIR;
}

sub loadMyModulesNow {
    my $loaded = 0;
    my $total  = 0;

    &status("Loading MyModules...");
    foreach (@myModulesLoadNow) {
	$total++;

	if (!exists $param{$_}) {
	    &DEBUG("myModule: $myModules{$_} not loaded.");
	    next;
	}
	&loadMyModule($myModules{$_});
	$loaded++;
    }

    &status("Modules: Loaded/Total [$loaded/$total]");
}

### rename to moduleReloadAll?
sub reloadAllModules {
    &status("Modules: reloading all.");
    foreach (map { substr($_,2) } keys %moduleAge) {
        &reloadModule($_);
    }
    &status("Modules: reloading done.");
}

### rename to modulesReload?
sub reloadModule {
    my ($mod)	= @_;
    my $file	= (grep /\/$mod/, keys %INC)[0];

    if (!defined $file) {
	&DEBUG("rM: mod '$mod' was not found in \%INC.");
	return;
    }

    if (! -f $file) {
	&DEBUG("rM: file '$file' does not exist?");
	return;
    }

    my $age = (stat $file)[9];
    return if ($age == $moduleAge{$file});

    if (grep /$mod/, @myModulesReloadNot) {
	&DEBUG("rM: SHOULD NOT RELOAD $mod!!!");
	return;
    }

    &status("Module: Loading $mod...");
    delete $INC{$file};
    eval "require \"$file\"";	# require or use?
    if (@$) {
	&DEBUG("rM: failure: @$");
    } else {
	my $basename = $file;
	$basename =~ s/^.*\///;
	&status("Modules: reloaded $basename");
	$moduleAge{$file} = $age;
    }
}

###
### OPTIONAL MODULES.
###

local %perlModulesLoaded  = ();
local %perlModulesMissing = ();

sub loadPerlModule {
    return 0 if (exists $perlModulesMissing{$_[0]});
    return 1 if (exists $perlModulesLoaded{$_[0]});

    &DEBUG("lPM: _ => '$_[0]'.");
    &reloadModule($_[0]);

    eval "use $_[0]";
    if ($@) {
	&WARN("Module: $_[0] is not installed!");
	$perlModulesMissing{$_[0]} = 1;
	return 0;
    } else {
	$perlModulesLoaded{$_[0]} = 1;
	&status("Module: Loaded $_[0] ...");
	&showProc(" ($_[0])");
	return 1;
    }
}

sub loadMyModule {
    my ($tmp) = @_;
    if (!defined $tmp) {
	&WARN("loadMyModule: module is NULL.");
	return 0; 
    }

    my ($modulebase, $modulefile);
    if (exists $myModules{$tmp}) {
	($modulename, $modulebase) = ($tmp, $myModules{$tmp});
    } else {
	$modulebase = $tmp;
	if ($tmp = grep /^$modulebase$/, keys %myModules) {
	    &DEBUG("lMM: lame hack, file => name => $tmp.");
	    $modulename = $tmp;
	}
    }
    my $modulefile = "$bot_src_dir/Modules/$modulebase";

    return 1 if (grep /$modulefile/, keys %INC);

    if (! -f $modulefile) {
	&ERROR("lMM: module ($modulebase) does not exist.");
	if ($$ == $bot_pid) {	# parent.
	    &shutdown() if (defined $shm and defined $dbh);
	} else {			# child.
	    &delForked($modulename);
	}

	exit 1;
    }

    eval "require \"$modulefile\"";
    if ($@) {
	&ERROR("cannot load my module: $modulebase");
	if ($bot_pid == $$) {	# parent.
	    &shutdown() if (defined $shm and defined $dbh);
	} else {			# child.
	    &delForked($modulename);
	}

	exit 1;
    } else {
	$moduleAge{$modulefile} = (stat $modulefile)[9];

	&status("myModule: Loaded $modulebase ...");
	&showProc(" ($modulebase)");
	return 1;
    }
}

### this chews 3megs on potato, 300 kB on slink.
$no_syscall = 0;
###eval "require 'sys/syscall.ph'";
#if ($@) {
#    &WARN("sys/syscall.ph has not been installed//generated. gettimeofday
#will use time() instead");
    $no_syscall = 1;
#}
#&showProc(" (syscall)");

1;
