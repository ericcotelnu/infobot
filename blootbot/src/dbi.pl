#
#   dbi.pl: DBI (mysql/pgsql/sqlite) database frontend.
#   Author: dms
#  Version: v0.9a (20021124)
#  Created: 19991203
#    Notes: based on db_mysql.pl
#	    overhauled to be 31337.
#

use strict;

use vars qw(%param);
use vars qw($dbh $shm $bot_data_dir);

package main;

#####
# &sqlOpenDB($dbname, $dbtype, $sqluser, $sqlpass, $nofail);
sub sqlOpenDB {
    my ($db, $type, $user, $pass, $no_fail) = @_;
    # this is a mess. someone fix it, please.
    if ($type =~ /^SQLite$/i) {
	$db = "dbname=$db.sqlite";
    } elsif ($type =~ /^pg/i) {
	$db = "dbname=$db";
	$type = "Pg";
    }

    my $dsn = "DBI:$type:$db";
    my $hoststr = "";
    # SQLHost should be unset for SQLite
    if (exists $param{'SQLHost'} and $param{'SQLHost'}) {
	$dsn    .= ":$param{SQLHost}";
	$hoststr = " to $param{'SQLHost'}";
    }
    # SQLite ignores $user and $pass
    $dbh    = DBI->connect($dsn, $user, $pass);

    if ($dbh && !$dbh->err) {
	&status("Opened $type connection$hoststr");
    } else {
	&ERROR("cannot connect$hoststr.");
	&ERROR("since $type is not available, shutting down bot!");
	&ERROR( $dbh->errstr ) if ($dbh);
	&closePID();
	&closeSHM($shm);
	&closeLog();

	return 0 if ($no_fail);

	exit 1;
    }
}

sub sqlCloseDB {
    return 0 unless ($dbh);

    my $x = $param{SQLHost};
    my $hoststr = ($x) ? " to $x" : "";

    &status("Closed DBI connection$hoststr.");
    $dbh->disconnect();

    return 1;
}

#####
# Usage: &sqlQuote($str);
sub sqlQuote {
    return $dbh->quote($_[0]);
}

#####
#  Usage: &sqlSelectMany($table, $select, [$where_href], [$other]);
# Return: $sth (Statement handle object)
sub sqlSelectMany {
    my($table, $select, $where_href, $other) = @_;
    my $query = "SELECT $select FROM $table";
    my $sth;

    if (!defined $select or $select =~ /^\s*$/) {
	&WARN("sqlSelectMany: select == NULL.");
	return;
    }

    if (!defined $table or $table =~ /^\s*$/) {
	&WARN("sqlSelectMany: table == NULL.");
	return;
    }

    if ($where_href) {
	my $where = &hashref2where($where_href);
	$query .= " WHERE $where" if ($where);
    }
    $query .= " $other"		if $other;

    if (!($sth = $dbh->prepare($query))) {
	&ERROR("sqlSelectMany: prepare: $DBI::errstr");
	return;
    }

    &SQLDebug($query);
    if (!$sth->execute) {
	&ERROR("sqlSelectMany: execute: '$query'");
	return;
    }

    return $sth;
}

#####
#  Usage: &sqlSelect($table, $select, [$where_href, [$other]);
# Return: scalar if one element, array if list of elements.
#   Note: Suitable for one column returns, that is, one column in $select.
#   Todo: Always return array?
sub sqlSelect {
    my $sth	= &sqlSelectMany(@_);
    if (!defined $sth) {
	&WARN("sqlSelect failed.");
	return;
    }
    my @retval	= $sth->fetchrow_array;
    $sth->finish;

    if (scalar @retval > 1) {
	return @retval;
    } elsif (scalar @retval == 1) {
	return $retval[0];
    } else {
	return;
    }
}

#####
#  Usage: &sqlSelectColArray($table, $select, [$where_href], [$other]);
# Return: array.
sub sqlSelectColArray {
    my $sth	= &sqlSelectMany(@_);
    my @retval;

    if (!defined $sth) {
	&WARN("sqlSelect failed.");
	return;
    }

    while (my @row = $sth->fetchrow_array) {
	push(@retval, $row[0]);
    }
    $sth->finish;

    return @retval;
}

#####
#  Usage: &sqlSelectColHash($table, $select, [$where_href], [$other], [$type]);
# Return: type = 1: $retval{ col2 }{ col1 } = 1;
# Return: no  type: $retval{ col1 } = col2;
#   Note: does not support $other, yet.
sub sqlSelectColHash {
    my ($table, $select, $where_href, $other, $type) = @_;
    my $sth	= &sqlSelectMany($table, $select, $where_href, $other);
    if (!defined $sth) {
	&WARN("sqlSelectColhash failed.");
	return;
    }
    my %retval;

    if (defined $type and $type == 2) {
	&DEBUG("dbgetcol: type 2!");
	while (my @row = $sth->fetchrow_array) {
	    $retval{$row[0]} = join(':', $row[1..$#row]);
	}
	&DEBUG("dbgetcol: count => ".scalar(keys %retval) );

    } elsif (defined $type and $type == 1) {
	while (my @row = $sth->fetchrow_array) {
	    # reverse it to make it easier to count.
	    if (scalar @row == 2) {
		$retval{$row[1]}{$row[0]} = 1;
	    } elsif (scalar @row == 3) {
		$retval{$row[1]}{$row[0]} = 1;
	    }
	    # what to do if there's only one or more than 3?
	}

    } else {
	while (my @row = $sth->fetchrow_array) {
	    $retval{$row[0]} = $row[1];
	}
    }

    $sth->finish;

    return %retval;
}

#####
#  Usage: &sqlSelectRowHash($table, $select, [$where_href]);
# Return: $hash{ col } = value;
#   Note: useful for returning only one/first row of data.
sub sqlSelectRowHash {
    my $sth	= &sqlSelectMany(@_);
    if (!defined $sth) {
	&WARN("sqlSelectRowHash failed.");
	return;
    }
    my $retval	= $sth->fetchrow_hashref();
    $sth->finish;

    if ($retval) {
	return %{ $retval };
    } else {
	return;
    }
}

#
# End of SELECT functions.
#

#####
#  Usage: &sqlSet($table, $where_href, $data_href);
# Return: 1 for success, undef for failure.
sub sqlSet {
    my ($table, $where_href, $data_href) = @_;

    if (!defined $table or $table =~ /^\s*$/) {
	&WARN("sqlSet: table == NULL.");
	return;
    }

    if (!defined $data_href or ref($data_href) ne "HASH") {
	&WARN("sqlSet: data_href == NULL.");
	return;
    }

    # any column can be NULL... so just get them all.
    my $k = join(',', keys %{ $where_href } );
    my $result = &sqlSelect($table, $k, $where_href);
#    &DEBUG("result is not defined :(") if (!defined $result);

    if (1 or defined $result) {
	&sqlUpdate($table, $data_href, $where_href);
    } else {
	# hack.
	my %hash = %{ $where_href };
	# add data_href values...
	foreach (keys %{ $data_href }) {
	    $hash{ $_ } = ${ $data_href }{$_};
	}

	$data_href = \%hash;
	&sqlInsert($table, $data_href);
    }

    return 1;
}

#####
# Usage: &sqlUpdate($table, $data_href, $where_href);
sub sqlUpdate {
    my ($table, $data_href, $where_href) = @_;

    if (!defined $data_href or ref($data_href) ne "HASH") {
	&WARN("sqlSet: data_href == NULL.");
	return;
    }

    my $where  = &hashref2where($where_href) if ($where_href);
    my $update = &hashref2update($data_href) if ($data_href);

    &sqlRaw("Update", "UPDATE $table SET $update WHERE $where");

    return 1;
}

#####
# Usage: &sqlInsert($table, $data_href, $other);
sub sqlInsert {
    my ($table, $data_href, $other) = @_;
    # note: if $other == 1, add "DELAYED" to function instead.

    if (!defined $data_href or ref($data_href) ne "HASH") {
	&WARN("sqlInsert: data_href == NULL.");
	return;
    }

    my ($k_aref, $v_aref) = &hashref2array($data_href);
    my @k = @{ $k_aref };
    my @v = @{ $v_aref };

    if (!@k or !@v) {
	&WARN("sqlInsert: keys or vals is NULL.");
	return;
    }

    &sqlRaw("Insert($table)", sprintf(
	"INSERT %s INTO %s (%s) VALUES (%s)",
	($other || ""), $table, join(',',@k), join(',',@v)
    ) );

    return 1;
}

#####
# Usage: &sqlReplace($table, $data_href);
sub sqlReplace {
    my ($table, $data_href) = @_;

    if (!defined $data_href or ref($data_href) ne "HASH") {
	&WARN("sqlReplace: data_href == NULL.");
	return;
    }

    my ($k_aref, $v_aref) = &hashref2array($data_href);
    my @k = @{ $k_aref };
    my @v = @{ $v_aref };

    if (!@k or !@v) {
	&WARN("sqlReplace: keys or vals is NULL.");
	return;
    }

    &sqlRaw("Replace($table)", sprintf(
	"REPLACE INTO %s (%s) VALUES (%s)",
	$table, join(',',@k), join(',',@v)
    ) );

    return 1;
}

#####
# Usage: &sqlDelete($table, $where_href);
sub sqlDelete {
    my ($table, $where_href) = @_;

    if (!defined $where_href or ref($where_href) ne "HASH") {
	&WARN("sqlDelete: where_href == NULL.");
	return;
    }

    my $where	= &hashref2where($where_href);

    &sqlRaw("Delete", "DELETE FROM $table WHERE $where");

    return 1;
}

#####
#  Usage: &sqlRaw($prefix, $query);
# Return: 1 for success, 0 for failure.
sub sqlRaw {
    my ($prefix, $query) = @_;
    my $sth;

    if (!defined $query or $query =~ /^\s*$/) {
	&WARN("sqlRaw: query == NULL.");
	return 0;
    }

    if (!($sth = $dbh->prepare($query))) {
	&ERROR("Raw($prefix): !prepare => '$query'");
	return 0;
    }

    &SQLDebug($query);
    if (!$sth->execute) {
	&ERROR("Raw($prefix): !execute => '$query'");
	$sth->finish;
	return 0;
    }

    $sth->finish;

    return 1;
}

#####
#  Usage: &sqlRawReturn($query);
# Return: array.
sub sqlRawReturn {
    my ($query) = @_;
    my @retval;
    my $sth;

    if (!defined $query or $query =~ /^\s*$/) {
	&WARN("sqlRawReturn: query == NULL.");
	return 0;
    }

    if (!($sth = $dbh->prepare($query))) {
	&ERROR("RawReturn: !prepare => '$query'");
	return 0;
    }

    &SQLDebug($query);
    if (!$sth->execute) {
	&ERROR("RawReturn: !execute => '$query'");
	$sth->finish;
	return 0;
    }

    while (my @row = $sth->fetchrow_array) {
	push(@retval, $row[0]);
    }

    $sth->finish;

    return @retval;
}

####################################################################
##### Misc DBI stuff...
#####

sub hashref2where {
    my ($href) = @_;

    if (!defined $href) {
	&WARN("hashref2where: href == NULL.");
	return;
    }

    if (ref($href) ne "HASH") {
	&WARN("hashref2where: href is not HASH ref (href => $href)");
	return;
    }

    my %hash = %{ $href };
    foreach (keys %hash) {
	my $v = $hash{$_};

	if (s/^-//) {   # as is.
	    $hash{$_} = $v;
	    delete $hash{'-'.$_};
	} else {
	    $hash{$_} = &sqlQuote($v);
	}
    }

    return join(' AND ', map { $_."=".$hash{$_} } keys %hash );
}

sub hashref2update {
    my ($href) = @_;

    if (ref($href) ne "HASH") {
	&WARN("hashref2update: href is not HASH ref.");
	return;
    }

    my %hash;
    foreach (keys %{ $href }) {
	my $k = $_;
	my $v = ${ $href }{$_};

	# is there a better way to do this?
	if ($k =~ s/^-//) {   # as is.
	    1;
	} else {
	    $v = &sqlQuote($v);
	}

	$hash{$k} = $v;
    }

    return join(', ', map { $_."=".$hash{$_} } sort keys %hash);
}

sub hashref2array {
    my ($href) = @_;

    if (ref($href) ne "HASH") {
	&WARN("hashref2update: href is not HASH ref.");
	return;
    }

    my(@k, @v);
    foreach (keys %{ $href }) {
	my $k = $_;
	my $v = ${ $href }{$_};

	# is there a better way to do this?
	if ($k =~ s/^-//) {   # as is.
	    1;
	} else {
	    $v = &sqlQuote($v);
	}

	push(@k, $k);
	push(@v, $v);
    }

    return (\@k, \@v);
}

#####
# Usage: &countKeys($table, [$col]);
sub countKeys {
    my ($table, $col) = @_;
    $col ||= "*";
    &DEBUG("&countKeys($table, $col);");

    return (&sqlRawReturn("SELECT count($col) FROM $table"))[0];
}

#####
# Usage: &sumKey($table, $col);
sub sumKey {
    my ($table, $col) = @_;

    return (&sqlRawReturn("SELECT sum($col) FROM $table"))[0];
}

#####
# Usage: &randKey($table, $select);
sub randKey {
    my ($table, $select) = @_;
    my $rand	= int(rand(&countKeys($table) - 1));
    my $query	= "SELECT $select FROM $table LIMIT $rand,1";
    if ($param{DBType} =~ /^pg/i) {
	$query =~ s/$rand,1/1,$rand/;
    }

    my $sth	= $dbh->prepare($query);
    &SQLDebug($query);
    &WARN("randKey($query)") unless $sth->execute;
    my @retval	= $sth->fetchrow_array;
    $sth->finish;

    return @retval;
}

#####
# Usage: &deleteTable($table);
sub deleteTable {
    &sqlRaw("deleteTable($_[0])", "DELETE FROM $_[0]");
}

#####
# Usage: &searchTable($table, $select, $key, $str);
#  Note: searchTable does dbQuote.
sub searchTable {
    my($table, $select, $key, $str) = @_;
    my $origStr = $str;
    my @results;

    # allow two types of wildcards.
    if ($str =~ /^\^(.*)\$$/) {
	&DEBUG("searchTable: should use dbGet(), heh.");
	$str = $1;
    } else {
	$str .= "%"	if ($str =~ s/^\^//);
	$str = "%".$str if ($str =~ s/\$$//);
	$str = "%".$str."%" if ($str eq $origStr);	# el-cheapo fix.
    }

    $str =~ s/\_/\\_/g;
    $str =~ s/\?/_/g;	# '.' should be supported, too.
    $str =~ s/\*/%/g;
    # end of string fix.

    my $query = "SELECT $select FROM $table WHERE $key LIKE ". 
		&sqlQuote($str);
    my $sth = $dbh->prepare($query);

    &SQLDebug($query);
    if (!$sth->execute) {
	&WARN("Search($query)");
	$sth->finish;
	return;
    }

    while (my @row = $sth->fetchrow_array) {
	push(@results, $row[0]);
    }
    $sth->finish;

    return @results;
}

sub dbCreateTable {
    my($table)	= @_;
    my(@path)	= ($bot_data_dir, ".","..","../..");
    my $found	= 0;
    my $data;

    foreach (@path) {
	my $file = "$_/setup/$table.sql";
	&DEBUG("dbCT: table => '$table', file => '$file'");
	next unless ( -f $file );

	&DEBUG("dbCT: found!!!");

	open(IN, $file);
	while (<IN>) {
	    chop;
	    $data .= $_;
	}

	$found++;
	last;
    }

    if (!$found) {
	return 0;
    } else {
	&sqlRaw("dbcreateTable($table)", $data);
	return 1;
    }
}

sub checkTables {
    my $database_exists = 0;
    my %db;

    if ($param{DBType} =~ /^mysql$/i) {
	my $sql = "SHOW DATABASES";
	foreach ( &sqlRawReturn($sql) ) {
	    $database_exists++ if ($_ eq $param{'DBName'});
	}

	unless ($database_exists) {
	    &status("Creating database $param{DBName}...");
	    my $query = "CREATE DATABASE $param{DBName}";
	    &sqlRaw("create(db $param{DBName})", $query);
	}

	# retrieve a list of db's from the server.
	foreach ($dbh->func('_ListTables')) {
	    $db{$_} = 1;
	}

    } elsif ($param{DBType} =~ /^SQLite$/i) {

	# retrieve a list of db's from the server.
	foreach ( &sqlRawReturn("SELECT name FROM sqlite_master WHERE type='table'") ) {
	    $db{$_} = 1;
	}

	# create database.
	if (!scalar keys %db) {
	    &status("Creating database $param{'DBName'}...");
	    my $query = "CREATE DATABASE $param{'DBName'}";
	    &sqlRaw("create(db $param{'DBName'})", $query);
	}
    }

    foreach ( qw(factoids freshmeat rootwarn seen stats botmail) ) {
	next if (exists $db{$_});
	&status("checkTables: creating new table $_...");

	&sqlCreateTable($_);
    }
}

1;
