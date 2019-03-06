package ncbi::Process::UpdateMonthlyPending;
######################################################################
#                  Copyright (c) 2012 Northrop Grumman.
#                          All rights reserved.
######################################################################

use strict;

use File::Basename;
use Pod::Usage;

use util::Constants;
use util::FileTime;
use util::TableData;

use ncbi::ErrMsgs;

use base 'ncbi::Process';

use fields qw(
  changes
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
### Revised File
###
sub REVISED_FILE { return 'revised'; }
###
### The changes that will be loaded for the monthly
###
sub CHANGE_TYPE { return 'changes'; }

sub ACCESSION_COL { return 'accession'; }
sub CHANGE_COL    { return 'change'; }
sub FILE_COL      { return 'file'; }

sub COLS_ORD { return ( FILE_COL, ACCESSION_COL, CHANGE_COL ); }

sub NEEDS_RELOAD_CHG { return 'reload'; }
sub NEW_LOAD_CHG     { return 'new'; }

################################################################################
#
#				Private Methods
#
################################################################################

sub _determineChanges {
  my ncbi::Process::UpdateMonthlyPending $this = shift;

  $this->{error_mgr}->printHeader("Determining Change Accessions");

  my $ncbi_utils = $this->{ncbi_utils};

  my $change_data =
    new util::TableData( undef, $this->{tools}, $this->{error_mgr} );

  my $type = CHANGE_TYPE;
  my $ord  = [COLS_ORD];

  $change_data->setTableData( $type, $ord );
  my $file = join( util::Constants::SLASH,
    $ncbi_utils->getDataDirectory,
    join( util::Constants::DOT, 'release', $type, 'txt' )
  );
  $change_data->setFile( $type, $file );
  $change_data->setTableInfoRaw($type);

  $this->{changes} = {};
  foreach my $struct ( @{ $change_data->getTableInfo($type) } ) {
    my $acc    = $struct->{accession};
    my $change = $struct->{change};
    my $file   = $struct->{file};
    next
      if !( $file =~ /^gbvrl\d+\.seq\.gz$/
      && ( $change eq 'reload' || $change eq 'new' ) );
    $this->{error_mgr}->printMsg("Using Accession $acc");
    $this->{changes}->{$acc} = util::Constants::EMPTY_STR;
  }
  $this->{tools}->printStruct( 'changes', $this->{changes} );
}

sub _processFile {
  my ncbi::Process::UpdateMonthlyPending $this = shift;
  my ($file) = @_;

  my $changes = $this->{changes};
  my $genbank = $this->genbank;
  my $gb_file = $genbank->gbFile;

  $this->{error_mgr}->printHeader( "Process File\n" . "  file      = $file" );
  return if ( !-e $file || !-f $file || -z $file || !-r $file );

  $gb_file->open($file);
  while ( !$gb_file->eof ) {
    $gb_file->nextRecord;
    next if ( !$gb_file->recordDefined );
    my $struct = $gb_file->getStruct;
    next if ( !defined( $changes->{ $struct->{gb_accession} } ) );
    $genbank->printRecord( REVISED_FILE, $gb_file->getRecord );
  }
  $gb_file->close;
}

sub _processPendingFile {
  my ncbi::Process::UpdateMonthlyPending $this = shift;

  my $genbank = $this->genbank;
  my $file    = $genbank->pendingFile;
  my $gb_file = $genbank->gbFile;

  $this->{error_mgr}
    ->printHeader( "Pre-Process Pending File\n" . "  file      = $file" );
  return if ( !-e $file || !-f $file || -z $file || !-r $file );

  $gb_file->open($file);
  while ( !$gb_file->eof ) {
    $gb_file->nextRecord;
    next if ( !$gb_file->recordDefined );
    $genbank->printRecord( REVISED_FILE, $gb_file->getRecord );
  }
  $gb_file->close;
}

################################################################################
#
#				    Methods
#
################################################################################

sub new {
  my ( $that, $error_mgr, $tools, $utils, $ncbi_utils ) = @_;
  my ncbi::Process::UpdateMonthlyPending $this =
    $that->SUPER::new( $error_mgr, $tools, $utils, $ncbi_utils );

  $this->{changes} = {};

  return $this;
}

sub processFiles {
  my ncbi::Process::UpdateMonthlyPending $this = shift;

  my $genbank = $this->genbank;
  ###
  ### Set Revised Record File
  ###
  $genbank->setOutFile(
    REVISED_FILE,
    join( util::Constants::DOT,
      $genbank->getOutFile( $genbank->PENDING_FILE ), REVISED_FILE
    )
  );
  $this->_determineChanges;
  $this->_processFile( $genbank->getOutFile( $genbank->LOAD_FILE ) );
  $this->_processPendingFile;
}

################################################################################
1;

__END__

=head1 NAME

UpdateMonthlyPending.pm

=head1 SYNOPSIS

  use ncbi::Process::UpdateMonthlyPending;

=head1 DESCRIPTION

This class defines a standard mechanism for extracting sequence records from
monthly genbank gbff file using the monthly release changes file, and prefixing
these to the existing pending file as a revised pending file.

=head1 METHODS

The following methods are exported by this class.

=head2 B<new ncbi::Process::UpdateMonthlyPending(error_mgr, tools, utils, ncbi_utils)>

This is the constructor for the class.

=cut
