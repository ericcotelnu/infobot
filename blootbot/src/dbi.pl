#
#   dbi.pl: DBI (mysql/pgsql/sqlite) database frontend.
#   Author: dms
#  Version: v0.2c (19991224)
#  Created: 19991203
#    Notes: based on db_mysql.pl
#

use strict;

use vars qw(%param);
use vars qw($dbh $shm $bot_data_dir);

package main;

#####
# &openDB($dbname, $dbtype, $sqluser, $sqlpass, $nofail);
sub openDB {
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

sub closeDB {
    return 0 unless ($dbh);

    my $x = $param{SQLHost};
    my $hoststr = ($x) ? " to $x" : "";

    &status("Closed DBI connection$hoststr.");
    $dbh->disconnect();

    return 1;
}

#####
# Usage: &dbQuote($str);
sub dbQuote {
    return $dbh->quote($_[0]);
}

#####
# Usage: &dbGet($table, $select, $where);
sub dbGet {
    my ($table, $select, $where) = @_;
    my $query	= "SELECT $select FROM $table";
    $query	.= " WHERE $where" if ($where);

    if (!defined $select or $select =~ /^\s*$/) {
	&WARN("dbGet: select == NULL.");
	return;
    }

    if (!defined $table or $table =~ /^\s*$/) {
	&WARN("dbGet: table == NULL.");
	return;
    }

    my $sth;
    if (!($sth = $dbh->prepare($query))) {
	&ERROR("Get: prepare: $DBI::errstr");
	return;
    }

    &SQLDebug($query);
    if (!$sth->execute) {
	&ERROR("Get: execute: '$query'");
	$sth->finish;
	return 0;
    }

    my @retval = $sth->fetchrow_array;

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
# Usage: &dbGetCol($table, $select, $where, [$type]);
sub dbGetCol {
    my ($table, $select, $where, $type) = @_;
    my $query	= "SELECT $select FROM $table";
    $query	.= " WHERE ".$where if ($where);
    my %retval;

    my $sth = $dbh->prepare($query);
    &SQLDebug($query);
    if (!$sth->execute) {
	&ERROR("GetCol: execute: '$query'");
	$sth->finish;
	return;
    }

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
# Usage: &dbGetColNiceHash($table, $select, $where);
sub dbGetColNiceHash {
    my ($table, $select, $where) = @_;
    $select	||= "*";
    my $query	= "SELECT $select FROM $table";
    $query	.= " WHERE ".$where if ($where);
    my %retval;

    my $sth;
    if (!($sth = $dbh->prepare($query))) {
	&ERROR("GetColNiceHash: prepare: $DBI::errstr");
	return;
    }
    &SQLDebug($query);
    if (!$sth->execute) {
	&ERROR("GetColNiceHash: execute: '$query'");
#	&ERROR("GetCol => $DBI::errstr");
	$sth->finish;
	return;
    }

    my $retval = $sth->fetchrow_hashref();

    $sth->finish;

    if ($retval) {
	return %{$retval};
    } else {
	return;
    }
}

####
# Usage: &dbGetColInfo($table);
sub dbGetColInfo {
    my ($table) = @_;

    my $query = "SHOW COLUMNS from $table";
    if ($param{DBType} =~ /^pg/i) {
	$query = "SELECT * FROM $table LIMIT 1";
    }

    my %retval;

    my $sth = $dbh->prepare($query);
    &SQLDebug($query);
    if (!$sth->execute) {
	&ERROR("GRI => '$query'");
	&ERROR("GRI => $DBI::errstr");
	$sth->finish;
	return;
    }

    my @cols;
    while (my @row = $sth->fetchrow_array) {
	push(@cols, $row[0]);
    }
    $sth->finish;

    return @cols;
}

##### NOTE: not used yet.
# Usage: &dbSelectHashref($select, $from, $where, $other)
sub dbSelectHashref {
    my $c = dbSelectManyHash(@_);
    my $H = $c->fetchrow_hashref;
    $c->finish;
    return $H;
}

##### NOTE: not used yet.
# Usage: &dbSelectHashref($select, $from, $where, $other)
sub dbSelectManyHash {
    my($select, $from, $where, $other) = @_;
    my $sql;   

    $sql = "SELECT $select ";
    $sql .= "FROM $from "	if $from;
    $sql .= "WHERE $where "	if $where;
    $sql .= "$other"		if $other;

#    sqlConnect();
    my $c = $dbh->prepare($sql);
    # $c->execute or print "\n<P><B>SQL Hashref Error</B><BR>\n";

    unless ($c->execute) {
#	apacheLog($sql);
	#kill 9,$$;
    }

    return $c;
}


#####
# Usage: &dbSet($table, $primhash_ref, $hash_ref);
#  Note: dbSet does dbQuote.
sub dbSet {
    my ($table, $phref, $href) = @_;
    my $where = join(' AND ', map {
		$_."=".&dbQuote($phref->{$_})
	} keys %{$phref}
    );

    if (!defined $phref) {
	&WARN("dbset: phref == NULL.");
	return;
    }

    if (!defined $href) {
	&WARN("dbset: href == NULL.");
	return;
    }

    if (!defined $table) {
	&WARN("dbset: table == NULL.");
	return;
    }

    my(@keys,@vals);
    foreach (keys %{$href}) {
	push(@keys, $_);
	push(@vals, &dbQuote($href->{$_}) );
    }

    if (!@keys or !@vals) {
	&WARN("dbset: keys or vals is NULL.");
	return;
    }

    my $result = &dbGet($table, join(',', keys %{$phref}), $where);

    my $query;
    if (defined $result) {
	my @keyval;
	for(my$i=0; $i<scalar @keys; $i++) {
	    push(@keyval, $keys[$i]."=".$vals[$i] );
	}

	$query = "UPDATE $table SET ".
		join(', ', @keyval).
		" WHERE ".$where;
    } else {
	foreach (keys %{$phref}) {
	    push(@keys, $_);
	    push(@vals, &dbQuote($phref->{$_}) );
	}

	$query = sprintf("INSERT INTO $table (%s) VALUES (%s)",
		join(',',@keys), join(',',@vals) );
    }

    &dbRaw("Set", $query);

    return 1;
}

#####
# Usage: &dbUpdate($table, $primkey, $primval, %hash);
#  Note: dbUpdate does dbQuote.
sub dbUpdate {
    my ($table, $primkey, $primval, %hash) = @_;
    my (@array);

    foreach (keys %hash) {
	push(@array, "$_=".&dbQuote($hash{$_}) );
    }

    &dbRaw("Update", "UPDATE $table SET ".join(', ', @array).
		" WHERE $primkey=".&dbQuote($primval)
    );

    return 1;
}

#####
# Usage: &dbInsert($table, $primkey, %hash);
#  Note: dbInsert does dbQuote.
sub dbInsert {
    my ($table, $primkey, %hash, $delay) = @_;
    my (@keys, @vals);
    my $p	= "";

    if ($delay) {
	&DEBUG("dbI: delay => $delay");
	$p	= " DELAYED";
    }

    foreach (keys %hash) {
	push(@keys, $_);
	push(@vals, &dbQuote( $hash{$_} ));
    }

    &dbRaw("Insert($table)", "INSERT $p INTO $table (".join(',',@keys).
		") VALUES (".join(',',@vals).")"
    );

    return 1;
}

#####
# Usage: &dbReplace($table, $key, %hash);
#  Note: dbReplace does optional dbQuote.
sub dbReplace {
    my ($table, $key, %hash) = @_;
    my (@keys, @vals);

    foreach (keys %hash) {
	if (s/^-//) {	# as is.
	    push(@keys, $_);
	    push(@vals, $hash{'-'.$_});
	} else {
	    push(@keys, $_);
	    push(@vals, &dbQuote( $hash{$_} ));
	}
    }

    # hrm... does pgsql support REPLACE?
    # if not, well... fuck it.
    &dbRaw("Replace($table)", "REPLACE INTO $table (".join(',',@keys).
		") VALUES (". join(',',@vals). ")"
    );

    return 1;
}

#####
# Usage: &dbSetRow($table, $vref, $delay);
#  Note: dbSetRow does dbQuote.
sub dbSetRow ($@$) {
    my ($table, $vref, $delay) = @_;
    my $p	= ($delay) ? " DELAYED " : "";

    # see 'perldoc perlreftut'
    my @values;
    foreach (@{ $vref }) {
	push(@values, &dbQuote($_) );
    }

    if (!scalar @values) {
	&WARN("dbSetRow: values array == NULL.");
	return;
    }

    return &dbRaw("SetRow", "INSERT $p INTO $table VALUES (".
	join(",", @values) .")" );
}

#####
# Usage: &dbDel($table, $primkey, $primval, [$key]);
#  Note: dbDel does dbQuote
sub dbDel {
    my ($table, $primkey, $primval, $key) = @_;

    &dbRaw("Del", "DELETE FROM $table WHERE $primkey=".
		&dbQuote($primval)
    );

    return 1;
}

# Usage: &dbRaw($prefix,$rawquery);
sub dbRaw {
    my ($prefix,$query) = @_;
    my $sth;

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

# Usage: &dbRawReturn($rawquery);
sub dbRawReturn {
    my ($query) = @_;
    my @retval;

    my $sth = $dbh->prepare($query);
    &SQLDebug($query);
    # what happens when it can't execute it? does it throw heaps more
    # error lines? if so. follow dbRaw()'s style.
    &ERROR("RawReturn => '$query'.") unless $sth->execute;
    while (my @row = $sth->fetchrow_array) {
	push(@retval, $row[0]);
    }
    $sth->finish;

    return @retval;
}

####################################################################
##### Misc DBI stuff...
#####

#####
# Usage: &countKeys($table, [$col]);
sub countKeys {
    my ($table, $col) = @_;
    $col ||= "*";
    &DEBUG("&countKeys($table, $col);");

    return (&dbRawReturn("SELECT count($col) FROM $table"))[0];
}

#####
# Usage: &sumKey($table, $col);
sub sumKey {
    my ($table, $col) = @_;

    return (&dbRawReturn("SELECT sum($col) FROM $table"))[0];
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
    &dbRaw("deleteTable($_[0])", "DELETE FROM $_[0]");
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
		&dbQuote($str);
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
	&dbRaw("dbcreateTable($table)", $data);
	return 1;
    }
}

sub checkTables {
    my $database_exists = 0;
    my %db;

    if ($param{DBType} =~ /^mysql$/i) {
	my $sql = "SHOW DATABASES";
	foreach ( &dbRawReturn($sql) ) {
	    $database_exists++ if ($_ eq $param{'DBName'});
	}

	unless ($database_exists) {
	    &status("Creating database $param{DBName}...");
	    my $query = "CREATE DATABASE $param{DBName}";
	    &dbRaw("create(db $param{DBName})", $query);
	}

	# retrieve a list of db's from the server.
	foreach ($dbh->func('_ListTables')) {
	    $db{$_} = 1;
	}

    } elsif ($param{DBType} =~ /^SQLite$/i) {

	# retrieve a list of db's from the server.
	foreach ( &dbRawReturn("SELECT name FROM sqlite_master WHERE type='table'") ) {
	    $db{$_} = 1;
	}

	# create database.
	if (!scalar keys %db) {
	    &status("Creating database $param{'DBName'}...");
	    my $query = "CREATE DATABASE $param{'DBName'}";
	    &dbRaw("create(db $param{'DBName'})", $query);
	}
    }

    foreach ( qw(factoids freshmeat rootwarn seen stats botmail) ) {
	next if (exists $db{$_});
	&status("checkTables: creating new table $_...");

	&dbCreateTable($_);
    }
}

1;
