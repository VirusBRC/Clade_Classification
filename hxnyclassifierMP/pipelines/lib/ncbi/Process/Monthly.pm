package ncbi::Process::Monthly;
######################################################################
#                  Copyright (c) 2012 Northrop Grumman.
#                          All rights reserved.
######################################################################

use strict;

use File::Basename;
use Pod::Usage;

use util::Constants;
use util::FileTime;
use util::Table;

use ncbi::DatabaseSequences;
use ncbi::ErrMsgs;

use base 'ncbi::Process';

use fields qw(
  changes
  db_data
  db_queries
  delete_accs
  obsoletes
  pending_records
  process_obsolete
);

################################################################################
#
#				Private Constants
#
################################################################################
###
### Error Category
###
sub ERR_CAT { return ncbi::ErrMsgs::MONTHLY_CAT; }
###
### Obsolete Counter
###
sub OBSOLETE_COUNTER   { return 'obsolete'; }
sub NOT_OBSOLETE_COUNT { return 'not obsolete'; }
sub OBSOLETE_COUNT     { return 'obsolete'; }
sub OBSOLETE_ORD       { return [ NOT_OBSOLETE_COUNT, OBSOLETE_COUNT ]; }

sub OBSOLETE_COUNTERS {
  return {
    title => "Obsolete Accessions Counts",
    tag   => OBSOLETE_COUNTER,
    ord   => OBSOLETE_ORD,
  };
}
###
### The changes that will be loaded for the monthly
### and
### the obsoletes that are processed for the monthly
###
sub CHANGE_TYPE   { return 'changes'; }
sub OBSOLETE_TYPE { return 'obsoletes'; }

sub ACCESSION_COL { return 'accession'; }
sub CHANGE_COL    { return 'change'; }
sub FILE_COL      { return 'file'; }

sub COLS_ORD { return ( FILE_COL, ACCESSION_COL, CHANGE_COL ); }

sub NEEDS_RELOAD_CHG { return 'reload'; }
sub NEW_LOAD_CHG     { return 'new'; }
sub OBSOLETE_CHG     { return 'obsoleted'; }
###
### Out Files
###
sub ALL_SEQ { return 'all_seq'; }
sub ALL_GB  { return 'all_gb'; }

sub ALL_MAP {
  return {
    &ALL_SEQ => 'monthlyAllSeqFile',
    &ALL_GB  => 'monthlyAllGBFile',
  };
}
###
### Obsolete Queries
###
sub INSERT_QUERY        { return 'insert'; }
sub NAENTRY_QUERY       { return 'update_naentry'; }
sub NASEQUENCEIMP_QUERY { return 'update_nasequenceimp'; }
sub DELETE_QUERY        { return 'delete'; }

sub OBSOLETE_DB_QUERIES {
  return {
    &DELETE_QUERY => {
      name   => 'Delete Table Contents',
      params => [],
      query  => "
delete from dots.obsolete_accession
",
    },

    &INSERT_QUERY => {
      name   => 'Obsolete Flu Accession Insert',
      params => [ 'gb_accession', ],
      query  => "
insert into dots.obsolete_accession
  (accession)
values
  (?)
",
    },

    &NAENTRY_QUERY => {
      name   => 'Updating NaEntry Table',
      params => [ 'source_id', 'gb_accession', ],
      query  => "
update dots.naentry 
set    source_id = ?
where  source_id = ?
",
    },

    &NASEQUENCEIMP_QUERY => {
      name   => 'Update NaSequenceImp Table',
      params => [ 'obsolete_date', 'gb_accession', ],
      query  => "
update dots.nasequenceimp
set    obsolete_date  = to_date(?,'YYMMDD.HH24MISS')
where  string1        = ?
and    obsolete_date is null
",
    },
  };
}

################################################################################
#
#				Private Methods
#
################################################################################

sub _generateReport {
  my ncbi::Process::Monthly $this = shift;
  my ($type) = @_;

  my $ncbi_utils = $this->{ncbi_utils};

  my @ord  = COLS_ORD;
  my %cols = ();
  foreach my $col (@ord) { $cols{$col} = $col; }
  my $table = new util::Table( $this->{error_mgr}, %cols );
  $table->setColumnOrder(@ord);
  $table->setRowOrder( 'sub {$a->{file} cmp $b->{file} '
      . 'or $a->{accession} cmp $b->{accession};}' );
  $table->setData( @{ $this->{$type} } );
  my $file = join( util::Constants::SLASH,
    $ncbi_utils->getDataDirectory,
    join( util::Constants::DOT, 'release', $type, 'txt' )
  );
  $table->generateTabFile($file);
}

sub _setGBFiles {
  my ncbi::Process::Monthly $this = shift;

  my $genbank    = $this->genbank;
  my $ncbi_utils = $this->{ncbi_utils};

  my $all_map = ALL_MAP;
  foreach my $type ( keys %{$all_map} ) {
    my $file = $ncbi_utils->getProperties->{ $all_map->{$type} };
    $genbank->setOutFile( $type,
      join( util::Constants::SLASH, $ncbi_utils->getDataDirectory, $file ) );
  }
}

sub _setDeleteFile {
  my ncbi::Process::Monthly $this = shift;

  my $ncbi_utils = $this->{ncbi_utils};
  my $db_data    = $this->{db_data};
  my $del_files  = $ncbi_utils->getFiles('monthlyDeleteFilePatterns');
  my $utils      = $this->{utils};

  $this->{error_mgr}->exitProgram(
    ERR_CAT, 2,
    [ $ncbi_utils->getProperties->{monthlyDeleteFile}, ],
    scalar @{$del_files} != 1
  );
  my $deletes_file = $del_files->[0];
  $this->{error_mgr}->printHeader("Getting Deletes\n  file = $deletes_file");
  my $fh = $utils->openFile( $deletes_file, '<' );
  $this->{delete_accs} = {};

  while ( !$fh->eof ) {
    my $line = $fh->getline;
    chomp($line);
    my ( $file_name, $accession ) = split( /\|/, $line );
    next if ( !$db_data->gbAccDefined($accession) );
    $this->{delete_accs}->{$accession} = 'gb' . lc($file_name) . '.seq.gz';
    $this->{error_mgr}
      ->printMsg( "($accession, " . $this->{delete_accs}->{$accession} . ")" );
  }

  $fh->close;
}

sub _preprocessPendingFile {
  my ncbi::Process::Monthly $this = shift;

  $this->{pending_records} = {};

  my $genbank         = $this->genbank;
  my $file            = $genbank->pendingFile;
  my $gb_file         = $genbank->gbFile;
  my $pending_records = $this->{pending_records};

  $this->{error_mgr}
    ->printHeader( "Pre-Process Pending File\n" . "  file      = $file" );
  return if ( !-e $file || !-f $file || -z $file || !-r $file );

  $gb_file->open($file);
  while ( !$gb_file->eof ) {
    $gb_file->nextRecord;
    next if ( !$gb_file->recordDefined );
    my $struct       = $gb_file->getStruct;
    my $gb_accession = $struct->{gb_accession};
    if ( !defined( $pending_records->{$gb_accession} ) ) {
      $pending_records->{$gb_accession} = {
        processed => util::Constants::FALSE,
        data      => [],
        date      => undef,
      };
    }
    push(
      @{ $pending_records->{$gb_accession}->{data} },
      {
        record => $gb_file->getRecord,
        struct => $struct,
      }
    );
    $pending_records->{$gb_accession}->{date} = $struct->{date};
  }
  $gb_file->close;
}

sub _processFile {
  my ncbi::Process::Monthly $this = shift;
  my ($file) = @_;

  my $genbank = $this->genbank;

  $genbank->printFile( ALL_GB, $file );

  my $fileType = $genbank->NCBI_FILE;
  my $changes  = $this->{changes};
  $this->{error_mgr}->printHeader(
    "Process File\n" . "  file_type = $fileType\n" . "  file      = $file" );
  return if ( !-e $file || !-f $file || -z $file || !-r $file );

  my $counter         = $genbank->getCounter($fileType);
  my $db_data         = $this->{db_data};
  my $pending_records = $this->{pending_records};

  my $gb_file = $genbank->gbFile;
  $gb_file->open($file);
  while ( !$gb_file->eof ) {
    $gb_file->nextRecord;
    next if ( !$gb_file->recordDefined );
    my $struct = $gb_file->getStruct;
    my $record = $gb_file->getRecord;
    if ( $gb_file->permissibleStruct($struct) ) {
      $genbank->printRecord( ALL_SEQ, $record );
      my $gb_accession = $struct->{gb_accession};
      my $gb_date      = $struct->{date};
      my $pending_data = $pending_records->{$gb_accession};
      if ( defined($pending_data) ) {
        ###
        ### Process pending records first
        ###
        foreach my $datum ( @{ $pending_data->{data} } ) {
          $genbank->processRecord( $genbank->PENDING_FILE, $datum->{record},
            $datum->{struct} );
        }
        $pending_data->{processed} = util::Constants::TRUE;
        if (
          !&later_than(
            &get_ncbi_time($gb_date),
            &get_ncbi_time( $pending_data->{date} )
          )
          )
        {
          $this->{error_mgr}->printMsg(
"SUPERSEDED BY PENDING($gb_accession):  gb_date = $gb_date, pending_date = "
              . $pending_data->{date} );
          $counter->increment( $genbank->NCBI_SEQS, $genbank->ALREADY_LOADED );
          next;
        }
      }
      ###
      ### Now process monthly record based on what is in the database
      ###
      my $chg_struct = {
        &ACCESSION_COL => $gb_accession,
        &FILE_COL      => basename($file),
      };
      if ( $db_data->gbAccDefined($gb_accession) ) {
        if ( $db_data->gbAccLater( $gb_accession, $gb_date ) ) {
          $this->{error_mgr}->printMsg(
            "NEEDS RELOAD($gb_accession):  gb_date = $gb_date, db_date = "
              . $db_data->getGbAccComponent( $gb_accession, $db_data->dateCol )
          );
          $chg_struct->{&CHANGE_COL} = NEEDS_RELOAD_CHG;
          push( @{$changes}, $chg_struct );
        }
        else {
          $this->{error_mgr}
            ->printMsg("ALREADY LOADED($gb_accession):  gb_date = $gb_date");
          $counter->increment( $genbank->NCBI_SEQS, $genbank->ALREADY_LOADED );
          next;
        }
      }
      else {
        $chg_struct->{&CHANGE_COL} = NEW_LOAD_CHG;
        push( @{$changes}, $chg_struct );
      }
    }
    $genbank->processRecord( $fileType, $record, $struct );
  }
  $gb_file->close;
}

sub _processPending {
  my ncbi::Process::Monthly $this = shift;
  ###
  ### Now process the remaing pending record not processed above
  ###
  my $genbank  = $this->genbank;
  my $fileType = $genbank->PENDING_FILE;
  $this->{error_mgr}->printHeader( "Process Rest of Pending File\n"
      . "  file_type = $fileType\n"
      . "  file      = "
      . $genbank->pendingFile );
  my $pending_records = $this->{pending_records};
  foreach my $gb_accession ( keys %{$pending_records} ) {
    my $pending_data = $pending_records->{$gb_accession};
    next if ( $pending_data->{processed} );
    foreach my $datum ( @{ $pending_data->{data} } ) {
      $genbank->processRecord( $fileType, $datum->{record}, $datum->{struct} );
    }
    $pending_data->{processed} = util::Constants::TRUE;
  }
}

sub _getParams {
  my ncbi::Process::Monthly $this = shift;
  my ( $query, $data ) = @_;

  my $db_query = $this->{db_queries}->{$query};
  my @params   = ();
  foreach my $col ( @{ $db_query->{params} } ) {
    push( @params, $data->{$col} );
  }
  return @params;
}

sub _obsoleteData {
  my ncbi::Process::Monthly $this = shift;
  my ($gb_accs) = @_;

  return if ( !$this->{process_obsolete} );

  $this->{error_mgr}->printHeader("Processing Deletes");
  my $db      = $this->{tools}->startTransaction;
  my $queries = new util::DbQuery($db);
  foreach my $query ( keys %{ $this->{db_queries} } ) {
    my $db_query = $this->{db_queries}->{$query};
    $queries->createQuery( $query, $db_query->{query}, $db_query->{name} );
    $queries->prepareQuery($query);
  }
  $this->{error_mgr}->printMsg("Deleting Table Contents Table");
  $queries->executeUpdate(DELETE_QUERY);
  $this->{error_mgr}->printMsg("Performing Obsolescence");
  foreach my $gb_accession ( sort keys %{$gb_accs} ) {
    $this->{error_mgr}->printMsg("  $gb_accession");
    my $data = $gb_accs->{$gb_accession};
    $queries->executeUpdate( INSERT_QUERY,
      $this->_getParams( INSERT_QUERY, $data ) );
    $queries->executeUpdate( NAENTRY_QUERY,
      $this->_getParams( NAENTRY_QUERY, $data ) );
    $queries->executeUpdate( NASEQUENCEIMP_QUERY,
      $this->_getParams( NASEQUENCEIMP_QUERY, $data ) );
  }
  $this->{tools}->finalizeTransaction('Obsolete Accession');
}

################################################################################
#
#				    Methods
#
################################################################################

sub new {
  my ( $that, $error_mgr, $tools, $utils, $ncbi_utils ) = @_;
  my ncbi::Process::Monthly $this =
    $that->SUPER::new( $error_mgr, $tools, $utils, $ncbi_utils );

  $this->{changes} = [];
  $this->{db_data} =
    new ncbi::DatabaseSequences( $error_mgr, $tools, $ncbi_utils );
  $this->{db_queries}       = OBSOLETE_DB_QUERIES;
  $this->{delete_accs}      = {};
  $this->{obsoletes}        = [];
  $this->{pending_records}  = {};
  $this->{process_obsolete} = $ncbi_utils->getProperties->{processObsolete};

  $this->{db_data}->getData;
  $this->_setDeleteFile;

  foreach my $file ( @{ $ncbi_utils->getFiles('monthlyFilePatterns') } ) {
    $this->setNcbiFile($file);
  }

  $this->{db_data}->write(
    join( util::Constants::SLASH,
      $ncbi_utils->getDataDirectory,
      'influenza.dat'
    )
  );

  return $this;
}

sub processFiles {
  my ncbi::Process::Monthly $this = shift;

  my $genbank    = $this->genbank;
  my $ncbi_utils = $this->{ncbi_utils};
  ###
  ### Always process all data and output to all outputs
  ###
  my $properties = $ncbi_utils->getProperties;
  $properties->{output}  = $ncbi_utils->ALL_VAL;
  $properties->{process} = $ncbi_utils->ALL_VAL;

  $genbank->createStatistic( OBSOLETE_COUNTER, OBSOLETE_COUNTERS );
  $this->_setGBFiles;

  $this->{changes} = [];

  $this->_preprocessPendingFile;
  foreach my $file ( $this->ncbiFiles ) { $this->_processFile($file); }
  $this->_processPending;
  $this->_generateReport(CHANGE_TYPE);
}

sub processDeletes {
  my ncbi::Process::Monthly $this = shift;

  my $genbank = $this->genbank;

  my $ncbi_utils  = $this->{ncbi_utils};
  my $delete_accs = $this->{delete_accs};
  my $db_data     = $this->{db_data};
  my $counter     = $genbank->getCounter(OBSOLETE_COUNTER);

  $this->{obsoletes} = [];
  my $obsoletes = $this->{obsoletes};

  my $obsolete_date = $ncbi_utils->getCmd("date +'%y%m%d.%H%M%S'");

  $this->{error_mgr}->printHeader("Determining Obsolete Accessions");
  my $gb_accs = {};
  foreach my $gb_accession ( $db_data->getAccs ) {
    $counter->increment( OBSOLETE_COUNTER,
      defined( $delete_accs->{$gb_accession} )
      ? OBSOLETE_COUNT
      : NOT_OBSOLETE_COUNT );
    next if ( !defined( $delete_accs->{$gb_accession} ) );
    push(
      @{$obsoletes},
      {
        &ACCESSION_COL => $gb_accession,
        &FILE_COL      => $delete_accs->{$gb_accession},
        &CHANGE_COL    => OBSOLETE_CHG,
      }
    );
    $gb_accs->{$gb_accession} = {
      gb_accession  => $gb_accession,
      obsolete_date => $obsolete_date,
      source_id =>
        join( util::Constants::DOT, $gb_accession, 'OBSOLETE', $obsolete_date ),
    };
    $this->{error_mgr}->printMsg(
      "  $gb_accession (" . $gb_accs->{$gb_accession}->{source_id} . ")" );
  }
  $this->_obsoleteData($gb_accs);
  $genbank->printStats(OBSOLETE_COUNTER);
  $this->_generateReport(OBSOLETE_TYPE);
}

################################################################################
1;

__END__

=head1 NAME

Monthly.pm

=head1 SYNOPSIS

  use ncbi::Process::Monthly;

=head1 DESCRIPTION

This class defines a standard mechanism for extracting sequence 
records from monthly genbank data and processing them.

=head1 METHODS

The following methods are exported by this class.

=head2 B<new ncbi::Process::Monthly(error_mgr, tools, utils, ncbi_utils)>

This is the constructor for the class.

=cut
