package ncbi::Process::Daily;
######################################################################
#                  Copyright (c) 2012 Northrop Grumman.
#                          All rights reserved.
######################################################################

use strict;

use Pod::Usage;
use parallel::Query;

use util::FileTime;

use base 'ncbi::Process';

################################################################################
#
#				Private Methods
#
################################################################################

sub _processFile {
  my ncbi::Process::Daily $this = shift;
  my ( $fileType, $file ) = @_;

  my $genbank    = $this->genbank;
  my $ncbi_utils = $this->{ncbi_utils};
  my $properties = $ncbi_utils->getProperties;

  my $query = new parallel::Query( undef, $this->{error_mgr}, $this->{tools} );

  my $counter     = $genbank->getCounter($fileType);
  my $daily_query = $properties->{dailyDbQuery};

  $this->{error_mgr}->printHeader(
    "Process File\n" . "  file_type = $fileType\n" . "  file      = $file" );
  return if ( !-e $file || !-f $file || -z $file || !-r $file );

  my $gb_file = $genbank->gbFile;
  $gb_file->open($file);
  while ( !$gb_file->eof ) {
    $gb_file->nextRecord;
    next if ( !$gb_file->recordDefined );
    my $gbRecord     = $gb_file->getRecord;
    my $gbStruct     = $gb_file->getStruct;
    my $gb_accession = $gbStruct->{gb_accession};
    my $gb_date      = $gbStruct->{date};

    if ( $gb_file->permissibleStruct($gbStruct) ) {
      $daily_query->{gb_accession} = $gb_accession;
      my @data = $query->getData($daily_query);
      if (
        scalar @data == 0
        ###
        ### This only happens if the last load was unsuccessful...
        ###
        || !defined( $data[0]->{date} )
        || util::Constants::EMPTY_LINE( $data[0]->{date} )
        )
      {
        $genbank->processRecord( $fileType, $gbRecord, $gbStruct );
      }
      elsif (
        &later_than(
          &get_ncbi_time($gb_date),
          &get_ncbi_time( $data[0]->{date} )
        )
        )
      {
        $genbank->processRecord( $fileType, $gbRecord, $gbStruct );
      }
      else {
        $this->{error_mgr}->printMsg(
"SUPERSEDED BY EXISTING($gb_accession): gb_date = $gb_date, database date = "
            . $data[0]->{date} );
        $counter->increment( $genbank->NCBI_SEQS, $genbank->ALREADY_LOADED );
        next;
      }
    }
    else {
      $genbank->processRecord( $fileType, $gbRecord, $gbStruct );
    }
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
  my ncbi::Process::Daily $this =
    $that->SUPER::new( $error_mgr, $tools, $utils, $ncbi_utils );

  $this->setNcbiFile(
    $ncbi_utils->getFile( 'ncDailyFileZip', $ncbi_utils->getNcMmdd ) );

  return $this;
}

sub processFiles {
  my ncbi::Process::Daily $this = shift;

  my $genbank    = $this->genbank;
  my $ncbi_utils = $this->{ncbi_utils};

  my $properties = $ncbi_utils->getProperties;

  $this->_processFile( $genbank->PENDING_FILE, $genbank->pendingFile );
  return if ( $properties->{process} ne $ncbi_utils->ALL_VAL );
  foreach my $file ( $this->ncbiFiles ) {
    $this->_processFile( $genbank->NCBI_FILE, $file );
  }
}

################################################################################
1;

__END__

=head1 NAME

Daily.pm

=head1 SYNOPSIS

  use ncbi::Process::Daily;

=head1 DESCRIPTION

This class defines a standard mechanism for extracting sequence 
records from daily genbank data and processing them.

=head1 METHODS

The following methods are exported by this class.

=head2 B<new ncbi::Process::Daily(error_mgr, tools, utils, ncbi_utils)>

This is the constructor for the class.

=cut
