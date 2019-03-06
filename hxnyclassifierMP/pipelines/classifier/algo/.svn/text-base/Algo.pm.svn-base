package algo::Algo;

use strict;
use warnings;
use util::blastf;

sub new {
  my $class = shift;
  my $self  = {@_};
  bless( $self, $class );
  $self->_init;
  return $self;
}

sub config  { my $self = shift; return $self->{config}; }
sub db_conn { my $self = shift; return $self->{db_conn}; }

###
### Initialize look up table for consistent hits.
### Hash value for lookup table is store in $self->{lookup}
###
sub _init {
  my $self = shift;

  my $config = $self->config;

  if ( !defined( $self->{blastout} ) ) {
    $self->{blastout} = 0;
  }

  my $hits = 3;
  if ( defined( $self->{count} ) ) {
    $hits = $self->{count};
  }

  $self->{lookup} = util::blastf::getLookupTable( $config, $self->db_conn );

  $self->{blastdb} =
    join( '/', $config->getValue("blastdir"), $config->getValue("blastdb") );

  $self->{formatdb} =
    join( ' ', $config->getValue("formatdb"), "-p F -o T -i",
    $self->{blastdb} );

  $self->{blastall} = join( ' ',
    $config->getValue("blastall"),
    "-p blastn -m 8 -e 1 -F F -v $hits -b $hits -g F -d",
    $self->{blastdb}, "-i <INPUTFILE>" );

  $self->{classifierDir} = join( '/',
    $config->getValue("TempDir"),
    $config->getValue("ClassifierDir") );

  $self->{taxit} = join( ' ',
    $config->getValue("taxit"),
    "create -l",
    $config->getValue("Type"),
    "-P",
    $config->getValue("HRefpkg"),
    "--aln-fasta",
    $config->getValue("HAlign"),
    "--tree-stats",
    join( '/', $self->{classifierDir}, $config->getValue("HStat") ),
    "--tree-file",
    join( '/', $self->{classifierDir}, $config->getValue("HTree") ) );

  $self->{pplacer} = join( ' ',
    $config->getValue("pplacer") . "/pplacer",
    "-c", $config->getValue("HRefpkg"), "--out-dir" );

  $self->{guppy} = join( ' ', $config->getValue("pplacer") . "/guppy", "tog" );

  $self->{node_lookup} = join( '/',
    $config->getValue("TempDir"),
    $config->getValue("ClassifierDir"),
    $config->getValue("Node_lookup") );

  $self->{lower_threshold} = $config->getValue("Lower_Threshold");
  $self->{upper_threshold} = $config->getValue("Upper_Threshold");

  $self->{input_fasta} =
    join( '/', $self->{classifierDir}, $config->getValue("blastdb") );
}

sub taxit {
  my $self = shift;
  my ($accession) = @_;

  my $refpkg = $self->config->getValue("HRefpkg");
  if ( -e $refpkg ) {
    system("/bin/rm -fr $refpkg");
    my $status = $?;
    die "Could not remove reference package for $accession ($status)\n"
      if ($status);
  }
  my $taxit =
    $self->{taxit} . " > $accession.taxit.std 2> $accession.taxit.err";
  print "$accession = $taxit\n";
  system("$taxit");
  my $status = $?;
  die "Failed to run taxit for $accession ($status)\n" if ($status);
}

sub blastdb {
  my $self = shift;
  my ($accession) = @_;

  my $blastdb    = $self->{blastdb};
  my $inputFasta = $self->{input_fasta};

  my $blastdir = $self->config->getValue("blastdir");
  if ( -e $blastdir ) {
    system("/bin/rm -fr $blastdir");
    my $status = $?;
    die "Could not remove blastdir for $accession ($status)\n"
      if ($status);
  }
  system("mkdir -p -m 0775 $blastdir");

  open( LOG, ">> $blastdb.log" )
    or die "Couldn't able to open the log file: $blastdb.log\n";
  print LOG "Created blastdir ($blastdir).\t\t" . localtime() . "\n";

  print LOG "Copying blastdb ($inputFasta to $blastdb).\t\t"
    . localtime() . "\n";
  system("cp $inputFasta $blastdb");

  print LOG "Running formatdb on $blastdb.\t\t" . localtime() . "\n";
  my $formatdbCmd =
    $self->{formatdb} . " > $accession.formatdb.std 2> $accession.formatdb.err";
  system($formatdbCmd);
  my $status = $?;
  die "Failed to run formatdb for $accession ($status)\n" if ($status);
  print LOG "Finished formatdb on $blastdb.\t\t" . localtime() . "\n";
  close(LOG);
}

sub tree {
  my $self = shift;
  my ( $accession, $seq ) = @_;

  my $sequenceFile = "$accession.fasta";
  open( SEQ, ">$sequenceFile" ) or die "Unable to open $sequenceFile:  $@\n";
  print SEQ ">$accession\n";
  print SEQ "$seq";
  close SEQ;

  my $guppyCmd   = $self->{guppy};
  my $pplacerCmd = $self->{pplacer};

  $pplacerCmd .=
    " . $sequenceFile > $accession.pplacer.std 2> $accession.pplacer.err";
  print "$pplacerCmd\n";
  system($pplacerCmd);
  my $status = $?;
  die "Failed to run pplacer for $accession ($status)\n" if ($status);

  $sequenceFile =~ s/\.fasta$/.jplace/;
  my $treeData = "";
  if ( -e $sequenceFile ) {
    $guppyCmd .=
      " $sequenceFile > $accession.guppy.std 2> $accession.guppy.err";
    print "$guppyCmd\n";
    system($guppyCmd);
    my $status = $?;
    die "Failed to run guppy for $accession ($status)\n" if ($status);
    $sequenceFile =~ s/\.jplace$/.tog.tre/;
    if ( !-e $sequenceFile ) {
      warn "$accession Accession guppy error\n";
    }
    else {
      ###
      ### The the unified tree
      ###
      open( TREEDATA, "<$sequenceFile" )
        or die "Unable to open $sequenceFile:  $@\n";
      while (<TREEDATA>) {
        chomp $_;
        $treeData .= $_;
      }
      close TREEDATA;
    }
  }
  else {
    warn "$accession Accession pplacer error\n";
  }
  if ( -e $sequenceFile ) {
    return ( $sequenceFile, $treeData );
  }
  else {
    return ( undef, undef );
  }
}

sub getLookup {
  my $self = shift;
  my ($accession) = @_;
  return $self->{lookup}->{$accession};
}

sub getClassification {
  my $self = shift;
  my (@params) = @_;
  #######################
  ### Abstract Method ###
  #######################
  return undef;
}

1;
