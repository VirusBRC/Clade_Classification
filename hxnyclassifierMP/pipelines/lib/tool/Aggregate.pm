package tool::Aggregate;
################################################################################
#
#				Required Modules
#
################################################################################

use strict;

use File::Basename;
use FileHandle;
use Pod::Usage;

use util::Constants;

use parallel::File::DataDups;
use parallel::File::FamilyNames;
use parallel::File::OutputFiles;

use parallel::Lock;

use tool::ErrMsgs;

use base 'tool::Tool';

use fields qw(
  aggregator_type
  completed
  data_dups
  data_files
  family_name_files
  family_names
  jobs_aggregated
  jobs_to_aggregate
  lock
  output_file
);

################################################################################
#
#			            Static Class Constants
#
################################################################################
###
### Error Category
###
sub ERR_CAT { return tool::ErrMsgs::AGGREGATOR_CAT; }
###
### Interproscan Properties
###
sub AGGREGATEDELETESUFFIX_PROP { return 'aggregateDeleteSuffix'; }
sub AGGREGATESUFFIX_PROP       { return 'aggregateSuffix'; }
sub DATADUPSFILE_PROP          { return 'dataDupsFile'; }
sub FAMILYNAMESFILE_PROP       { return 'familyNamesFile'; }

sub AGGREGATE_PROPERTIES {
  return (
    AGGREGATEDELETESUFFIX_PROP, AGGREGATESUFFIX_PROP,
    DATADUPSFILE_PROP,          FAMILYNAMESFILE_PROP
  );
}
###
### Aggregate file types
###
sub AGGREGATE_TYPE { return AGGREGATESUFFIX_PROP; }
sub DELETE_TYPE    { return AGGREGATEDELETESUFFIX_PROP; }

################################################################################
#
#                           Private Methods
#
################################################################################

sub _initializeRun {
  my tool::Aggregate $this = shift;

  my $properties = $this->getProperties;

  $this->{completed} = util::Constants::FALSE;
  $this->{data_dups} =
    new parallel::File::DataDups( $properties->{dataDupsFile},
    $this->{error_mgr} );
  $this->{data_files} =
    new parallel::File::OutputFiles( $properties->{dataFile},
    $this->{error_mgr} );
  $this->{family_names} =
    new parallel::File::FamilyNames( $properties->{familyNamesFile},
    $this->{error_mgr} );
  $this->{family_name_files} = {};
  $this->{jobs_aggregated}   = {};
  $this->{jobs_to_aggregate} = [];
  $this->{output_file}       = $properties->{outputFile};
  $this->{lock}              = new parallel::Lock( $properties->{dataFileLock},
    $this->{error_mgr}, $this->{tools} );
}

sub _getOutputFiles {
  my tool::Aggregate $this = shift;

  $this->{jobs_to_aggregate} = [];

  my $dataFiles         = $this->getDataFiles;
  my $jobs_aggregated   = $this->{jobs_aggregated};
  my $jobs_to_aggregate = $this->{jobs_to_aggregate};
  my $lock              = $this->{lock};
  my $properties        = $this->getProperties;
  my $tools             = $this->{tools};

  while (util::Constants::TRUE) {
    if ( $lock->setLock ) {
      ###
      ### Got the lock, read the file contents
      ###
      if ( $dataFiles->readFile ) {
        $tools->setStatus( $tools->FAILED );
        return util::Constants::TRUE;
      }
      ###
      ### remove the lock
      ###
      $lock->removeLock;
      if ( $lock->errorAsserted ) {
        $tools->setStatus( $tools->FAILED );
        return $lock->errorAsserted;
      }
      ###
      ### Get the aggregation information
      ###
      last;
    }
    else {
      ###
      ### Check for error asserted
      ###
      if ( $lock->errorAsserted ) {
        $tools->setStatus( $tools->FAILED );
        return $lock->errorAsserted;
      }
      sleep( $properties->{sleepInterval} );
    }
  }
  ###
  ### Determine new contents to aggregate and if the job is completed.
  ###
  $this->{completed} = $dataFiles->getCompleted;
  foreach my $prefix ( $dataFiles->getPrefixes ) {
    next if ( defined( $jobs_aggregated->{$prefix} ) );
    push( @{$jobs_to_aggregate}, $prefix );
  }
}

################################################################################
#
#                           Public Methods
#
################################################################################

sub new($$$$) {
  my ( $that, $aggregator_type, $properties, $utils, $error_mgr, $tools ) = @_;
  push( @{$properties}, AGGREGATE_PROPERTIES );
  my tool::Aggregate $this =
    $that->SUPER::new( 'aggregator', $properties, $utils, $error_mgr, $tools );

  $this->{aggregator_type}   = $aggregator_type;
  $this->{completed}         = util::Constants::FALSE;
  $this->{data_dups}         = undef;
  $this->{data_files}        = undef;
  $this->{family_name_files} = undef;
  $this->{family_names}      = undef;
  $this->{jobs_aggregated}   = {};
  $this->{jobs_to_aggregate} = [];
  $this->{lock}              = undef;
  $this->{output_file}       = undef;

  return $this;
}

sub initializeOutputFile {
  my tool::Aggregate $this = shift;
  my ($outputFile) = @_;
  ###
  ### Remove output File
  ###
  my $status = util::Constants::FALSE;
  return $status if ( !-e $outputFile );
  my $num_files = unlink($outputFile);
  $status = ( $num_files != 1 );
  if ($status) {
    $this->{error_mgr}->registerError( ERR_CAT, 2, [$outputFile], $status );
    $this->{tools}->setStatus( $this->{tools}->FAILED );
  }
  return $status;
}

sub initializeAggregator {
  my tool::Aggregate $this = shift;

  ###############################
  ### Re-implementable Method ###
  ###############################
  ###
  ### Default Action
  ###
  return $this->initializeOutputFile( $this->getOutputFile );
}

sub aggregateFile {
  my tool::Aggregate $this = shift;
  my ($dataFile) = @_;

  #######################
  ### Abstract Method ###
  #######################

  return util::Constants::FALSE;
}

sub postProcess {
  my tool::Aggregate $this = shift;

  ###############################
  ### Re-implementable Method ###
  ###############################
  ###
  ### Default Action:  NO-OP
  ###
}

sub run {
  my tool::Aggregate $this = shift;

  ###
  ### Initialize aggregator and run it 'in place'
  ###
  my $properties = $this->getProperties;
  my $tools      = $this->{tools};
  $this->_initializeRun;
  ###
  ### 1.  Read the data duplicates and (optionally) family names files,
  ###     and initialize aggregator
  ###
  my $status = $this->getDataDups->readFile;
  if ($status) {
    $this->{error_mgr}
      ->registerError( ERR_CAT, 1, [ $properties->{dataDupsFile} ], $status );
    $tools->setStatus( $tools->FAILED );
    return;
  }
  $status = $this->getFamilyNames->readFile;
  if ($status) {
    $this->{error_mgr}
      ->registerError( ERR_CAT, 6, [ $properties->{familyNamesFile} ],
      $status );
    $tools->setStatus( $tools->FAILED );
    return;
  }
  ###
  ### 2.  Initialize Aggregator
  ###
  $status = $this->initializeAggregator;
  return if ($status);
  ###
  ### 3.  Aggregate jobs
  ###
  while ( !$this->getCompleted ) {
    sleep( $properties->{sleepInterval} );
    ###
    ### Get the new outputs
    ###
    $status = $this->_getOutputFiles;
    if ($status) {
      $this->{error_mgr}
        ->registerError( ERR_CAT, 5, [ $this->getOutputFile ], $status );
      $tools->setStatus( $tools->FAILED );
      return;
    }
    foreach my $prefix ( @{ $this->{jobs_to_aggregate} } ) {
      my $dataFile = $this->getDataFiles->getOutputFile($prefix);
      $this->{error_mgr}->printHeader( "Process File\n"
          . "  dir  = "
          . dirname($dataFile) . "\n"
          . "  file = "
          . basename($dataFile) );
      if ( $this->getDataFiles->getOutputFileStatus($prefix) eq
        $this->getDataFiles->FILE_NOT_EXISTS )
      {
        $this->{error_mgr}->printMsg("File Missing, Skipping");
        $this->{jobs_aggregated}->{$prefix} = util::Constants::EMPTY_STR;
        next;
      }
      $status = $this->aggregateFile($dataFile);
      if ($status) {
        $this->{error_mgr}->registerError( ERR_CAT, 4, [$dataFile], $status );
        $this->postProcess;
        $tools->setStatus( $tools->FAILED );
        return;
      }
      $this->{jobs_aggregated}->{$prefix} = util::Constants::EMPTY_STR;
    }
  }
  $this->postProcess;
}

################################################################################
#
#                           Getter Methods
#
################################################################################

sub getCompleted {
  my tool::Aggregate $this = shift;
  return $this->{completed};
}

sub getDataDups {
  my tool::Aggregate $this = shift;
  return $this->{data_dups};
}

sub getFamilyNames {
  my tool::Aggregate $this = shift;
  return $this->{family_names};
}

sub getOutputFile {
  my tool::Aggregate $this = shift;
  return $this->{output_file};
}

sub getDataFiles {
  my tool::Aggregate $this = shift;
  return $this->{data_files};
}

sub getOutputFh {
  my tool::Aggregate $this = shift;
  my ( $id, $file_type ) = @_;

  my $fh     = new FileHandle;
  my $status = util::Constants::FALSE;
  if ( $file_type ne AGGREGATE_TYPE && $file_type ne DELETE_TYPE ) {
    $status = util::Constants::TRUE;
    $this->{error_mgr}
      ->registerError( ERR_CAT, 8, [ $id, $file_type ], $status );
    $this->{tools}->setStatus( $this->{tools}->FAILED );
    return ( $fh, $status );
  }

  my $familyNameFiles   = $this->{family_name_files};
  my $familyNames       = $this->getFamilyNames;
  my $outputFile        = $this->getOutputFile;
  my $family_name       = $familyNames->getFamilyName($id);
  my $familyNamePattern = FAMILYNAMESFILE_PROP;
  my $file              = undef;
  if ( util::Constants::EMPTY_LINE($family_name) ) {
    $file = $outputFile;
  }
  else {
    if ( !defined( $familyNameFiles->{$family_name} ) ) {
      my $fnFile = $outputFile;
      $fnFile =~ s/$familyNamePattern/$family_name/;
      $familyNameFiles->{$family_name} = $fnFile;
    }
    $file = $familyNameFiles->{$family_name};
  }
  if ( $file_type eq DELETE_TYPE ) {
    my $aggregate_type = $this->getProperties->{&AGGREGATE_TYPE};
    my $delete_type    = $this->getProperties->{&DELETE_TYPE};
    $file =~ s/\.$aggregate_type/\.$delete_type/;
  }

  $status = !$fh->open( $file, '>>' );
  if ($status) {
    $this->{error_mgr}->registerError( ERR_CAT, 8, [ $id, $file ], $status );
    $this->{tools}->setStatus( $this->{tools}->FAILED );
    return ( $fh, $status );
  }
  $fh->autoflush(util::Constants::TRUE);
  return ( $fh, $status );
}

################################################################################

1;

__END__

=head1 NAME

Aggregate.pm

=head1 DESCRIPTION

This abstract class class defines the runner for aggregating results.

=head1 STATIC CONSTANTS


=head1 METHODS

The following methods are exported by this class.

=head2 B<new tool::Aggregate(aggregator_type, utils, error_mgr, tools)>

This is the constructor for the class.

=cut
