#!/usr/bin/perl 

use db::DB_Handler;
use config::Config_Reader;
use algo::H1N1NewPand;
use util::Utils;
use Data::Dumper;

my $configFile = $ARGV[0];
if (!defined($configFile) || !-e $configFile){
  warn "USAGE: perl classifier [configuration file]\n";
  exit(1);
}

my $config = config::Config_Reader->new(fileName=>$configFile);
my $OUT    = $config->getValue("output");
my $IN     = $config->getValue("input");

if($IN eq "text" ){
  if (!defined($ARGV[1]) || !-f $ARGV[1]) {
    warn "USAGE: perl classifier [configuration file] [input sequence file fasta]\n";
    exit(1);
  }
}
my $inputFile = undef;
if ( defined($ARGV[1]) ) {
    $inputFile = $ARGV[1];
}

my $outputfile = undef;
if($OUT eq "text" && defined($ARGV[2])) {
  $outputfile = $ARGV[2];
} 

my $dbConn = undef;
if ($IN eq "DB" || $OUT eq "DB") {
  $dbConn = 
    db::DB_Handler->new(
	"db_name"     => $config->getValue(uc("DB_NAME")),
	"db_host"     => $config->getValue(uc("DB_HOST")),
	"db_user"     => $config->getValue(uc("DB_USER")),
	"db_platform" => $config->getValue(uc("DB_PLATFORM")),
	"db_pass"     => $config->getValue(uc("DB_PASSWORD")),
	"db_debug"    => "0");
}

my $blastout   = 0;
my $fluType    = $config->getValue("flutype");
my $seroType   = $config->getValue("serotype");
my $seg        = $config->getValue("seg");
my $type       = $config->getValue("Type");
my $lookupfile = $config->getValue("lookupfile");

my $class = "algo::$type";
my $classifier =
  $class->new(config   => $config,
	      db_conn  => $dbConn,
	      blastout => $blastout,
	      count    => 3); 

my $classifierDir =
  join('',
       $config->getValue("TempDir"),
       $config->getValue("ClassifierDir"));

open (LOG, ">>$classifierDir/classification.$type.log")
  or die "Cannot open log file. \t $classifierDir/classification.$type.log";
my $tempFile = "$classifierDir/$$.tmp";

print LOG "Classifier - $type ".localtime()."\n";

my $ltype       = lc($type);
my $sequenceSql = "
SELECT ISDID, 
       SEQUENCE
FROM   SEQUENCE 
WHERE  ISDID IN 
         (SELECT ISDID
          FROM   TEMP_SEQUENCE
          WHERE  C_TYPE = '$ltype')
";
my @resultRow = ();
eval{
  if ($IN eq "DB") {
    @resultRow = @{$dbConn->getResult($sequenceSql)};
  } else {
    @resultRow = @{util::Utils::getSequenceFromFasta($inputFile)};
  }
};
if($@){
  warn "ERROR in collection of result. $@";
  exit(1);
}

print LOG "Input Info: $fluType:$seroType:$seq:$type:$lookupfile\n"; 
print "Input Info: $fluType:$seroType:$seq:$type:$lookupfile\n"; 
print LOG "RESULT: ";
print LOG Dumper(@resultRow) . "\n";
print "RESULT: ";
print Dumper(@resultRow) . "\n";

my $size = scalar @resultRow;
print LOG "Total number of sequences: $size \n";
my $OUTFILE;

if(defined($outputfile)) {
  open($OUTFILE,">$outputfile")
    or warn "Cannot open outputfile";
}

foreach my $row (@resultRow){
  my $isdid = $row->[0];
  my $seq = util::Utils::trim($row->[1]);
  if ($seq eq "" ){
    print LOG "-------- Empty SEQ ----------\n";
    print LOG "Accession number: $isdid\n";
    print LOG "-------------------------------\n";
    next;
  }

  open(SEQ, ">$tempFile");
  print SEQ "$seq";
  close(SEQ);

  print "\n" if ($blastout);
  my $classification = $classifier->getClassification($tempFile);
  if ($OUT eq "text" && !defined $OUTFILE) {
    print "ISDID:\t$isdid\t\tClassification:\t$classification\n";
  }
  if (defined $OUTFILE) {
    print $OUTFILE "$isdid\t$classification\n";
  }

  if ($OUT eq "DB") {
    my $sql = "
SELECT UP_METADATA($isdid,$ltype,'$ltype','$classification')
";
    eval{
	$dbConn->setResult($sql);
	print LOG "isdid:$isdid\tclassification:$classification\n";
    };
    if($@){
	print LOG "-------- ERROR in DB ----------\n";
	print LOG "$isdid\t $seq\n";
	print LOG "$@";
	print LOG "-------------------------------\n";
    }
  }
}

if ($OUT eq "DB") {
  $dbConn->setResult("DELETE FROM TEMP_SEQUENCE WHERE C_TYPE='$ltype'");
  $dbConn->close();
}
close LOG;
unlink($tempFile);


