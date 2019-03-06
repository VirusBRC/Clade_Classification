#!/usr/bin/perl

use strict;
use warnings;
use util::Utils;
use XML::Xml_Writer;


print "\nThis utility can be used to generate configuration file for Classifier.\n
Entern 'q' or 'Q' for quit. 
Fields: 
* Data base - Database name, platform, user, password and host.
*			----------	
*			 DEFAULTS
*			----------
* Blast - blastall 
* FormtDB - formatdb 
* PPlacer - pplacer 
* Temp directory - /tmp 
* Classifer type ( H1N1 , H5N1 classifier ) - H1N1
* Sequence Query parameter - 
*	H1N1 - Flutype - A, Serotype = H1N1 
* 	H5N1 - ? 

\n";



my %dbMap = (

		"DB_PLATFORM" => "",
		"DB_HOST" => "",
		"DB_NAME" => "",
		"DB_USER" => "",
		"DB_PASSWORD" => ""
	    );

my %binaryFiles = (
		"blastall" => "blastall",
		"pplacer" => "pplacer",
		"formatdb" => "formatdb"
		);

my %seqQuery = (
		"flutype" => "A",
		"serotype" => "H1N1",
		"seg" => "seg8"
	       );

my $type = undef;
my $temp_dir = "/tmp/";
my %xmlMap =();


SWITCH: {

		$type = _Read_Input(" Classification type: \n	1 - H1N1NewPand \n	2 - H5N1 \n	 ");
		$type eq "1" && do {$type="H1N1NewPand"; last SWITCH;};
		$type eq "2" && do {$type="H5N1"; last SWITCH;};
		print "\nYou have entered wrong classifier type!.\n"; 
		redo SWITCH;
	}

$xmlMap{"Type"} = $type;

print "\n\t--------------------\n
database information.\n
--------------------\n";
foreach my $k (keys( %dbMap )){

LOOP: {
	      my $temp = _Read_Input("$k : ");

	      if ( $temp eq "" ){
		      print "field cann't be empty.\n";
		      redo LOOP;
	      } 
	      $xmlMap {$k} = $temp;
      }
}
print "\n\t--------------------------------\n
Binary file location information. \n 
For default - leave blank \n
--------------------------------\n";

foreach my $k (keys (%binaryFiles)){
	my $temp = _Read_Input("path for $k: ");
	if ($temp ne "" && -e $temp){
		$binaryFiles{$k} = $temp;
	}

	$xmlMap{$k}=$binaryFiles{$k};
}


print "\n\t--------------------------------\n
Sequence query parameter. \n 
For default - leave blank \n
--------------------------------\n";

foreach my $k (keys (%seqQuery)){
	my $temp = _Read_Input(" value $k: ");
	if ($temp ne "" && -e $temp){
		$seqQuery{$k} = $temp;
	}

	$xmlMap{$k}=$seqQuery{$k};
}

$temp_dir = _Read_Input(" temp directory (blank for default):\t ");

if( !($temp_dir ne "" &&  -e $temp_dir)){
	$temp_dir = "/tmp/";
}

$xmlMap{"TempDir"}=$temp_dir;

my $tmp = _Read_Input(" Blast db directory (blank for default):\t");

my $blastdir = "blastdb";

unless($tmp eq ""){
	$blastdir = $tmp;
}

$xmlMap{"blastdir"}=$blastdir;


my $blastdb = "$type.fasta" ;


$xmlMap{"blastdb"}=$blastdb;

$tmp = _Read_Input(" Input method\n\t0:\ttext\n\t1:\tdata base\n\t(blank for default Data base):\t");
my $input = "DB";

if($tmp eq "0" || $tmp eq "1"){
	$input = ($tmp eq "0") ? "text" : "DB";
}

$xmlMap{"input"}=$input;

$tmp = _Read_Input(" Output method\n\t0:\ttext\n\t1:\tdata base\n\t(blank for default Data base):\t");

my $output = "DB";

if($tmp eq "0" || $tmp eq "1"){
	$output = ($tmp eq "0") ? "text" : "DB";
}


my $lookupFile = _Read_Input(" Lookup file path (blank for default):\t");

$xmlMap{"lookupfile"} = $lookupFile;



$xmlMap{"output"}=$output;

$xmlMap{"ClassifierDir"} = ".classifier";



my $CONFIG_FILE = uc($dbMap{"DB_HOST"})."$type-IN-$input-out-$output.xml";

my $xml = XML::Xml_Writer->new(
		"fileName" => $CONFIG_FILE
		);


$xml->writeXML(\%xmlMap);

sub _Read_Input{

	my $msg = shift;
	print "Please enter ",$msg;
	my $input = <>;
	$input = util::Utils::trim($input);

	if ($input eq "q" || $input eq"Q"){
		exit 0;
	}
	return $input;
}


