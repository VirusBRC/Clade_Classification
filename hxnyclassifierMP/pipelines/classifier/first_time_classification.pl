#!/usr/bin/perl 

use db::DB_Handler;
use config::Config_Reader;
use algo::H1N1NewPand;
use util::Utils;

my $DB = 1;
my $configFile = $ARGV[0];

unless(defined $configFile && -e $configFile){
    warn "Usage: perl classifier [configuration file]";
    exit(1);
}

my $config = config::Config_Reader->new(fileName=>$configFile);

my $dbConn = db::DB_Handler->new(
    "db_name" => $config->getValue(uc("db_name")),
    "db_host" => $config->getValue(uc("db_host")),
    "db_user" => $config->getValue(uc("db_user")),
    "db_platform" => $config->getValue(uc("db_platform")),
    "db_pass" => $config->getValue(uc("db_password")),
    "db_debug" => "0"
);

my $fluType = $config->getValue("flutype");
my $seroType = $config->getValue("serotype");
my $seg = $config->getValue("seg");
my $type = $config->getValue("Type");
$DB= ($config->getValue("output") eq 'text') ? 0:1;



my $whereClause ;
my $class = "algo::$type";

if ( $type eq "H1N1NewPand" ) {

    $whereClause = " where  flutype = '$fluType' and serotype = '$seroType' ";

}


my $sequenceSql = "select sequence, isdid from sequence $whereClause" if defined $whereClause; 

my @resultRow = @{$dbConn->getResult($sequenceSql)};

my $blastout = 0;

my $classifier =  $class->new(config=>$config,
                                db_conn=>$dbConn,
                                blastout=>$blastout,
                                count=>3); 



my $classifierDir = $config->getValue("TempDir")."/".$config->getValue("ClassifierDir");


open LOG,">>$classifierDir/classification.$type.log" or die "Cannot open log file. \t $classifierDir/classification.$type.log";

my $tempFile = "$classifierDir/$$.tmp";
my $size = scalar(@resultRow);


print LOG "Running first time classifier for $type- ".localtime()."\n";
print LOG "Total number of sequences: $size \n";

foreach my $row (@resultRow){

    my $seq = util::Utils::trim($row->[0]);
    my $isdid = $row->[1];

    if ($seq eq "" ){
        print LOG "-------- Empty in SEQ ----------\n";
        print LOG "Accession number: $isdid\n";
        print LOG "Seq: $seq\n";
        print LOG "-------------------------------\n";
        next;
    }

    open SEQ,">$tempFile";
    print SEQ "$seq";
    close SEQ;
    
   
    my $classification = $classifier->getClassification($tempFile);
    my $accession = $row->[2];

    my $sql = "SELECT up_metadata($isdid,'".lc($type)."','$classification')";

    print "ISDID:\t$isdid\t\tClassification:\t$classification\n" if !$DB;


    eval{
        $dbConn->setResult($sql) if $DB;
        print LOG "isdid:$isdid\tclassification:$classification\n" if $DB;

    };

    if($@){
        
        print LOG "-------- ERROR in DB ----------\n";
        print LOG "$isdid\t $seq\n";
        print LOG "$@";
        print LOG "-------------------------------\n";
    }
}

unlink($tempFile);
