#!/usr/bin/perl

use strict;
use DBI;
use Cwd;
use Cwd 'chdir';
use Getopt::Std;
use Data::Dumper;


my $dbproc = &ConnectToDb( 'BRCSTG11','dots', 'dots');
my $blastset="H1N1NewPand";
my $query ="SELECT accession, blastvalue FROM blast_info WHERE blastset = '$blastset'";

my @resultRow = &do_sql( $dbproc, $query );

my $cacheFile="/home/idaily/influenza_daily/classifier/H1N1NewPand.cached2";
      open CACHE,">$cacheFile" or die "Cannot open $cacheFile";

        foreach my $row (@resultRow){
        my ($id, $val) = split( ",", $row );

                print CACHE "$id\t$val\n";

        }
 
        close CACHE;







sub ConnectToDb {
        my ( $server, $user, $password ) = @_;

        my $connect_string = "DBI:Oracle:" . $server;
        my $dbh            = DBI->connect(
                $connect_string,
                $user,
                $password,
                {
                        PrintError => 1,
                        RaiseError => 1
                }
        );
        if ( !$dbh ) {
                my $logger->logdie(
"Invalid username/password access database server [$server] denied access to the username [$user].  Please check the username/password and confirm you have permissions to access the database server [$server]\n"
                );
        }
        return $dbh;
}


sub do_sql {
        my ( $dbproc, $query, $delimeter ) = @_;
        my ( $statementHandle, @x,      @results );
        my ( $i,               $result, @row );

        if ( $delimeter eq "" ) {
                $delimeter = ",";
        }

        $statementHandle = $dbproc->prepare($query);
        if ( !defined $statementHandle ) {
                die "Cannot prepare statement: $DBI::errstr\n";
        }
        $statementHandle->execute() || die "failed query: $query\n";
        while ( @row = $statementHandle->fetchrow() ) {
                push( @results, join( $delimeter, @row ) );
        }

        $statementHandle->finish;
        return (@results);
}

