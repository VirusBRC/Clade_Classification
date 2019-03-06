#!/usr/bin/perl 

use strict;
use warnings;
use Carp;
use config::Config_Reader;
use Data::Dumper;
use db::DB_Handler;


my $configFile =  $ARGV[0];
if (!defined($configFile)) {
  croak "Usage: perl blast_db.pl [config file]\n";
}
if (!-e $configFile) {
  croak "Invalid configuration file $configFile\n";
}
my $conf = config::Config_Reader->new(fileName => $configFile);

my $tempdir = $conf->getValue("TempDir");
my $classifierDir = $tempdir . $conf->getValue("ClassifierDir");
if (!-d $classifierDir){
  croak "ClassifierDir does not exist $classifierDir\n";
}
my $blastdir  = join('/', $classifierDir, $conf->getValue("blastdir"));
my $blastdb   = $conf->getValue("blastdb");
my $blastfile = join('/', $blastdir, $blastdb);
`mkdir -p $blastdir`;

open LOG,">> $blastdir/$blastdb.log"
  or die "ERROR:  NOT able to open the log file: $blastdir/$blastdb.log\n";

my $dbCon
  = db::DB_Handler->new(
    "db_name"     => $conf->getValue("DB_NAME"),
    "db_host"     => $conf->getValue("DB_HOST"),
    "db_user"     => $conf->getValue("DB_USER"),
    "db_platform" => $conf->getValue("DB_PLATFORM"),
    "db_pass"     => $conf->getValue("DB_PASSWORD"),
    "db_debug"    => "1");
my $BLASTSET = $conf->getValue("Type"); 

my $sql = "
SELECT STRING1 ACCESSION,
       SEQUENCE FROM NASEQUENCEIMP
WHERE  STRING1 IN
         (SELECT ACCESSION
          FROM   BLAST_INFO
          WHERE BLASTSET = '$BLASTSET')
AND    OBSOLETE_DATE IS NULL
";
print LOG "Getting sequences from data base.\t\t".localtime()."\n";

my @result = @{$dbCon->getResult($sql)};

print LOG "Opening temp blast file. \t\t".localtime()."\n";

my $tempFile = $blastdir."/$blastdb.tmp";
open TMPBLAST,">$tempFile"
  or die "Couldn't open $tempFile \n";
foreach my $row (@result){
  my $isdid = $row->[0];
  my $sequence =$row->[1];
  print TMPBLAST ">$isdid /1-" . (length($sequence)) . "\n";
  print TMPBLAST "$sequence\n";
}
close TMPBLAST;
rename($tempFile,$blastfile);

print LOG "Running formatdb on $blastfile.\t\t".localtime()."\n";
my $formatdbcmd = "nice formatdb -i $blastfile -p F -o T ";
system($formatdbcmd);
print LOG "Completed formatdb on $blastfile.\t\t".localtime()."\n";

close(LOG);
exit(0);
