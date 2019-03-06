package ncbi::H5N1Classifier;
######################################################################
#                  Copyright (c) 2012 Northrop Grumman.
#                          All rights reserved.
######################################################################

use strict;

use File::Basename;
use Cwd 'chdir';
use Pod::Usage;

use Bio::SeqIO;

use ncbi::ErrMsgs;
use ncbi::Loader;

use parallel::Jobs;
use parallel::PidInfo;
use parallel::Query;

use util::ConfigParams;
use util::Constants;
use util::PathSpecifics;
use util::Statistics;

use POSIX ":sys_wait_h";

use fields qw(
  accs
  counts
  continents
  countries
  country_continent
  data
  error_mgr
  error_status
  jobs
  last_job
  ncbi_utils
  next_job
  pids
  profile
  profile_clade
  run_dir
  tools
  utils
  unique_id
);

################################################################################
#
#			            Static Class Constants
#
################################################################################
###
### File types
###
sub FASTA_TYPE      { return 'fasta'; }
sub LOOKUP_TYPE     { return 'lookup'; }
sub PROPERTIES_TYPE { return 'properties'; }
sub STATS_TYPE      { return 'stats'; }
sub TREE_TYPE       { return 'tree'; }
###
### Status Types
###
sub CLUSTALW_TYPE   { return 'clustalw'; }
sub CLASSIFIER_TYPE { return 'classifier'; }

sub STATUS_TYPES { return ( CLUSTALW_TYPE, CLASSIFIER_TYPE ); }
###
###
###
sub DISPOSITION_TAG { return 'Disposition'; }

sub REFERENCE_VAL         { return 'reference'; }
sub FAILED_CLUSTALW_VAL   { return 'failed clustalw'; }
sub FAILED_CLASSIFIER_VAL { return 'failed classifier'; }
sub CLASSIFIED_VAL        { return 'classified'; }

sub DISPOSITION_VALS {
  return [
    REFERENCE_VAL,         FAILED_CLUSTALW_VAL,
    FAILED_CLASSIFIER_VAL, CLASSIFIED_VAL,
  ];
}
###
### Queries
###
sub SEQID_QUERY  { return 'seqMrkrSeqIdQuery'; }
sub UPDATE_QUERY { return 'updateQuery'; }
###
### Query Specific Properties from its Configuration
###
sub MAXELEMENTS_PROP     { return 'maxElements'; }
sub QUERYPARAMSUBS_PROP  { return 'queryParamSubs'; }
sub QUERYPARAMS_PROP     { return 'queryParams'; }
sub QUERYPREDICATES_PROP { return 'queryPredicates'; }
sub QUERYRESULTSORD_PROP { return 'queryResultsOrd'; }
sub QUERY_PROP           { return 'query'; }

sub QUERY_PROPERTIES {
  return [
    MAXELEMENTS_PROP,     QUERYPARAMSUBS_PROP,  QUERYPARAMS_PROP,
    QUERYPREDICATES_PROP, QUERYRESULTSORD_PROP, QUERY_PROP,
  ];
}
###
###  Unique ID suffix
###
sub UNIQUE_ID_START { return 100000; }
###
### Error Category
###
sub ERR_CAT { return ncbi::ErrMsgs::HXNYCLASSIFIER_CAT; }

################################################################################
#
#				   Private Methods
#
################################################################################

sub _getUniqueAccession {
  my ncbi::H5N1Classifier $this = shift;

  my $ncbi_utils = $this->{ncbi_utils};
  my $properties = $ncbi_utils->getProperties;

  $this->{unique_id}++;
  return uc( $properties->{datasetName} ) . $this->{unique_id};
}

sub _getCountryContinents {
  my ncbi::H5N1Classifier $this = shift;

  $this->{continents}        = {};
  $this->{countries}         = {};
  $this->{country_continent} = {};

  my $ncbi_utils = $this->{ncbi_utils};
  my $utils      = $this->{utils};
  my $serializer = $this->{tools}->serializer;
  my $properties = $ncbi_utils->getProperties;
  ###
  ### All sequences are processed if from fast file
  ###
  return if ( $properties->{fasta} );

  my $continentQuery = $properties->{continentQuery};
  my $countries      = $properties->{countries};
  my $continents     = $properties->{continents};

  if ( !util::Constants::EMPTY_LINE($countries)
    && ref($countries) eq $serializer->ARRAY_TYPE )
  {
    foreach my $country ( @{$countries} ) {
      $country = lc( strip_whitespace($country) );
      $this->{error_mgr}->printMsg("Added country = $country");
      $this->{countries}->{$country} = util::Constants::EMPTY_STR;
    }
  }
  if ( !util::Constants::EMPTY_LINE($continents)
    && ref($continents) eq $serializer->ARRAY_TYPE )
  {
    foreach my $continent ( @{$continents} ) {
      $continent = lc( strip_whitespace($continent) );
      $this->{error_mgr}->printMsg("Added continent = $continent");
      $this->{continents}->{$continent} = util::Constants::EMPTY_STR;
    }
  }

  my $query = new parallel::Query( undef, $this->{error_mgr}, $this->{tools} );
  my @data = $query->getData($continentQuery);
  $this->{error_mgr}->exitProgram( ERR_CAT, 1, [ $continentQuery->{query}, ],
    $query->getErrorStatus );
  return if $query->getErrorStatus;

  foreach my $struct (@data) {
    my $country   = lc( strip_whitespace( $struct->{country} ) );
    my $continent = lc( strip_whitespace( $struct->{continent} ) );
    $this->{error_mgr}
      ->printMsg("Added (country, continent) = ($country, $continent)");
    $this->{country_continent}->{$country} = $continent;
  }
}

sub _filterData {
  my ncbi::H5N1Classifier $this = shift;
  my (@data) = @_;

  my $countries         = $this->{countries};
  my $continents        = $this->{continents};
  my $country_continent = $this->{country_continent};

  my $allData =
    ( scalar keys %{$countries} == 0 && scalar keys %{$continents} == 0 )
    ? util::Constants::TRUE
    : util::Constants::FALSE;

  my @fdata = ();
  foreach my $struct (@data) {
    my $acc     = $struct->{gb_accession};
    my $country = lc( strip_whitespace( $struct->{country} ) );
    $struct->{seq} =~ s/~/-/g;
    if ($allData) {
      $this->{error_mgr}->printMsg("Added accession for all data ($acc)");
      push( @fdata, $struct );
      next;
    }
    elsif ( defined( $countries->{$country} ) ) {
      $this->{error_mgr}
        ->printMsg("Added accession for country ($acc, $country)");
      push( @fdata, $struct );
      next;
    }
    my $continent = $country_continent->{$country};
    next if ( !defined($continent) );
    if ( defined( $continents->{$continent} ) ) {
      $this->{error_mgr}
        ->printMsg("Added accession for continent ($acc, $continent)");
      push( @fdata, $struct );
      next;
    }
  }
  return @fdata;
}

sub _getNaSeqIds {
  my ncbi::H5N1Classifier $this = shift;

  my $ncbi_utils = $this->{ncbi_utils};
  my $utils      = $this->{utils};
  my $properties = $ncbi_utils->getProperties;

  my $fastaFile     = $properties->{fastaFile};
  my $naSequenceIds = $properties->{naSequenceIds};
  my $naSidFile     = $properties->{naSidFile};

  if ( $properties->{fasta} ) {
    return if ( !-s $fastaFile );
    my $fh = $utils->openFile( $fastaFile, '<' );
    my $fastaSeq = new Bio::SeqIO( -fh => $fh, -format => FASTA_TYPE );
    while ( my $seq = $fastaSeq->next_seq ) {
      my $defline      = $seq->display_id;
      my $gb_accession = $defline;
      if ( $defline !~ /^[a-z0-9.]+$/i ) {
        $gb_accession = $this->_getUniqueAccession;
      }
      my $struct = {
        defline      => $defline,
        gb_accession => $gb_accession,
        seq          => $seq->seq,
      };
      push( @{$naSequenceIds}, $struct );
    }
    $fh->close;
  }
  elsif ( $properties->{allSeqs} ) {
    my $query =
      new parallel::Query( undef, $this->{error_mgr}, $this->{tools} );
    my $lproperties = { %{$properties} };
    foreach my $property ( keys %{ $properties->{allNaSequenceIdsQuery} } ) {
      $lproperties->{$property} =
        $properties->{allNaSequenceIdsQuery}->{$property};
    }
    my @data = $query->getData($lproperties);
    $this->{error_mgr}->exitProgram( ERR_CAT, 1, [ $lproperties->{query}, ],
      $query->getErrorStatus );
    $this->{error_mgr}->printHeader( "all seqs = " . scalar @data );
    foreach my $struct (@data) {
      push( @{$naSequenceIds}, $struct->{na_sequence_id} );
    }
  }
  else {
    my $file = join( util::Constants::SLASH,
      $ncbi_utils->getDataDirectory,
      $naSidFile->{file}
    );
    return if ( !-s $file );
    my $fh = $utils->openFile( $file, '<' );
    my $separator = $naSidFile->{separator};
    while ( !$fh->eof ) {
      my $line = $fh->getline;
      chomp($line);
      my @row = split( /$separator/, $line );
      my $struct = {};
      foreach my $index ( 0 .. $#{ $naSidFile->{cols} } ) {
        $struct->{ $naSidFile->{cols}->[$index] } = $row[$index];
      }
      push( @{$naSequenceIds}, $struct->{na_sequence_id} );
    }
    $fh->close;
  }
}

sub _getData {
  my ncbi::H5N1Classifier $this = shift;

  my $ncbi_utils = $this->{ncbi_utils};
  my $properties = $ncbi_utils->getProperties;
  ###
  ### return immediately if fasta file is being used
  ###
  return @{ $properties->{naSequenceIds} }
    if ( $properties->{fasta} );

  my $query = new parallel::Query( undef, $this->{error_mgr}, $this->{tools} );
  my $lproperties = { %{$properties} };
  foreach my $property ( keys %{ $properties->{selectQuery} } ) {
    $lproperties->{$property} = $properties->{selectQuery}->{$property};
  }
  my @data = $this->_filterData( $query->getData($lproperties) );
  $this->{error_mgr}->exitProgram( ERR_CAT, 1, [ $lproperties->{query}, ],
    $query->getErrorStatus );
  $this->{error_mgr}->printHeader( "all seqs = " . scalar @data );
  return @data;
}

sub _getProfileData {
  my ncbi::H5N1Classifier $this = shift;

  $this->{profile} = {};

  my $cmds       = $this->{tools}->cmds;
  my $ncbi_utils = $this->{ncbi_utils};
  my $properties = $ncbi_utils->getProperties;

  my $profileSeqs = $properties->{profileSeqs};

  my $directoryName = $profileSeqs->{directoryName};
  my $files         = $profileSeqs->{files};
  my $rootDirectory = $profileSeqs->{rootDirectory};
  my $server        = $profileSeqs->{server};
  my $userName      = $profileSeqs->{userName};
  my $getFromServer =
    (    !util::Constants::EMPTY_LINE($userName)
      && !util::Constants::EMPTY_LINE($server)
      && !util::Constants::EMPTY_LINE($rootDirectory) )
    ? util::Constants::TRUE
    : util::Constants::FALSE;

  foreach my $fname ( @{$files} ) {

    $fname =~ /\.(.+)$/;
    my $type = $1;
    my $msgs = {};
    if ($getFromServer) {
      my $file =
        join( util::Constants::SLASH, $rootDirectory, $directoryName, $fname );
      my $theServer = $userName . '@' . $server;
      $msgs->{cmd} = "scp $theServer:$file " . $this->{run_dir};
    }
    else {
      my $file =
        join( util::Constants::SLASH, getPath($directoryName), $fname );
      $msgs->{cmd} = "ln -s '$file' '" . $this->{run_dir} . "'";
    }
    $cmds->executeCommand( $msgs, $msgs->{cmd}, "copying $fname" );
    $this->{profile}->{$type} =
      join( util::Constants::SLASH, $this->{run_dir}, $fname );
  }
}

sub _readProfileClade {
  my ncbi::H5N1Classifier $this = shift;

  my $utils = $this->{utils};

  my $fh = $utils->openFile( $this->{profile}->{&LOOKUP_TYPE}, '<' );
  $this->{profile_clade} = {};
  while ( !$fh->eof ) {
    my $line = $fh->getline;
    chomp($line);
    next if ( util::Constants::EMPTY_LINE($line) );
    my ( $acc, $clade ) = split( /\t/, $line );
    $this->{profile_clade}->{$acc} = $clade;
  }
  $fh->close;
}

################################################################################
#
#			   Parallel Processing Methods
#
################################################################################

sub _setErrorStatus {
  my ncbi::H5N1Classifier $this = shift;
  my ( $err_cat, $err_num, $msgs, $test ) = @_;

  return if ( !$test );
  $this->{error_mgr}->registerError( $err_cat, $err_num, $msgs, $test );
  $this->{error_status} = util::Constants::TRUE;
}

sub _getErrorStatus {
  my ncbi::H5N1Classifier $this = shift;

  return $this->{error_status};
}

sub _checkErrorStatus {
  my ncbi::H5N1Classifier $this = shift;

  my $ncbi_utils = $this->{ncbi_utils};

  return if ( !$this->_getErrorStatus );
  $ncbi_utils->addReport( $this->{counts}->printStr );
  $ncbi_utils->printReport;
  $this->{jobs}->terminateRun( 'h5n1', keys %{ $this->{pids} } );
}

sub _updateResult {
  my ncbi::H5N1Classifier $this = shift;
  my ($pid) = @_;

  my $ncbi_utils = $this->{ncbi_utils};
  my $properties = $ncbi_utils->getProperties;
  my $tools      = $this->{tools};
  my $utils      = $this->{utils};

  my $pidInfo       = $this->{pids}->{$pid};
  my $gbAccession   = $pidInfo->getComponentType;
  my $workspaceRoot = $pidInfo->getWorkspaceRoot;

  my $statusFile =
    join( util::Constants::SLASH, $workspaceRoot, $properties->{statusFile} );
  ###
  ### Update Status
  ###
  my $runStatus = util::Constants::FALSE;
  foreach my $type (STATUS_TYPES) {
    my $sFile = join( util::Constants::DOT, $statusFile, $type );
    my $jobStatus = $utils->getStatus($sFile);
    $this->{error_mgr}
      ->printMsg("$pid completes with $type status = $jobStatus");
    if ( $jobStatus eq $tools->FAILED ) {
      $tools->setStatus( $tools->FAILED );
      $runStatus = util::Constants::TRUE;
      $this->{counts}->increment( DISPOSITION_TAG,
        ( $type eq CLUSTALW_TYPE )
        ? FAILED_CLUSTALW_VAL
        : FAILED_CLASSIFIER_VAL );
      last;
    }
  }
  return if ($runStatus);
  ###
  ### Update Result
  ###
  $this->{counts}->increment( DISPOSITION_TAG, CLASSIFIED_VAL );
  my $struct = $this->{data}->{$gbAccession};
  my $seqOut =
    join( util::Constants::SLASH, $workspaceRoot, $ncbi_utils->SEQ_OUT );
  my $fh = $utils->openFile( $seqOut, '<' );
  while ( !$fh->eof ) {
    my $line = $fh->getline;
    chomp($line);
    next if ( util::Constants::EMPTY_LINE($line) );
    my ( $acc, $clade ) = split( /\t/, $line );
    next if ( $acc ne $gbAccession );
    $struct->{h5n1_clade} = $clade;
  }
  $fh->close;
}

sub _launchNextJob {
  my ncbi::H5N1Classifier $this = shift;

  my $cmds       = $this->{tools}->cmds;
  my $ncbi_utils = $this->{ncbi_utils};
  my $properties = $ncbi_utils->getProperties;
  my $utils      = $this->{utils};

  my $nextFileIndex = $this->{next_job};
  return 0 if ( $nextFileIndex > $this->{last_job} );

  my $acc       = $this->{accs}->[$nextFileIndex];
  my $struct    = $this->{data}->{$acc};
  my $country   = lc( strip_whitespace( $struct->{country} ) );
  my $continent = $this->{country_continent}->{$country};
  my $gap_info  = $ncbi_utils->calculateUngapped( $struct->{seq} );

  $this->{error_mgr}->printMsg("Creating process $acc ($continent, $country)");

  my $workspaceRoot = join( util::Constants::SLASH, $this->{run_dir}, $acc );
  $this->{tools}
    ->cmds->createDirectory( $workspaceRoot, 'Creating $acc directory',
    util::Constants::TRUE );
  my $propertiesFile = join( util::Constants::SLASH,
    $workspaceRoot, join( util::Constants::DOT, $acc, PROPERTIES_TYPE ) );
  my $errFile = join( util::Constants::SLASH,
    $workspaceRoot,
    join( util::Constants::DOT, $acc, $utils->ERR_OUTPUT_SUFFIX ) );
  my $statusFile =
    join( util::Constants::SLASH, $workspaceRoot, $properties->{statusFile} );

  chdir($workspaceRoot);

  my $config = new util::ConfigParams( $this->{error_mgr} );
  foreach my $type (STATUS_TYPES) {
    $config->setProperty( $type . 'Status',
      join( util::Constants::DOT, $statusFile, $type ) );
  }

  my $msgs =
    { cmd =>
      $cmds->COPY_FILE( $this->{profile}->{&FASTA_TYPE}, $workspaceRoot ), };
  $cmds->executeCommand( $msgs, $msgs->{cmd}, 'copying profile' );

  $config->setProperty( 'classifierConfig',  $properties->{classifierConfig} );
  $config->setProperty( 'classifierPerlLib', $properties->{classifierPerlLib} );
  $config->setProperty( 'classifierTool',    $properties->{classifierTool} );
  $config->setProperty( 'clustalWPath',      $properties->{clustalWPath} );
  $config->setProperty( 'debugSwitch',       $properties->{debugSwitch} );
  $config->setProperty( 'executionDirectory', $workspaceRoot );
  $config->setProperty( 'gbAccession',        $acc );
  $config->setProperty( 'logInfix',           $properties->{logInfix} );
  $config->setProperty( 'naSequenceId',       $struct->{na_sequence_id} );
  $config->setProperty(
    'profileFasta',
    join( util::Constants::SLASH,
      $workspaceRoot, basename( $this->{profile}->{&FASTA_TYPE} )
    )
  );
  $config->setProperty( 'seqOut',
    join( util::Constants::SLASH, $workspaceRoot, $ncbi_utils->SEQ_OUT ) );
  $config->setProperty( 'sequence',      $gap_info->{ungapped_seq} );
  $config->setProperty( 'workspaceRoot', $workspaceRoot );
  $config->setProperty( 'yearDate',
    $ncbi_utils->getNcYyyy . $ncbi_utils->getNcMmdd );
  $config->storeFile($propertiesFile);

  my $cmd = $utils->getRunToolCmd( $properties->{runTool},
    $propertiesFile, $workspaceRoot, $acc );
  my $pid = $this->{jobs}->forkProcess($cmd);
  $this->_setErrorStatus( ERR_CAT, 2, [ $acc, $properties->{runTool}, ],
    !$pid );
  return 0 if ( $this->_getErrorStatus );
  $this->{pids}->{$pid} = new parallel::PidInfo(
    $pid, $this->{error_mgr}, $this->{utils},
    cmd             => $cmd,
    component_type  => $acc,
    err_file        => $errFile,
    properties_file => $propertiesFile,
    status_file     => $statusFile,
    workspace_root  => $workspaceRoot
  );
  $this->{next_job}++;
  return $pid;
}

################################################################################
#
#				    Methods
#
################################################################################

sub new {
  my ncbi::H5N1Classifier $this = shift;
  my ( $error_mgr, $tools, $utils, $ncbi_utils ) = @_;
  $this = fields::new($this) unless ref($this);

  $this->{continents}        = {};
  $this->{countries}         = {};
  $this->{country_continent} = {};
  $this->{error_mgr}         = $error_mgr;
  $this->{ncbi_utils}        = $ncbi_utils;
  $this->{profile}           = undef;
  $this->{tools}             = $tools;
  $this->{utils}             = $utils;
  $this->{unique_id}         = UNIQUE_ID_START;

  $this->{run_dir} = join( util::Constants::SLASH,
    $ncbi_utils->getDataDirectory,
    $ncbi_utils->getProperties->{datasetName}
  );

  return $this;
}

sub process {
  my ncbi::H5N1Classifier $this = shift;

  my $ncbi_utils = $this->{ncbi_utils};
  my $properties = $ncbi_utils->getProperties;
  my $tools      = $this->{tools};

  if ( $properties->{na_sid} )   { $this->createNaSid; }
  if ( $properties->{generate} ) { $this->generateLoad; }
  if ( $properties->{load} )     { $this->processToDb; }

  $ncbi_utils->printReport;
  $tools->setStatus( $tools->SUCCEEDED );
  $tools->saveStatus(
    join( util::Constants::SLASH, $this->{run_dir}, $properties->{statusFile} )
  );
}

sub createNaSid {
  my ncbi::H5N1Classifier $this = shift;

  $this->{error_mgr}->printHeader("Generating NA Sid File");

  my $cmds       = $this->{tools}->cmds;
  my $ncbi_utils = $this->{ncbi_utils};
  my $properties = $ncbi_utils->getProperties;
  my $tools      = $this->{tools};
  my $utils      = $this->{utils};

  my $accsFile  = $properties->{accsFile};
  my $naSidFile = $properties->{naSidFile};

  my $file_separator = $naSidFile->{file_separator};
  my $NSFile         = join( util::Constants::SLASH,
    $ncbi_utils->getDataDirectory,
    $naSidFile->{file}
  );

  my $lproperties = { %{$properties} };
  $lproperties->{gbAccessions} = [];
  my $ifh = $utils->openFile( $accsFile, '<' );
  while ( !$ifh->eof ) {
    my $gb_accession = $ifh->getline;
    chomp($gb_accession);
    next if ( util::Constants::EMPTY_LINE($gb_accession) );
    push( @{ $lproperties->{gbAccessions} }, $gb_accession );
  }
  $ifh->close;
  my $query = new parallel::Query( undef, $this->{error_mgr}, $this->{tools} );
  foreach my $property ( keys %{ $properties->{naSidQuery} } ) {
    $lproperties->{$property} = $properties->{naSidQuery}->{$property};
  }
  my @data = $query->getData($lproperties);

  $this->{error_mgr}->exitProgram( ERR_CAT, 1, [ $lproperties->{query}, ],
    $query->getErrorStatus );
  $this->{error_mgr}->printHeader( "na sid accessions = " . scalar @data );

  my $ofh = $utils->openFile($NSFile);
  foreach my $struct (@data) {
    my @row = ();
    foreach my $index ( 0 .. $#{ $naSidFile->{cols} } ) {
      push( @row, $struct->{ $naSidFile->{cols}->[$index] } );
    }
    $ofh->print( join( $file_separator, @row ) . util::Constants::NEWLINE );
  }
  $ofh->close;
}

sub generateLoad {
  my ncbi::H5N1Classifier $this = shift;

  my $cmds       = $this->{tools}->cmds;
  my $ncbi_utils = $this->{ncbi_utils};
  my $properties = $ncbi_utils->getProperties;
  my $tools      = $this->{tools};
  my $utils      = $this->{utils};

  $this->{error_mgr}->printHeader("Getting Sequences");
  $tools->cmds->createDirectory( $this->{run_dir}, 'Creating H5N1 directory',
    util::Constants::TRUE );
  chdir( $this->{run_dir} );

  $this->_getNaSeqIds;
  if ( scalar @{ $properties->{naSequenceIds} } == 0 ) {
    $ncbi_utils->addReport(
      "H5N1 classification annotation:  no sequences found\n");
    return;
  }
  $this->_getCountryContinents;
  my @data = $this->_getData;
  if ( scalar @data == 0 ) {
    $ncbi_utils->addReport(
      "H5N1 classification annotation:  no sequences found\n");
    return;
  }
  ###
  ### Job Specifics
  ###
  $this->{accs}         = [];
  $this->{data}         = {};
  $this->{error_status} = util::Constants::FALSE;
  $this->{next_job}     = 0;
  $this->{pids}         = {};

  $this->{counts} =
    new util::Statistics( 'H5N1 Classification Sequence Disposition',
    undef, $this->{error_mgr}, DISPOSITION_TAG, DISPOSITION_VALS );
  $this->{counts}->setCountsToZero;
  $this->{counts}->setShowTotal(util::Constants::TRUE);

  $this->{jobs} = new parallel::Jobs(
    $properties->{retryLimit},
    $properties->{retrySleep},
    $properties->{datasetName},
    join( util::Constants::SLASH, $this->{run_dir}, $properties->{statusFile} ),
    $this->{run_dir},
    $this->{utils},
    $this->{error_mgr},
    $tools
  );
  $this->{jobs}->setSleepRate(0);
  ###
  ### Determine Sequences to Compute
  ###
  $this->{error_mgr}->printHeader("Processing Sequences");
  $this->_getProfileData;
  $this->_readProfileClade;
  my $profile_clade = $this->{profile_clade};
  foreach my $struct (@data) {
    my $acc = $struct->{gb_accession};
    $this->{data}->{$acc} = $struct;
    $struct->{h5n1_clade} = util::Constants::EMPTY_STR;
    ###
    ### check for profile sequence
    ###
    if ( defined( $profile_clade->{$acc} ) ) {
      $struct->{h5n1_clade} = $profile_clade->{$acc};
      $this->{error_mgr}
        ->printMsg( "reference sequence ($acc) already assigned clade = "
          . $struct->{h5n1_clade} );
      $this->{counts}->increment( DISPOSITION_TAG, REFERENCE_VAL );
      next;
    }
    push( @{ $this->{accs} }, $acc );
  }
  $this->{last_job} = $#{ $this->{accs} };
  ###
  ### Launch Jobs
  ###
  ### Initially, Start the Maximumn Number Of Processes
  ###
  foreach my $procNum ( 1 .. $properties->{maxProcesses} ) {
    my $pid = $this->_launchNextJob;
    $this->_checkErrorStatus;
    last if ( !$pid );
  }
  ###
  ### Run the Rest of Jobs
  ###
  my $completed = util::Constants::FALSE;
  my $cPids     = [ keys %{ $this->{pids} } ];
  while ( !$completed ) {
    if ( scalar @{$cPids} == 0 ) {
      $completed = util::Constants::TRUE;
      next;
    }
    sleep( $properties->{processSleep} );
    my $curr_pids = [];
    foreach my $child ( $this->{jobs}->getPidInfo($cPids) ) {
      my $pid = $child->{pid};
      $this->{error_mgr}->printMsg( $child->{line} );
      if ( $child->{completed} ) {
        my $creturn = waitpid( $pid, WNOHANG );
        $this->{error_mgr}->printMsg("  child return status = $creturn");
        $this->_updateResult($pid);
        $pid = $this->_launchNextJob;
        $this->_checkErrorStatus;
      }
      push( @{$curr_pids}, $pid ) if ($pid);
    }
    $cPids = $curr_pids;
  }
  $ncbi_utils->addReport( $this->{counts}->printStr );
  $ncbi_utils->saveResults( $this->{data}, $this->{run_dir} );

  my $failed_count =
    $this->{counts}->count( DISPOSITION_TAG, FAILED_CLUSTALW_VAL ) +
    $this->{counts}->count( DISPOSITION_TAG, FAILED_CLASSIFIER_VAL );
  return if ( $failed_count == 0 );
  $this->{counts}->print;
  $tools->setStatus( $tools->FAILED );
  $this->{tools}->saveStatus(
    join( util::Constants::SLASH, $this->{run_dir}, $properties->{statusFile} )
  );
  $this->{error_mgr}->exitProgram( ERR_CAT, 4, [], util::Constants::TRUE );
}

sub processToDb {
  my ncbi::H5N1Classifier $this = shift;

  my $ncbi_utils = $this->{ncbi_utils};
  my $properties = $ncbi_utils->getProperties;
  my $tools      = $this->{tools};

  if ( !-s $ncbi_utils->getSeqsOut( $this->{run_dir} ) ) {
    $ncbi_utils->addReport(
      "H5N1 classification annotation:  no sequences found\n");
    return;
  }

  $tools->startTransaction(util::Constants::TRUE);
  my $loader = new ncbi::Loader( 'H5N1 annotation',
    SEQID_QUERY, [UPDATE_QUERY], $this->{error_mgr}, $this->{tools},
    $this->{utils}, $this->{ncbi_utils} );
  $loader->setSeqIdComp( $properties->{seqIdComp} );

  $this->{error_mgr}->printHeader("Updating Clade");
  my $queryStatus = util::Constants::FALSE;
  my $segmentName =
    join( util::Constants::COMMA_SEPARATOR, @{ $properties->{segments} } );
  my $errorCount = 0;
OUTTER_LOOP:
  foreach my $struct ( $ncbi_utils->readResults( $this->{run_dir} ) ) {
    $this->{error_mgr}->printMsg(
      '('
        . join( util::Constants::COMMA_SEPARATOR,
        $struct->{gb_accession}, $struct->{na_sequence_id},
        $struct->{h5n1_clade}
        )
        . ')'
    );
    $struct->{subtype}      = $properties->{subtype};
    $struct->{segment_name} = $segmentName;
    ###
    ### Get seq_id
    ###
    my $status = $loader->getSeqId($struct);
    $queryStatus = $status ? $status : $queryStatus;
    last if ($status);
    ###
    ### execute updates
    ###
    foreach my $queryName (UPDATE_QUERY) {
      my $status = $loader->executeUpdate( $queryName, $struct );
      $errorCount++ if ($status);
      $queryStatus = $status ? $status : $queryStatus;
      next OUTTER_LOOP if ($status);
    }
  }
  ###
  ### Error(s) in  Run
  ###
  my $db = $this->{tools}->getSession;
  if ($queryStatus) {
    $ncbi_utils->addReport(
      "H5N1 classification annotation (ERRORS ENCOUNTERED):  inserts executed "
        . ( $db->getCommitCount - $errorCount )
        . ", insert errors $errorCount\n" );
    $ncbi_utils->printReport;
    $tools->rollbackTransaction;
    $tools->setStatus( $tools->FAILED );
    $tools->saveStatus(
      join( util::Constants::SLASH,
        $this->{run_dir}, $properties->{statusFile}
      )
    );
    $this->{error_mgr}->exitProgram( ERR_CAT, 3, [], util::Constants::TRUE );
  }
  ###
  ### Successful Run
  ###
  $ncbi_utils->addReport( "H5N1 classification annotation:  success "
      . ( $db->getCommitCount - $errorCount )
      . ", error $errorCount\n" );
  $tools->finalizeTransaction;
}

################################################################################
1;

__END__

=head1 NAME

H5N1Classifier.pm

=head1 SYNOPSIS

  use ncbi::H5N1Classifier;

=head1 DESCRIPTION

The H5N1 classifier.

=head1 METHODS

The following methods are exported by this class.

=head2 B<new ncbi::H5N1Classifier(error_mgr, tools, utils, ncbi_utils)>

This is the constructor for the class.

=cut
