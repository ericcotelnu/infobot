#
#   Debian.pl: Frontend to debian contents and packages files
#      Author: dms
#     Version: v0.7b (20000527)
#     Created: 20000106
#

package Debian;

use strict;

# format: "alias=real".
my $defaultdist	= "woody";
my %dists	= (
	"unstable"	=> "woody",
	"stable"	=> "potato",
	"incoming"	=> "incoming",
);

my %urlcontents = (
	"debian/Contents-##DIST-i386.gz" =>
		"ftp://ftp.us.debian.org".
		"/debian/dists/##DIST/Contents-i386.gz",#all but woody?

	"debian/Contents-##DIST-i386-non-US.gz" =>	# OK, no hacks
		"ftp://non-us.debian.org".
		"/debian-non-US/dists/##DIST/non-US/Contents-i386.gz",
);

my %urlpackages = (
	"debian/Packages-##DIST-main-i386.gz" =>	# OK
		"ftp://ftp.us.debian.org".
		"/debian/dists/##DIST/main/binary-i386/Packages.gz",
	"debian/Packages-##DIST-contrib-i386.gz" =>	# OK
		"ftp://ftp.us.debian.org".
		"/debian/dists/##DIST/contrib/binary-i386/Packages.gz",
	"debian/Packages-##DIST-non-free-i386.gz" =>	# OK
		"ftp://ftp.us.debian.org".
		"/debian/dists/##DIST/non-free/binary-i386/Packages.gz",
	"debian/Packages-##DIST-non-US-i386.gz" =>	# SLINK ONLY
		"ftp://non-us.debian.org".
		"/debian-non-US/dists/##DIST/non-US/binary-i386/Packages.gz",
);

#####################
### COMMON FUNCTION....
#######################

####
# Usage: &DebianDownload(%hash);
sub DebianDownload {
    my ($dist, %urls)	= @_;
    my $refresh = $main::param{'debianRefreshInterval'} * 60 * 60 * 24;
    my $bad	= 0;
    my $good	= 0;

    &main::status("Debian: Downloading files for '$dist'.");

    if (! -d "debian/") {
	&main::status("Debian: creating debian dir.");
	mkdir("debian/",0755);
    }

    %urls = &fixNonUS($dist, %urls);

    # fe dists.
    # Download the files.
    my $file;
    foreach $file (keys %urls) {
	my $url = $urls{$file};
	$url  =~ s/##DIST/$dist/g;
	$file =~ s/##DIST/$dist/g;
	my $update = 0;

	if ( -f $file) {
	    my $last_refresh = (stat($file))[9];
	    $update++ if (time() - $last_refresh > $refresh);
	} else {
	    &main::DEBUG("Debian: local '$file' does not exist.");
	    $update++;
	}

	next unless ($update);

	if ($good + $bad == 0) {
	    &main::msg($main::who, "Updating debian files... please wait.");
	}

	if (exists $main::debian{$url}) {
	    &main::DEBUG("2: ".(time - $main::debian{$url})." <= $refresh");
	    next if (time() - $main::debian{$url} <= $refresh);
	    &main::DEBUG("stale for url $url; updating!");
	}

	if ($url =~ /^ftp:\/\/(.*?)\/(\S+)\/(\S+)$/) {
	    my ($host,$path,$thisfile) = ($1,$2,$3);

	    # error internally to ftp.
	    # hope it doesn't do anything bad.
	    if (!&main::ftpGet($host,$path,$thisfile,$file)) {
		&main::DEBUG("deb: down: ftpGet($host,$path,$thisfile,$file) == BAD.");
		$bad++;
		next;
	    }

	    if (! -f $file) {
		&main::DEBUG("deb: down: ftpGet: !file");
		$bad++;
		next;
	    }

	    &main::DEBUG("deb: download: good.");
	    $good++;
	} else {
	    &main::ERROR("Debian: invalid format of url => ($url).");
	    $bad++;
	    next;
	}
    }

    if ($good) {
	&generateIndex($dist);
	return 1;
    } else {
	return -1 unless ($bad);	# no download.
	&main::DEBUG("DD: !good and bad($bad). :(");
	return 0;
    }
}

###########################
# DEBIAN CONTENTS SEARCH FUNCTIONS.
########

####
# Usage: &searchContents($query);
sub searchContents {
    my ($dist, $query)	= &getDistroFromStr($_[0]);
    &main::status("Debian: Contents search for '$query' on $dist.");
    my $dccsend	= 0;

    $dccsend++		if ($query =~ s/^dcc\s+//i);
    ### larne's regex.
    # $query = $query.'(\.so\.)?([.[[:digit:]]+\.]+)?$';

    $query =~ s/\\([\^\$])/$1/g;
    $query =~ s/^\s+|\s+$//g;
    $query =~ s/\*/\\S*/g;		# does it even work?

    if (!&main::validExec($query)) {
	&main::msg($main::who, "search string looks fuzzy.");
	return;
    }

    if ($dist eq "incoming") {		# nothing yet.
	&main::DEBUG("sC: dist = 'incoming'. no contents yet.");
	return;
    } else {
	my %urls = &fixDist($dist, %urlcontents);
	# download contents file.
	&main::DEBUG("deb: download 1.");
	if (!&DebianDownload($dist, %urls)) {
	    &main::WARN("Debian: could not download files.");
	}
    }

    # start of search.
    my $start_time = &main::gettimeofday();

    my $found = 0;
    my %contents;
    my $search = "$query.*\[ \t]";
    my @files;
    foreach (keys %urlcontents) {
	s/##DIST/$dist/g;
	&main::DEBUG("checking for '$_'.");
	next unless ( -f $_);
	push(@files,$_);
    }

    if (!scalar @files) {
	&main::ERROR("sC: no files?");
	&main::msg($main::who, "failed.");
	return;
    }

    my $files = join(' ', @files);

    open(IN,"zegrep -h '$search' $files |");
    while (<IN>) {
	if (/^\.?\/?(.*?)[\t\s]+(\S+)\n$/) {
	    my ($file,$package) = ("/".$1,$2);
	    if ($query =~ /\//) {
		next unless ($file =~ /\Q$query\E/);
	    } else {
		my ($basename) = $file =~ /^.*\/(.*)$/;
		next unless ($basename =~ /\Q$query\E/);
	    }
	    next if ($query !~ /\.\d\.gz/ and $file =~ /\/man\//);

	    $contents{$package}{$file} = 1;
	    $found++;
	}
    }
    close IN;

    my $pkg;

    ### send results with dcc.
    if ($dccsend) {
	if (exists $main::dcc{'SEND'}{$main::who}) {
	    &main::msg($main::who, "DCC already active!");
	    return;
	}

	if (!scalar %contents) {
	    &main::msg($main::who,"search returned no results.");
	    return;
	}

	if (! -d "Temp/") {
	    mkdir("Temp",0755);
	}

	my $file = "temp/$main::who.txt";
	if (!open(OUT,">$file")) {
	    &main::ERROR("Debian: cannot write file for dcc send.");
	    return;
	}

	foreach $pkg (keys %contents) {
	    foreach (keys %{$contents{$pkg}}) {
		# TODO: correct padding.
		print OUT "$_\t\t\t$pkg\n";
	    }
	}
	close OUT;

	&main::shmWrite($main::shm, "DCC SEND $main::who $file");

	return;
    }

    &main::status("Debian: $found results.");

    my @list;
    foreach $pkg (keys %contents) {
	my @tmplist = &main::fixFileList(keys %{$contents{$pkg}});
	my @sublist = sort { length $a <=> length $b } @tmplist;

	pop @sublist while (scalar @sublist > 3);

	$pkg =~ s/\,/\037\,\037/g;	# underline ','.
	push(@list, "(". join(', ',@sublist) .") in $pkg");
    }
    # sort the total list from shortest to longest...
    @list = sort { length $a <=> length $b } @list;

    # show how long it took.
    my $delta_time = &main::gettimeofday() - $start_time;
    &main::status(sprintf("Debian: %.02f sec to complete query.", $delta_time)) if ($delta_time > 0);

    my $prefix = "Debian Search of '$query' ";
    &main::performStrictReply( &main::formListReply(0, $prefix, @list) );
}

####
# Usage: &searchAuthor($query);
sub searchAuthor {
    my ($dist, $query)	= &getDistroFromStr($_[0]);
    &main::DEBUG("searchAuthor: dist => '$dist', query => '$query'.");
    $query =~ s/^\s+|\s+$//g;

    # start of search.
    my $start_time = &main::gettimeofday();
    &main::status("Debian: starting author search.");

    my $files;
    my ($bad,$good) = (0,0);
    my %urls = %urlpackages;
    ### potato now has the "new" non-US tree like woody does.
    if ($dist =~ /^(woody|potato)$/) {
	%urls = &fixNonUS($dist, %urlpackages);
    }

    foreach (keys %urlpackages) {
	s/##DIST/$dist/g;

	if (! -f $_) {
	    $bad++;
	    next;
	}

	$good++;
	$files .= " ".$_;
    }

    &main::DEBUG("good = $good, bad = $bad...");

    if ($good == 0 and $bad != 0) {
	my %urls = &fixDist($dist, %urlpackages);
	&main::DEBUG("deb: download 2.");
	if (!&DebianDownload($dist, %urls)) {
	    &main::ERROR("Debian(sA): could not download files.");
	    return;
	}
    }

    my (%maint, %pkg, $package);
    open(IN,"zegrep -h '^Package|^Maintainer' $files |");
    while (<IN>) {
	if (/^Package: (\S+)$/) {
	    $package = $1;
	} elsif (/^Maintainer: (.*) \<(\S+)\>$/) {
	    $maint{$1}{$2} = 1;
	    $pkg{$1}{$package} = 1;
	} else {
	    &main::WARN("invalid line: '$_'.");
	}
    }
    close IN;

    my %hash;
    # TODO: can we use 'map' here?
    foreach (grep /\Q$query\E/i, keys %maint) {
	$hash{$_} = 1;
    }

    # TODO: should we only search email if '@' is used?
    if (scalar keys %hash < 15) {
	my $name;
	foreach $name (keys %maint) {
	    my $email;
	    foreach $email (keys %{$maint{$name}}) {
		next unless ($email =~ /\Q$query\E/i);
		next if (exists $hash{$name});
		$hash{$name} = 1;
	    }
	}
    }

    my @list = keys %hash;
    if (scalar @list != 1) {
	my $prefix = "Debian Author Search of '$query' ";
	&main::performStrictReply( &main::formListReply(0, $prefix, @list) );
	return 1;
    }

    &main::DEBUG("showing all packages by '$list[0]'...");

    my @pkg = sort keys %{$pkg{$list[0]}};

    # show how long it took.
    my $delta_time = &main::gettimeofday() - $start_time;
    &main::status(sprintf("Debian: %.02f sec to complete query.", $delta_time)) if ($delta_time > 0);

    my $email	= join(', ', keys %{$maint{$list[0]}});
    my $prefix	= "Debian Packages by $list[0] \002<\002$email\002>\002 ";
    &main::performStrictReply( &main::formListReply(0, $prefix, @pkg) );
}

####
# Usage: &generateIncoming();
sub generateIncoming {
    my $interval = $main::param{'debianRefreshInterval'};
    my $pkgfile  = "debian/Packages-incoming";
    my $idxfile  = $pkgfile.".idx";
    my $stale	 = 0;
    $stale++ if (&main::isStale($pkgfile.".gz", $interval));
    $stale++ if (&main::isStale($idxfile.".gz", $interval));
    &main::DEBUG("gI: stale => '$stale'.");
    return 0 unless ($stale);

    ### STATIC URL.
    my %ftp = &main::ftpList("llug.sep.bnl.gov", "/pub/debian/Incoming/");

    if (!open(PKG,">$pkgfile")) {
	&main::ERROR("cannot write to pkg $pkgfile.");
	return 0;
    }
    if (!open(IDX,">$idxfile")) {
	&main::ERROR("cannot write to idx $idxfile.");
	return 0;
    }

    print IDX "*$pkgfile.gz\n";
    my $file;
    foreach $file (sort keys %ftp) {
	next unless ($file =~ /deb$/);

	if ($file =~ /^(\S+)\_(\S+)\_(\S+)\.deb$/) {
	    print IDX "$1\n";
	    print PKG "Package: $1\n";
	    print PKG "Version: $2\n";
	    print PKG "Architecture: ", (defined $4) ? $4 : "all", "\n";
	}
	print PKG "Filename: $file\n";
	print PKG "Size: $ftp{$file}\n";
	print PKG "\n";
    }
    close IDX;
    close PKG;

    system("gzip -9fv $pkgfile");	# lame fix.

    &main::status("Debian: generateIncoming() complete.");
}


##############################
# DEBIAN PACKAGE INFO FUNCTIONS.
#########

# Usage: &getPackageInfo($query,$file);
sub getPackageInfo {
    my ($package, $file) = @_;

    if (! -f $file) {
	&main::status("gPI: file $file does not exist?");
	return 'NULL';
    }

    my $found = 0;
    my (%pkg, $pkg);

    open(IN, "zcat $file 2>&1 |");

    my $done = 0;
    while (!eof IN) {
	$_ = <IN>;

	next if (/^ \S+/);	# package long description.

	# package line.
	if (/^Package: (.*)\n$/) {
	    $pkg = $1;
	    if ($pkg =~ /^$package$/i) {
		$found++;	# we can use pkg{'package'} instead.
		$pkg{'package'} = $pkg;
	    }

	    next;
	}

	if ($found) {
	    chop;

	    if (/^Version: (.*)$/) {
		$pkg{'version'}		= $1;
	    } elsif (/^Priority: (.*)$/) {
		$pkg{'priority'}	= $1;
	    } elsif (/^Section: (.*)$/) {
		$pkg{'section'}		= $1;
	    } elsif (/^Size: (.*)$/) {
		$pkg{'size'}		= $1;
	    } elsif (/^i.*size: (.*)$/) {
		$pkg{'installed'}	= $1;
	    } elsif (/^Description: (.*)$/) {
		$pkg{'desc'}		= $1;
	    } elsif (/^Filename: (.*)$/) {
		$pkg{'find'}		= $1;
	    } elsif (/^Pre-Depends: (.*)$/) {
		$pkg{'depends'}		= "pre-depends on $1";
	    } elsif (/^Depends: (.*)$/) {
		if (exists $pkg{'depends'}) {
		    $pkg{'depends'} .= "; depends on $1";
		} else {
		    $pkg{'depends'} = "depends on $1";
		}
	    } elsif (/^Maintainer: (.*)$/) {
		$pkg{'maint'} = $1;
	    } elsif (/^Provides: (.*)$/) {
		$pkg{'provides'} = $1;
	    } elsif (/^Suggests: (.*)$/) {
		$pkg{'suggests'} = $1;
	    } elsif (/^Conflicts: (.*)$/) {
		$pkg{'conflicts'} = $1;
	    }

###	    &main::DEBUG("=> '$_'.");
	}

	# blank line.
	if (/^$/) {
	    undef $pkg;
	    last if ($found);
	    next;
	}

	next if (defined $pkg);
    }

    close IN;

    %pkg;
}

# Usage: &infoPackages($query,$package);
sub infoPackages {
    my ($query,$dist,$package) = ($_[0], &getDistroFromStr($_[1]));
    my $interval = $main::param{'debianRefreshInterval'} || 7;

    &main::status("Debian: Searching for package '$package' in '$dist'.");

    # download packages file.
    # hrm...
    my %urls = &fixDist($dist, %urlpackages);
    if ($dist ne "incoming") {
	&main::DEBUG("deb: download 3.");
	if (!&DebianDownload($dist, %urls)) {	# no good download.
	    &main::WARN("Debian(iP): could not download ANY files.");
	}
    }

    # check if the package is valid.
    my $incoming = 0;
    my @files = &validPackage($package, $dist);
    if (!scalar @files) {
	&main::status("Debian: no valid package found; checking incoming.");
	@files = &validPackage($package, "incoming");
	if (scalar @files) {
	    &main::status("Debian: cool, it exists in incoming.");
	    $incoming++;
	} else {
	    &main::msg($main::who, "Package '$package' does not exist.");
	    return 0;
	}
    }

    if (scalar @files > 1) {
	&main::WARN("same package in more than one file; random.");
	&main::DEBUG("THIS SHOULD BE FIXED SOMEHOW!!!");
	$files[0] = &main::getRandom(@files);
    }

    if (! -f $files[0]) {
	&main::WARN("files[0] ($files[0]) doesn't exist.");
	&main::msg($main::who, "WARNING: $files[0] does not exist? FIXME");
	return 'NULL';
    }

    ### TODO: if specific package is requested, note down that a version
    ###		exists in incoming.

    my $found = 0;
    my $file = $files[0];
    my ($pkg);

    ### TODO: use fe, dump to a hash. if only one version of the package
    ###		exists. do as normal otherwise list all versions.
    if (! -f $file) {
	&main::ERROR("D:iP: file '$file' DOES NOT EXIST!!! should never happen.");
	return 0;
    }
    my %pkg = &getPackageInfo($package, $file);

    # 'fm'-like output.
    if ($query eq "info") {
	if (scalar keys %pkg > 5) {
	    $pkg{'info'}  = "\002(\002". $pkg{'desc'} ."\002)\002";
	    $pkg{'info'} .= ", section ".$pkg{'section'};
	    $pkg{'info'} .= ", is ".$pkg{'priority'};
	    $pkg{'info'} .= ". Version: \002$pkg{'version'}\002";
	    $pkg{'info'} .= ", Packaged size: \002". int($pkg{'size'}/1024) ."\002 kB";
	    $pkg{'info'} .= ", Installed size: \002$pkg{'installed'}\002 kB";

	    if ($incoming) {
		&main::status("iP: info requested and pkg is in incoming, too.");
		my %incpkg = &getPackageInfo($query, "debian/Packages-incoming");

		if (scalar keys %incpkg) {
		   $pkg{'info'} .= ". Is in incoming ($incpkg{'file'}).";
		} else {
		    &main::ERROR("iP: pkg $query is in incoming but we couldn't get any info?");
		}
	    }
	} else {
	    &main::DEBUG("running debianCheck() due to problems (".scalar(keys %pkg).").");
	    &debianCheck();
	    &main::DEBUG("end of debianCheck()");

	    &main::msg($main::who,"Debian: Package appears to exist but I could not retrieve info about it...");
	    return;
	}
    } 

    if ($dist eq "incoming") {
	$pkg{'info'} .= "Version: \002$pkg{'version'}\002";
	$pkg{'info'} .= ", Packaged size: \002". int($pkg{'size'}/1024) ."\002 kB";
	$pkg{'info'} .= ", is in incoming!!!";
    }

    if (!exists $pkg{$query}) {
	if ($query eq "suggests") {
	    $pkg{$query} = "has no suggestions";
	} elsif ($query eq "conflicts") {
	    $pkg{$query} = "does not conflict with any other package";
	} elsif ($query eq "depends") {
	    $pkg{$query} = "does not depend on anything";
	} elsif ($query eq "maint") {
	    $pkg{$query} = "has no maintainer";
	} else {
	    $pkg{$query} = "has nothing about $query";
	}
    }

    &main::performStrictReply("$package: $pkg{$query}");
}

# Usage: &infoStats($dist);
sub infoStats {
    my ($dist)	= @_;
    $dist	= &getDistro($dist);
    return unless (defined $dist);

    &main::DEBUG("infoS: dist => '$dist'.");
    my $interval = $main::param{'debianRefreshInterval'} || 7;

    # download packages file if needed.
    my %urls = &fixDist($dist, %urlpackages);
    &main::DEBUG("deb: download 4.");
    if (!&DebianDownload($dist, %urls)) {
	&main::WARN("Debian(iS): could not download ANY files.");
	&main::msg($main::who, "Debian(iS): internal error.");
	return;
    }

    my %stats;
    my %total;
    my $file;
    foreach $file (keys %urlpackages) {
	$file =~ s/##DIST/$dist/g;	# won't work for incoming.
	&main::DEBUG("file => '$file'.");
	if (exists $stats{$file}{'count'}) {
	    &main::DEBUG("hrm... duplicate open with $file???");
	    next;
	}

	open(IN,"zcat $file 2>&1 |");

	if (! -e $file) {
	    &main::DEBUG("iS: $file does not exist.");
	    next;
	}

	while (!eof IN) {
	    $_ = <IN>;

	    next if (/^ \S+/);	# package long description.

	    if (/^Package: (.*)\n$/) {		# counter.
		$stats{$file}{'count'}++;
		$total{'count'}++;
	    } elsif (/^Maintainer: .* <(\S+)>$/) {
		$stats{$file}{'maint'}{$1}++;
		$total{'maint'}{$1}++;
	    } elsif (/^Size: (.*)$/) {		# compressed size.
		$stats{$file}{'csize'}	+= $1;
		$total{'csize'}		+= $1;
	    } elsif (/^i.*size: (.*)$/) {	# installed size.
		$stats{$file}{'isize'}	+= $1;
		$total{'isize'}		+= $1;
	    }

###	    &main::DEBUG("=> '$_'.");
	}
	close IN;
    }

    &main::performStrictReply(
	"Debian Distro Stats on $dist... ".
	"\002$total{'count'}\002 packages, ".
	"\002".scalar(keys %{$total{'maint'}})."\002 maintainers, ".
	"\002". int($total{'isize'}/1024)."\002 MB installed size, ".
	"\002". int($total{'csize'}/1024/1024)."\002 MB compressed size."
    );

### TODO: do individual stats? if so, we need _another_ arg.
#    foreach $file (keys %stats) {
#	foreach (keys %{$stats{$file}}) {
#	    &main::DEBUG("  '$file' '$_' '$stats{$file}{$_}'.");
#	}
#    }

    return;
}



###
# HELPER FUNCTIONS FOR INFOPACKAGES...
###

# Usage: &generateIndex();
sub generateIndex {
    my (@dists)	= @_;
    &main::DEBUG("Debian: generateIndex() called.");
    if (!scalar @dists) {
	&main::ERROR("gI: no dists to generate index.");
	return 1;
    }

    foreach (@dists) {
	my $dist = &getDistro($_); # incase the alias is returned, possible?
	my $idx  = "debian/Packages-$dist.idx";

	# TODO: check if any of the Packages file have been updated then
	#	regenerate it, even if it's not stale.
	# TODO: also, regenerate the index if the packages file is newer
	#	than the index.
	next unless (&main::isStale($idx, $main::param{'debianRefreshInterval'}));
	if (/^incoming$/i) {
	    &main::DEBUG("gIndex: calling generateIncoming()!");
	    &generateIncoming();
	    next;
	}

	&main::DEBUG("gIndeX: calling DebianDownload($dist, ...).");
	&DebianDownload($dist, %urlpackages);

	&main::status("Debian: generating index for '$_'.");
	if (!open(OUT,">$idx")) {
	    &main::ERROR("cannot write to $idx.");
	    return 0;
	}

	my $packages;
	foreach $packages (keys %urlpackages) {
	    $packages =~ s/##DIST/$dist/;

	    if (! -e $packages) {
		&main::ERROR("gIndex: '$packages' does not exist?");
		next;
	    }

	    print OUT "*$packages\n";
	    open(IN,"zcat $packages |");

	    while (<IN>) {
		if (/^Package: (.*)\n$/) {
		    print OUT $1."\n";
		}
	    }
	    close IN;
	}
	close OUT;
    }

    return 1;
}

# Usage: &validPackage($package, $dist);
sub validPackage {
    my ($package,$dist) = @_;
    my @files;
    my $file;

    &main::DEBUG("D: validPackage($package, $dist) called.");

    my $error = 0;
    while (!open(IN, "debian/Packages-$dist.idx")) {
	if ($error) {
	    &main::ERROR("Packages-$dist.idx does not exist (#1).");
	    return;
	}

	&generateIndex($dist);

	$error++;
    }

    my $count = 0;
    while (<IN>) {
	if (/^\*(.*)\n$/) {
	    $file = $1;
	    next;
	}

	if (/^$package\n$/) {
	    push(@files,$file);
	}
	$count++;
    }
    close IN;

    &main::DEBUG("vP: scanned $count items in index.");

    return @files;
}

sub searchPackage {
    my ($dist, $query) = &getDistroFromStr($_[0]);
    my $file = "debian/Packages-$dist.idx";
    my @files;
    my $error = 0;

    &main::status("Debian: Search package matching '$query' in '$dist'.");
    if ( -z $file) {
	&main::DEBUG("sP: $file == NULL; removing, redoing.");
	unlink $file;
    }

    while (!open(IN, $file)) {
	&main::ERROR("$file does not exist (#2).");
	if ($dist eq "incoming") {
	    &main::DEBUG("sP: dist == incoming; calling gI().");
	    &generateIncoming();
	}

	if ($error) {
	    &main::ERROR("could not generate index!!!");
	    return;
	}
	$error++;
	&generateIndex(($dist));
    }

    while (<IN>) {
	chop;

	if (/^\*(.*)$/) {
	    &main::DEBUG("sP: hrm => '$1'.");

	    if (&main::isStale($file, $main::param{'debianRefreshInterval'})) {
		&main::DEBUG("STALE $file! regen.");
		&generateIndex(($dist));
###		@files = searchPackage("$query $dist");
		&main::DEBUG("EVIL HACK HACK HACK.");
		last;
	    }

	    $file = $1;
	    next;
	}

	if (/\Q$query\E/) {
	    push(@files,$_);
	}
    }
    close IN;

    return @files;
}

sub getDistro {
    my $dist = $_[0];

    if (!defined $dist or $dist eq "") {
	&main::DEBUG("gD: dist == NULL; dist = defaultdist.");
	$dist = $defaultdist;
    }

    if (exists $dists{$dist}) {
	return $dists{$dist};
    } else {
	if (!grep /^\Q$dist\E$/i, %dists) {
	    &main::msg($main::who, "invalid dist '$dist'.");
	    return;
	}

	return $dist;
    }
}

sub getDistroFromStr {
    my ($str) = @_;
    my $dists	= join '|', %dists;
    my $dist	= $defaultdist;

    if ($str =~ s/\s+($dists)$//i) {
	$dist = &getDistro(lc $1);
	$str =~ s/\\+$//;
    }
    $str =~ s/\\([\$\^])/$1/g;

    return($dist,$str);
}

sub fixDist {
    my ($dist, %urls) = @_;
    my %new;
    my ($key,$val);

    while (($key,$val) = each %urls) {
	$key =~ s/##DIST/$dist/;
	$val =~	s/##DIST/$dist/;
	### TODO: what should we do if the sar wasn't done.
	$new{$key} = $val;
    }
    return %new;
}

sub DebianFind {
    ### H-H-H-HACK HACK HACK :)
    my ($str) = @_;
    my ($dist, $query) = &getDistroFromStr($str);
    my @results = sort &searchPackage($str);

    if (!scalar @results) {
	&main::Forker("debian", sub { &searchContents($str); } );
    } elsif (scalar @results == 1) {
	&main::status("searchPackage returned one result; getting info of package instead!");
	&main::Forker("debian", sub { &infoPackages("info", "$results[0] $dist"); } );
    } else {
	my $prefix = "Debian Package Listing of '$str' ";
	&main::performStrictReply( &main::formListReply(0, $prefix, @results) );
    }
}

### TODO: move DWH to &fixDist() or leave it being called by DD?
sub fixNonUS {
    my ($dist, %urls) = @_;

    foreach (keys %urls) {
	last unless ($dist =~ /^(woody|potato)$/);
	next unless (/non-US/);
	&main::DEBUG("DD: Enabling hack (to keep slink happy) for $dist non-US.");

	my $file = $_;
	my $url  = $urls{$_};
	delete $urls{$file};	# heh.

	foreach ("main","contrib","non-free") {
	    my ($newfile,$newurl) = ($file,$url);
	    # only needed for Packages for now, not Contents; good.
	    $newfile =~ s/non-US/non-US_$_/;
	    $newurl =~ s#non-US/bin#non-US/$_/bin#;
	    &main::DEBUG("URL{$newfile} => '$newurl'.");
	    $urls{$newfile} = $newurl;
	}

	&main::DEBUG("DD: Files: ".scalar(keys %urls));
	last;
    }

    %urls;
}

sub debianCheck {
    my $dir	= "debian/";
    my $error	= 0;

    &main::status("debianCheck() called.");

    ### TODO: remove the following loop (check if dir exists before)
    while (1) {
	last if (opendir(DEBIAN, $dir));
	if ($error) {
	    &main::ERROR("dC: cannot opendir debian.");
	    return;
	}
	mkdir $dir, 0755;
	$error++;
    }

    my $retval = 0;
    my $file;
    while (defined($file = readdir DEBIAN)) {
	next unless ($file =~ /(gz|bz2)$/);

	my $exit = system("gzip -t '$dir/$file'");
	next unless ($exit);
	&main::DEBUG("hmr... => ".(time() - (stat($file))[8])."'.");
	next unless (time() - (stat($file))[8] > 3600);

	&main::DEBUG("dC: exit => '$exit'.");
	&main::WARN("dC: '$dir/$file' corrupted? deleting!");
	unlink $dir."/".$file;
	$retval++;
    }

    return $retval;
}

1;
