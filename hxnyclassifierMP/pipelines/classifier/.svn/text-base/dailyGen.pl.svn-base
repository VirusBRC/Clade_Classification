#!/usr/bin/perl
use strict;
use Cwd;
use Cwd 'chdir';
use Getopt::Std;
use Data::Dumper;
use DBI;
use File::Basename;

use vars qw($opt_s $opt_u $opt_p $opt_f);
getopts('s:u:p:f:');

my $TMP_DIR = "/var/tmp/classifier";
system("/bin/rm -rf $TMP_DIR");
system("mkdir -p $TMP_DIR");

my $toolName = basename($0);
my $usage = "$toolName -u username -p password -s server -f na_sid_file";

my $server = "";
if ($opt_s) {
  $server = $opt_s;
} else {
  die " MISSING -s server\n$usage";
}
my $user = "";
if ($opt_u) {
  $user = $opt_u;
} else {
  die " MISSING -u username\n$usage";
}

my $password = "";
if ($opt_p) {
  $password = $opt_p;
} else {
  die " MISSING -p password\n$usage";
}

my $file = "";
if ($opt_f) {
  $file = $opt_f;
} else {
  die " MISSING -f na_sid_file\n$usage";
}
#
# run blastdb first
#
my $cmd = "./blast_db.pl H1N1NewPand-IN-text-out-text.xml";
print "CMD:  $cmd\n";
`$cmd`;

my $dbproc = &ConnectToDb($server, $user, $password)
  || die "can't connect to database server: $server\n";
$dbproc->{LongReadLen} = 100000000;

print "INPUT:$file\n";
my $outFile ="/home/idaily/influenza_daily/classifier/Output.txt";
if(-e $file) {
  `rm -f $outFile`;
}
if(-e $file) {
   open(FILE, "< $file" )
     || die  "Cannot open file $file for reading";
    while( my $line = <FILE>) {
      print "LINE:$line\n";
      my @a = split (' ', $line);
      my $accession = $a[0];
      print "accession:$accession\n";

      my $query = "
SELECT a.NA_SEQUENCE_ID,
       a.SEQUENCE, 
       NVL(c.AUTOCURATION_SEGMENT, 'NSEGMENT') SEGMENT, 
       NVL(c.AUTOCURATION_SUBTYPE, 'NSUBTYPE') SUBTYPE
FROM   NASEQUENCEIMP       a, 
       SEQUENCE_STATISTICS b,
       SEQUENCE_OTHER_INFO c
WHERE  a.NA_SEQUENCE_ID   = b.NA_SEQUENCE_ID
AND    c.NA_SEQUENCE_ID   = b.NA_SEQUENCE_ID
AND    a.OBSOLETE_DATE    IS NULL
AND    b.ORGANISM         LIKE 'Influenza A%'
AND    a.LENGTH           > 1 
AND    a.STRING1          NOT LIKE 'IRD%'
AND    a.STRING1          = '$accession'
";
###-- and c.is_2009_swineflu_pandemic is null
    print "SQL:$query\n";
    my @results = &do_sql($dbproc, $query);
    foreach my$row (@results) {
      my($na_id, $seq, $segment, $subtype) =split (',', $row);
      next if ($segment == 4 && $subtype ne "H1");
      next if ($segment == 6 && $subtype ne "N1");
      print "CHECK:$segment:$subtype\n";
      my $tmpFastFile = "$TMP_DIR/$na_id.fasta";
      open(OUT, ">$tmpFastFile") || die "Can't open file:$tmpFastFile to write: $!\n"; 
      print OUT ">$na_id\n";
      print OUT $seq;
      close OUT;
      print "Accession which can be run:$na_id:$accession\n";
      if(-e $file) {
        `rm -f $outFile`;
      }
      my $cmd = "./classifier.pl H1N1NewPand-IN-text-out-text.xml $tmpFastFile $outFile";
      print "CMD:  $cmd\n";
      `$cmd`;
      my $status = $?;
      print "CMD status:  $status\n";
      if (!-e $outFile || -z $outFile) {
        print "WARNING:  no sequences for $accession, skipping\n";
        next;
      }
      open(RETFILE, "<$outFile")
        || die  "Cannot open file $outFile for reading";
      my $lineCnt =0;
      while( my $retline = <RETFILE>) {
        $lineCnt++;
        if ($lineCnt ==1) {
          chomp($retline);
          $retline = trim($retline);
          my @a = split ('\t', $retline);
         print "\nRESULT:$a[0]:$a[1]\n";
         my $query = "
MERGE INTO DOTS.SEQUENCE_OTHER_INFO w
USING (SELECT $na_id  NA_ID,
              '$a[1]' RESULT 
       FROM   dual) q
ON    (w.NA_SEQUENCE_ID = q.NA_ID)
WHEN MATCHED THEN
  UPDATE SET w.IS_2009_SWINEFLU_PANDEMIC = q.RESULT
";
          print "SQL:$query\n";
          &exec_sql($dbproc, $query);
        }
      }
      close(RETFILE);
    }
    #
    # update record for segment 4 and 6
    #
    my $query = "
UPDATE SEQUENCE_OTHER_INFO 
SET    IS_2009_SWINEFLU_PANDEMIC ='NE' 
WHERE  NA_SEQUENCE_ID IN 
         (SELECT NA_SEQUENCE_ID 
          FROM   NASEQUENCEIMP 
          WHERE  STRING1       = '$accession'
          AND    OBSOLETE_DATE IS NULL)
AND    AUTOCURATION_SEGMENT = '4' 
AND    AUTOCURATION_SUBTYPE <>'H1'
";
    print "SQL:$query\n";
    &exec_sql($dbproc, $query);

    my $query = "
UPDATE SEQUENCE_OTHER_INFO 
SET    IS_2009_SWINEFLU_PANDEMIC ='NE' 
WHERE  NA_SEQUENCE_ID IN 
         (SELECT NA_SEQUENCE_ID 
          FROM   NASEQUENCEIMP 
          WHERE  STRING1       = '$accession'
          AND    OBSOLETE_DATE IS NULL)
AND    AUTOCURATION_SEGMENT = '6'
AND    AUTOCURATION_SUBTYPE <>'N1'
";
      print "SQL:$query\n";
      &exec_sql($dbproc, $query);
      #
      #end of update
      #
    }
   close(FILE);
} else {
    print "Warning: no input file found!\n";
}
exit(0);


sub do_sql {
  my ( $dbproc, $query, $delimiter ) = @_;

  if ( !defined($delimiter) || $delimiter eq "" ) {
    $delimiter = ",";
  }

  my $statementHandle = $dbproc->prepare($query);
  if ( !defined $statementHandle ) {
    die "Cannot prepare statement: $DBI::errstr\n";
  }
  $statementHandle->execute() || die "failed query: $query\n";
  my @results = ();
  while ( my @row = $statementHandle->fetchrow() ) {
    push( @results, join( $delimiter, @row ) );
  }
  $statementHandle->finish;
  return (@results);
}

sub exec_sql {
  my ( $dbproc, $query ) = @_;

  my $statementHandle = $dbproc->prepare($query);
  if ( !defined $statementHandle ) {
    die "Cannot prepare statement: $DBI::errstr\n";
  }
  $statementHandle->execute() || die "failed query: $query\n";

  $statementHandle->finish;
  return 0;
}

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
"Invalid username/password access database server [$server] denied access to the username [$user].\nPlease check the username/password and confirm you have permissions to access the database server [$server]\n"
    );
  }
  return $dbh;
}

#=============================================================================
# trim: space, #, : and \n from the beging and end
#=============================================================================

sub trim {
 my (@out) = @_;
 for (@out) {
   s/^\#//;
   s/^\_//;
   s/^\s+//;
   s/\:+$//;
   s/\n+$//;
   s/\s+$//;
   s/\_$//;
 }
  return wantarray ? @out : $out[0];
}

