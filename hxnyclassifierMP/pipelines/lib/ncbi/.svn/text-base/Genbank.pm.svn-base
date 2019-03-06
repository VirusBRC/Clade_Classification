package ncbi::Genbank;
######################################################################
#                  Copyright (c) 2012 Northrop Grumman.
#                          All rights reserved.
######################################################################

use strict;

use File::Basename;
use FileHandle;
use Pod::Usage;

use util::Constants;
use util::DbQuery;
use util::FileTime;
use util::PathSpecifics;
use util::Statistics;

use xml::Types;

use ncbi::ErrMsgs;
use ncbi::GenbankFile;
use ncbi::Taxonomy;

use fields qw(
  add_missing
  counters
  db_date
  db_queries
  delete_missing
  error_mgr
  gb_data
  gb_file
  ncbi_utils
  loaded
  out_files
  pending
  pending_file
  taxons
  type
  tools
  utils
);

################################################################################
#
#			            Static Class Constants
#
################################################################################
###
### Error Category
###
sub ERR_CAT { return ncbi::ErrMsgs::GENBANK_CAT; }
###
### Sequence Counting Statistics
###
sub NCBI_SEQS { return 'NCBI Sequences'; }

sub ALREADY_LOADED     { return 'already loaded'; }
sub ALREADY_PENDING    { return 'already pending'; }
sub LOADABLE_COUNT     { return 'loadable'; }
sub NOT_LOADABLE_COUNT { return 'not loadable'; }
sub PENDING_COUNT      { return 'pending'; }

sub NCBI_COUNT_ORD {
  return [
    NOT_LOADABLE_COUNT, LOADABLE_COUNT, PENDING_COUNT,
    ALREADY_LOADED,     ALREADY_PENDING,
  ];
}
###
### Missing Sequence Counting Statistics
###
sub MISSING_SEQS { return 'Missing Sequences'; }

sub MISSING_TAXON_COUNT { return 'missing taxon'; }
sub MISSING_FLU_COUNT   { return 'missing flu na'; }

sub MISSING_COUNT_ORD { return [ MISSING_TAXON_COUNT, MISSING_FLU_COUNT, ]; }
###
### Family Names Counts
###
sub FAMILY_NAMES { return 'Family Names'; }

sub FAMILY_NAMES_SEQS { return 'NCBI Sequences'; }
sub FAMILY_NAMES_SEQS_ORD { return return [ LOADABLE_COUNT, PENDING_COUNT, ]; }
###
### Statistics Counters
###
sub FAMILY_NAMES_COUNTER { return 'family names'; }
sub MISSING_COUNTER      { return 'missing'; }
sub NCBI_COUNTER         { return 'ncbi'; }
sub PENDING_COUNTER      { return PENDING_COUNT; }
sub TOTAL_COUNTER        { return 'total'; }

sub COUNTERS {
  return {
    &FAMILY_NAMES_COUNTER => {
      title => "Family Names Counts",
      tag   => [ FAMILY_NAMES_SEQS, FAMILY_NAMES, ],
      ord   => [ FAMILY_NAMES_SEQS_ORD, undef, ],
    },

    &MISSING_COUNTER => {
      title => "Missing Record Counts",
      tag   => MISSING_SEQS,
      ord   => MISSING_COUNT_ORD
    },

    &NCBI_COUNTER => {
      title => "NCBI Record Counts",
      tag   => NCBI_SEQS,
      ord   => NCBI_COUNT_ORD,
    },

    &PENDING_COUNTER => {
      title => "Pending Record Counts",
      tag   => NCBI_SEQS,
      ord   => NCBI_COUNT_ORD,
    },

    &TOTAL_COUNTER => {
      title => "Total Record Counts",
      tag   => NCBI_SEQS,
      ord   => NCBI_COUNT_ORD,
    },
  };
}
###
### File Types
###
sub LOAD_FILE    { return LOADABLE_COUNT; }
sub NCBI_FILE    { return NCBI_COUNTER; }
sub PENDING_FILE { return PENDING_COUNT; }

################################################################################
#
#				Private Methods
#
################################################################################

sub _setTodayDate {
  my ncbi::Genbank $this = shift;

  my $ncbi_utils = $this->{ncbi_utils};
  my $date       = $ncbi_utils->getSpecialValue('todayDayDate');
  $this->{db_date} =
    join( util::Constants::HYPHEN, $date->{year}, $date->{month},
    $date->{day} );
}

sub _setOutFiles {
  my ncbi::Genbank $this = shift;
  my ($not_reset) = @_;

  my $ncbi_utils = $this->{ncbi_utils};
  my $properties = $ncbi_utils->getProperties;
  ###
  ### Set the final pending file
  ###
  $this->{pending_file} = getPath( $properties->{pendingFile} );
  ###
  ### Set the working pending file
  ###
  $this->setOutFile(
    PENDING_FILE,
    join( util::Constants::SLASH,
      $ncbi_utils->getDataDirectory,
      basename( $this->{pending_file} )
    ),
    $not_reset
  );
  ###
  ### Set the load file
  ###
  $this->setOutFile( LOAD_FILE,
    $ncbi_utils->getFile( 'loadSeqFile', $ncbi_utils->getNcMmdd ), $not_reset );
}

sub _addData {
  my ncbi::Genbank $this = shift;
  my ( $struct, $file_type, $load_type ) = @_;

  $struct->{file_type}         = $file_type;
  $struct->{load_type}         = $load_type;
  $struct->{file_process_date} = $this->dbDate;

  push( @{ $this->{gb_data} }, $struct );
}

sub _updatePending {
  my ncbi::Genbank $this = shift;

  my $cmds = $this->{tools}->cmds;

  my $gb_file   = $this->gbFile;
  my $pfile     = $this->getOutFile(PENDING_FILE);
  my $counter   = $this->getCounter(PENDING_COUNT);
  my $fncounter = $this->getCounter(FAMILY_NAMES_COUNTER);
  ###
  ### Determine if any pending records have been overtaken
  ### by loaded records.  That is, date on loaded record is
  ### more current than pending record.  In which case,
  ### remove pending record from pending file.
  ###
  my $remove_accs = {};
  foreach my $gb_accession ( keys %{ $this->{pending} } ) {
    next
      if (
      !defined( $this->{loaded}->{$gb_accession} )
      || !&later_than(
        &get_ncbi_time( $this->{loaded}->{$gb_accession}->{date} ),
        &get_ncbi_time( $this->{pending}->{$gb_accession}->{date} )
      )
      );
    $remove_accs->{$gb_accession} =
      $this->{pending}->{$gb_accession}->{family_name};
  }
  return if ( scalar keys %{$remove_accs} == 0 );
  ###
  ### Update pending file
  ###
  $this->{error_mgr}
    ->printHeader("Correcting Pending File\n  file      = $pfile");

  my $backupPendingFile = join( util::Constants::DOT, $pfile, 'BACKUP' );
  my $msgs = { cmd => $cmds->MOVE_FILE( $pfile, $backupPendingFile ), };
  $this->{error_mgr}->exitProgram(
    ERR_CAT, 1,
    [ 'moving', $pfile, "to $backupPendingFile", ],
    $cmds->executeCommand( $msgs, $msgs->{cmd}, 'moving file' )
  );
  $gb_file->open($backupPendingFile);
  while ( !$gb_file->eof ) {
    $gb_file->nextRecord;
    my $gb_accession = $gb_file->getStruct->{gb_accession};
    if ( defined( $remove_accs->{$gb_accession} ) ) {
      $counter->increment( NCBI_SEQS, NOT_LOADABLE_COUNT );
      $counter->decrement( NCBI_SEQS, PENDING_COUNT );
      $fncounter->decrement( FAMILY_NAMES_SEQS, PENDING_COUNT, FAMILY_NAMES,
        $remove_accs->{$gb_accession} );
      $this->{error_mgr}->printMsg("  Pending Record Removed:  $gb_accession");
      next;
    }
    $this->printRecord( PENDING_FILE, $gb_file->getRecord );
  }
  $gb_file->close;
}

################################################################################
#
#				    Methods
#
################################################################################

sub new {
  my ncbi::Genbank $this = shift;
  my ( $type, $db_queries, $error_mgr, $tools, $utils, $ncbi_utils ) = @_;
  $this = fields::new($this) unless ref($this);

  $this->{add_missing}    = $ncbi_utils->getProperties->{addMissing};
  $this->{counters}       = {};
  $this->{db_date}        = undef;
  $this->{db_queries}     = $db_queries;
  $this->{delete_missing} = $ncbi_utils->getProperties->{deleteMissing};
  $this->{error_mgr}      = $error_mgr;
  $this->{gb_data}        = [];
  $this->{ncbi_utils}     = $ncbi_utils;
  $this->{out_files}      = {};
  $this->{pending_file}   = undef;
  $this->{tools}          = $tools;
  $this->{type}           = $type;
  $this->{utils}          = $utils;

  $this->_setOutFiles(util::Constants::FALSE);
  $this->_setTodayDate;

  $this->{gb_file} =
    new ncbi::GenbankFile( $error_mgr, $tools, $utils, $ncbi_utils );

  $this->{taxons} = new ncbi::Taxonomy( $error_mgr, $tools );
  $this->{taxons}->setTaxonFile( $ncbi_utils->getProperties->{taxonFile} );
  $this->{taxons}->getTaxons;

  my $counters = COUNTERS;
  foreach my $counter ( keys %{$counters} ) {
    $this->createStatistic( $counter, $counters->{$counter} );
  }

  return $this;
}

sub newBase {
  my ncbi::Genbank $this = shift;
  my ( $error_mgr, $tools, $utils, $ncbi_utils ) = @_;
  $this = fields::new($this) unless ref($this);

  $this->{add_missing}    = undef;
  $this->{counters}       = {};
  $this->{db_date}        = undef;
  $this->{db_queries}     = undef;
  $this->{delete_missing} = undef;
  $this->{error_mgr}      = $error_mgr;
  $this->{gb_data}        = [];
  $this->{loaded}         = {};
  $this->{ncbi_utils}     = $ncbi_utils;
  $this->{out_files}      = {};
  $this->{pending_file}   = undef;
  $this->{pending}        = {};
  $this->{taxons}         = undef;
  $this->{tools}          = $tools;
  $this->{type}           = 'base';
  $this->{utils}          = $utils;

  $this->_setOutFiles(util::Constants::TRUE);
  $this->_setTodayDate;

  $this->{gb_file} =
    new ncbi::GenbankFile( $error_mgr, $tools, $utils, $ncbi_utils );

  return $this;
}

sub createStatistic {
  my ncbi::Genbank $this = shift;
  my ( $counter, $data ) = @_;

  my $ncbi_utils = $this->{ncbi_utils};
  my $properties = $ncbi_utils->getProperties;

  my $statistic = undef;
  if ( $counter eq FAMILY_NAMES_COUNTER ) {
    my @tags = ();
    foreach my $index ( 0 .. $#{ $data->{tag} } ) {
      my $ctag = $data->{tag}->[$index];
      my $cord = $data->{ord}->[$index];
      if ( $ctag eq FAMILY_NAMES ) { $cord = $properties->{familyNames}; }
      push( @tags, $ctag, $cord );
    }
    $statistic =
      new util::Statistics( $data->{title}, undef, $this->{error_mgr}, @tags );
  }
  else {
    $statistic =
      new util::Statistics( $data->{title}, undef, $this->{error_mgr},
      $data->{tag}, $data->{ord} );
  }
  $statistic->setCountsToZero;
  $statistic->setShowTotal(util::Constants::FALSE)
    if ( $counter eq MISSING_COUNTER );

  $this->{counters}->{$counter} = $statistic;
}

sub getCounter {
  my ncbi::Genbank $this = shift;
  my ($stats) = @_;

  return $this->{counters}->{$stats};
}

sub printStats {
  my ncbi::Genbank $this = shift;
  my ($stats) = @_;

  my $stat = $this->{counters}->{$stats};
  $stat->print;
  $this->{ncbi_utils}->addReport( $stat->printStr );
}

sub setMissingData {
  my ncbi::Genbank $this = shift;

  #######################
  ### Abstract Method ###
  #######################
  $this->{error_mgr}
    ->printDebug("Abract Method:  ncbi::Genbank::setMissingData");
}

sub process {
  my ncbi::Genbank $this = shift;
  my ($processor) = @_;

  $this->{loaded}  = {};
  $this->{pending} = {};

  my $ncbi_utils  = $this->{ncbi_utils};
  my $properties  = $ncbi_utils->getProperties;
  my $familyNames = $properties->{familyNames};

  $processor->setGenbank($this);
  $processor->processFiles;
  $this->_updatePending;
  $this->printStats(PENDING_FILE);
  $this->printStats(NCBI_FILE);
  my $counts = NCBI_COUNT_ORD;
  foreach my $count ( @{$counts} ) {
    foreach my $counter ( NCBI_FILE, PENDING_FILE ) {
      $this->getCounter(TOTAL_COUNTER)
        ->incrementCount(
        $this->getCounter($counter)->count( NCBI_SEQS, $count ),
        NCBI_SEQS, $count );
    }
  }
  $this->printStats(TOTAL_COUNTER);
  $this->printStats(FAMILY_NAMES_COUNTER) if ( scalar @{$familyNames} > 1 );
  $this->setMissingData;
  $this->printStats(MISSING_COUNTER);
  $processor->processDeletes;
  $ncbi_utils->printReport;
}

sub printRecord {
  my ncbi::Genbank $this = shift;
  my ( $load_type, $record ) = @_;

  my $file = $this->getOutFile($load_type);
  my $fh   = new FileHandle;

  $this->{error_mgr}->exitProgram(
    ERR_CAT, 1,
    [ 'append', $file, "appending record" ],
    !$fh->open( $file, '>>' )
  );
  $fh->autoflush(util::Constants::TRUE);
  $fh->print($record);
  $fh->close;
}

sub printFile {
  my ncbi::Genbank $this = shift;
  my ( $load_type, $file ) = @_;

  my $cmds     = $this->{tools}->cmds;
  my $out_file = $this->getOutFile($load_type);

  $this->{error_mgr}->exitProgram(
    ERR_CAT, 1,
    [ 'check existence', $file, 'file does not exist' ],
    !-e $file || !-f $file || -z $file
  );
  my $file_kind = undef;
  if   ( $file =~ /(\.gz|\.Z)$/ ) { $file_kind = xml::Types::GZIP_FILE_TYPE; }
  else                            { $file_kind = xml::Types::PLAIN_FILE_TYPE; }

  my $cmd = undef;
  if   ( $file_kind eq xml::Types::GZIP_FILE_TYPE ) { $cmd = 'gunzip -c'; }
  else                                              { $cmd = 'cat'; }
  my $msgs = { file => $file, cmd => "$cmd $file >> $out_file", };
  $this->{error_mgr}->exitProgram(
    ERR_CAT, 1,
    [ 'appending', $file, "appending to $out_file", ],
    $cmds->executeCommand( $msgs, $msgs->{cmd}, 'appending file' )
  );
}

sub processRecord {
  my ncbi::Genbank $this = shift;
  my ( $fileType, $record, $struct ) = @_;

  my $counter    = $this->getCounter($fileType);
  my $fncounter  = $this->getCounter(FAMILY_NAMES_COUNTER);
  my $gb_file    = $this->{gb_file};
  my $ncbi_utils = $this->{ncbi_utils};
  my $taxons     = $this->{taxons};

  my $properties = $ncbi_utils->getProperties;

  if ( $gb_file->permissibleStruct($struct) ) {
    ###
    ### Determine taxon id
    ###
    my $attr      = undef;
    my $load_type = undef;
    if ( $properties->{output} eq $ncbi_utils->ALL_VAL ) {
      if ( $taxons->taxonDefined( $struct->{taxon_id} ) ) {
        $attr      = 'loaded';
        $load_type = LOADABLE_COUNT;
      }
      else {
        $attr      = 'pending';
        $load_type = PENDING_COUNT;
      }
    }
    else {    ### $properties->{output} eq $ncbi_utils->PENDING_VAL
      $attr      = 'pending';
      $load_type = PENDING_COUNT;
    }
    $this->_addData( $struct, $fileType, $load_type );
    $counter->increment( NCBI_SEQS, $load_type );
    $fncounter->increment( FAMILY_NAMES_SEQS, $load_type, FAMILY_NAMES,
      $struct->{family_name} );
    $this->{tools}->printStruct( 'sequence record', $struct );
    $this->printRecord( $load_type, $record );
    $this->{$attr}->{ $struct->{gb_accession} } = {
      date        => $struct->{date},
      family_name => $struct->{family_name},
    };
  }
  else {
    $counter->increment( NCBI_SEQS, NOT_LOADABLE_COUNT );
  }
}

sub updatePendingFile {
  my ncbi::Genbank $this = shift;
  ###
  ### Now Update Pending File
  ###
  ### 1.  Make backup current pending file
  ### 2.  Set pending file
  ###
  my $ncbi_utils = $this->{ncbi_utils};
  my $properties = $ncbi_utils->getProperties;
  my $today_date = $properties->{todayDayDate};

  my $cmds = $this->{tools}->cmds;
  my $msgs = {};
  my $backupPendingFile =
    join( util::Constants::DOT, $this->pendingFile, $today_date );
  if ( $ncbi_utils->isMonthly ) {
    $backupPendingFile .= util::Constants::DOT . 'monthly';
  }
  my $sourceFile = $this->getOutFile(PENDING_FILE);
  unlink($backupPendingFile) if ( -e $backupPendingFile );
  $msgs->{cmd} = $cmds->COPY_FILE( $sourceFile, $backupPendingFile );
  $this->{error_mgr}->exitProgram(
    ERR_CAT, 1,
    [
      'copy', $sourceFile,
      "Cannot backup new pending file to $backupPendingFile",
    ],
    $cmds->executeCommand( $msgs, $msgs->{cmd}, 'backup new pending file' )
  );
  unlink( $this->pendingFile ) if ( -e $this->pendingFile );
  $msgs->{cmd} = $cmds->COPY_FILE( $sourceFile, $this->pendingFile );
  $this->{error_mgr}->exitProgram(
    ERR_CAT, 1,
    [
      'copy', $sourceFile,
      "Cannot copy new pending file to " . $this->pendingFile,
    ],
    $cmds->executeCommand( $msgs, $msgs->{cmd}, 'copy pending file' )
  );
}

sub addMissingData {
  my ncbi::Genbank $this = shift;
  my ( $type, $data, $tag ) = @_;

  return if ( !$this->{add_missing} );

  my $insert = $this->{db_queries}->{$type}->{insert};
  $this->{error_mgr}->printHeader( $insert->{name} );

  my $counter = $this->getCounter(MISSING_COUNTER);
  my $db      = $this->{tools}->startTransaction(util::Constants::TRUE);
  my $queries = new util::DbQuery($db);
  $queries->createQuery( $insert->{name}, $insert->{query}, $insert->{name} );
  $queries->prepareQuery( $insert->{name} );
  foreach my $struct ( @{$data} ) {
    my @query_array = ();
    foreach my $col ( @{ $insert->{queryParams} } ) {
      push( @query_array, $struct->{$col} );
    }
    $counter->increment( MISSING_SEQS, $tag );
    $this->{error_mgr}->printMsg( '('
        . join( util::Constants::COMMA_SEPARATOR, @{ $insert->{queryParams} } )
        . ') = ('
        . join( util::Constants::COMMA_SEPARATOR, @query_array )
        . ')' );

    $queries->executeUpdate( $insert->{name}, @query_array );
  }
  $this->{tools}->finalizeTransaction( $insert->{name} );
}

sub deleteData {
  my ncbi::Genbank $this = shift;
  my ($type) = @_;

  return if ( !$this->{delete_missing} );

  my $delete = $this->{db_queries}->{$type}->{delete};
  $this->{error_mgr}->printHeader( $delete->{name} );

  my $db      = $this->{tools}->startTransaction(util::Constants::TRUE);
  my $queries = new util::DbQuery($db);
  $queries->createQuery( $delete->{name}, $delete->{query}, $delete->{name} );
  $queries->prepareQuery( $delete->{name} );
  $queries->executeUpdate( $delete->{name}, $this->dbDate );
  $this->{tools}->finalizeTransaction( $delete->{name} );
}

sub pendingFile {
  my ncbi::Genbank $this = shift;

  return $this->{pending_file};
}

sub gbFile {
  my ncbi::Genbank $this = shift;

  return $this->{gb_file};
}

sub setOutFile {
  my ncbi::Genbank $this = shift;
  my ( $type, $file, $not_reset ) = @_;

  $not_reset =
    ( !util::Constants::EMPTY_LINE($not_reset) && $not_reset )
    ? util::Constants::TRUE
    : util::Constants::FALSE;

  my $ncbi_utils = $this->{ncbi_utils};

  $this->{out_files}->{$type} = $file;
  $ncbi_utils->resetFile( $file, "$type file" ) if ( !$not_reset );

}

sub getOutFile {
  my ncbi::Genbank $this = shift;
  my ($type) = @_;

  return $this->{out_files}->{$type};
}

sub dbDate {
  my ncbi::Genbank $this = shift;

  return $this->{db_date};
}

sub gbData {
  my ncbi::Genbank $this = shift;

  return @{ $this->{gb_data} };
}

################################################################################
1;

__END__

=head1 NAME

Genbank.pm

=head1 SYNOPSIS

  use ncbi::Genbank;

=head1 DESCRIPTION

This class defines a standard mechanism for extracting genbank sequences
records from genbank data and processing them

=head1 METHODS

The following methods are exported by this class.

=head2 B<new ncbi::Genbank(type, db_queries, error_mgr, tools, utils, ncbi_utils)>

This is the constructor for the class.

=cut
