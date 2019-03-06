#!/usr/bin/perl
use strict;
use Cwd;
use Cwd 'chdir';
use Getopt::Std;
use Data::Dumper;
use DBI;
use vars qw($opt_s $opt_u $opt_p $opt_d);
getopts('s:u:p:d:');
my $server   = "bhbdev";
if ($opt_s) {$server = $opt_s;}
my $user     = "dots";
if ($opt_u) {$user = $opt_u;}
my $password = "dots";
if ($opt_p) {$password = $opt_p;}

my $date = "";
if ($opt_d) {$date = $opt_d;}


#run blastdb first
my $cmd = "./blast_db.pl H1N1NewPand-IN-text-out-text.xml";
print "CMD:  $cmd\n";
`$cmd`;

#copy balstdb result to file_share_server:15
my $cmd = 'scp -p /tmp/.classifier/blastdb/* dbadmin@192.168.1.15:/home/public/app/brcDocs/datafiles/classifier/blastdb';
`$cmd`;

my $cmd = 'scp -p /tmp/.classifier/H1N1NewPand.cached dbadmin@192.168.1.15:/home/public/app/brcDocs/datafiles/classifier/blastdb';
`$cmd`;

my $inputFile = '/home/idaily/influenza_daily/'.$date."/data/nc_gbff/na_sid";
my $dbproc = &ConnectToDb($server, $user, $password) || die "can't connect to database server: $server\n";
$dbproc->{LongReadLen} = 100000000;

print "INPUT:$inputFile\n";
my $outFile;
  if(-e $inputFile) {
     open(FILE, "< $inputFile" )
           || die  "Cannot open file $inputFile for reading";
      while( my $line = <FILE>) {
print "LINE:$line\n";
        my @a = split (' ', $line);

        my $accession = $a[0];
        print "accession:$accession\n";

#        my $query = "select  a.string1
#            from nasequenceimp 
#            where obsolete_date is null
#            and string1 =\'$accession\'";

        my $query = "select  a.na_sequence_id, a.sequence, 
            NVL(c.autocuration_segment, 'NSEGMENT') segment, 
            NVL(c.autocuration_subtype, 'NSUBTYPE') subtype
            from nasequenceimp a, SEQUENCE_STATISTICS b, sequence_other_info c
            where a.na_sequence_id=b.na_sequence_id
            and a.obsolete_date is null and organism like 'Influenza A%'
            and a.length >1 and string1 not like 'IRD%'
            and c.na_sequence_id=a.na_sequence_id
            and a.string1 =\'$accession\'
           -- and c.is_2009_swineflu_pandemic is null
            ";
#print "SQL:$query\n";
         my @aaresults = &do_sql($dbproc, $query);
         foreach my$row (@aaresults){
           my($na_id,$seq, $segment, $subtype)=split(',', $row);
            if(-e $inputFile) {
              `rm -f $outFile`;
             }
            $outFile ="/home/idaily/influenza_daily/classifier/result/$na_id.txt";
            if(-e $inputFile) {
                `rm -f $outFile`;
            }
#           next if ($segment == 4 && $subtype ne "H1");
#           next if ($segment == 6 && $subtype ne "N1");
print "CHECK:$segment:$subtype\n";

           my $tmpFastFile = "/tmp/.classifier/$na_id.fasta";
           open(OUT, ">$tmpFastFile") || die "Can't open file:$tmpFastFile to write: $!\n"; 
           print OUT ">$na_id\n";
           print OUT $seq;
           close OUT;
           print "Accession which can be run:$na_id:$accession\n";
           if(-e $inputFile) {
                 `rm -f $outFile`;
           }
           my $cmd = "./classifier.pl H1N1NewPand-IN-text-out-text.xml $tmpFastFile $outFile";
           print "CMD:  $cmd\n";
           my $ret = `$cmd`;
           my $status = $?;
	   print "CMD status:  $status\n";
	   print "running result:$ret\n";
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
             trim($retline);
             my @a = split ('\t', $retline);
           print "\nRESULT:$a[0]:$a[1]\n";
           my $query = "MERGE into dots.sequence_other_info_0725 w
                             using (select $na_id na_id, 
                                  '$a[1]' result from dual) q
                             on (w.na_sequence_id=q.na_id)
                             WHEN MATCHED THEN
                             update set w.is_2009_swineflu_pandemic = q.result";
print "SQL:$query\n";
            &exec_sql($dbproc, $query);
           }
         }
         close(RETFILE);
       }

# update record for segment 4 and 6
#     my $query = "update sequence_other_info_0725 set is_2009_swineflu_pandemic ='NE' where na_sequence_id in (select na_sequence_id from nasequenceimp where string1 =\'$accession\' and obsolete_date is null) and autocuration_segment = \'4\' and autocuration_subtype <>\'H1\' ";
#print "SQL:$query\n";
#     &exec_sql($dbproc, $query);
#     my $query = "update sequence_other_info_0725 set is_2009_swineflu_pandemic ='NE' where na_sequence_id in (select na_sequence_id from nasequenceimp where string1 =\'$accession\' and obsolete_date is null) and autocuration_segment = \'6\' and autocuration_subtype <>\'N1\' ";
#print "SQL:$query\n";
#       &exec_sql($dbproc, $query);
#end of update
      }
     close(FILE);
   }else {
    print "Warning: no input file found!\n";

   }

exit(0);


sub do_sql {
    my($dbproc,$query,$delimeter) = @_;
    my($statementHandle,@x,@results);
    my($i,$result, @row);

    if($delimeter eq "") {
        $delimeter = ",";
    }

    $statementHandle = $dbproc->prepare($query);
    if ( !defined $statementHandle) {
        die "Cannot prepare statement: $DBI::errstr\n";
    }
    $statementHandle->execute() || die "failed query: $query\n";
    while ( @row = $statementHandle->fetchrow() ) {
          push(@results,join($delimeter,@row));
    }

    $statementHandle->finish;
    return(@results);
}


sub exec_sql {
    my($dbproc,$query,$delimeter) = @_;
    my($statementHandle,@x,@results);
    my($i,$result, @row);

    if($delimeter eq "") {
        $delimeter = ",";
    }

    $statementHandle = $dbproc->prepare($query);
    if ( !defined $statementHandle) {
        die "Cannot prepare statement: $DBI::errstr\n";
    }
    $statementHandle->execute() || die "failed query: $query\n";

    $statementHandle->finish;
    return 0;
}






sub ConnectToDb {
    my ($server, $user, $password) = @_;

    my $connect_string = "DBI:Oracle:" . $server;
    my $dbh = DBI->connect($connect_string, $user, $password,
                                 { PrintError => 1,
                                   RaiseError => 1
                                 }
                           );
    if(! $dbh){
          my  $logger->logdie("Invalid username/password access database server [$server] denied access to the username [$user].  Please check the username/password and confirm you have permissions to access the database server [$server]\n");
    }
    return $dbh;
}
#=============================================================================
# trim: space, #, : and \n from the beging and end
#=============================================================================

sub trim {
   my @out =@_;
   for (@out) {
     s/^\#//;
     s/^\_//;
     s/^\s+//;
     s/\:+$//;
     s/\n+$//;
     s/\s+$//;
     s/\_$//;
  }
  return wantarray ?@out:$out[0];
}

