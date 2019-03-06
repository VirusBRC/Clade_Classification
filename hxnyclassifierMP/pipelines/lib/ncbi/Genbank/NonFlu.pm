package ncbi::Genbank::NonFlu;
######################################################################
#                  Copyright (c) 2012 Northrop Grumman.
#                          All rights reserved.
######################################################################

use strict;

use Pod::Usage;

use util::Constants;

use base 'ncbi::Genbank';

################################################################################
#
#			            Static Class Constants
#
################################################################################
###
### MISSING TABLE DATABASE OPERATIONS
###
sub TAXONOMY { return 'taxonomy'; }

sub DB_QUERIES {
  return {
    &TAXONOMY => {
      delete => {
        name  => 'Missing Taxonomy Delete',
        query => "
delete from dots.daily_vipr_missing_taxonomy
where  file_process_date = to_date(?, 'YYYY-MM-DD')
",
      },

      insert => {
        name        => 'Missing Taxonomy Insert',
        queryParams => [ 'gb_accession', 'taxon_id', 'file_process_date', ],
        query       => "
insert into dots.daily_vipr_missing_taxonomy
  (gb_accession,
   taxon_id,
   record_date,
   file_process_date)
values
  (?, 
   ?, 
   sysdate, 
   to_date(?, 'YYYY-MM-DD'))
",
      },
    },
  };
}

################################################################################
#
#				    Methods
#
################################################################################

sub new {
  my ( $that, $error_mgr, $tools, $utils, $ncbi_utils ) = @_;
  my ncbi::Genbank::NonFlu $this =
    $that->SUPER::new( 'vipr', DB_QUERIES, $error_mgr, $tools, $utils,
    $ncbi_utils );

  return $this;
}

sub setMissingData {
  my ncbi::Genbank::NonFlu $this = shift;

  my $missing = { &TAXONOMY => {}, };
  $this->deleteData( TAXONOMY );
  my $missingData = [];
  foreach my $struct ( $this->gbData ) {
    next
      if (
      !(
           $struct->{file_type} eq $this->NCBI_FILE
        && $struct->{load_type} eq $this->PENDING_COUNT
      )
      );
    my $gb_accession = $struct->{gb_accession};
    next if ( defined( $missing->{&TAXONOMY}->{$gb_accession} ) );
    $missing->{&TAXONOMY}->{$gb_accession} = util::Constants::EMPTY_STR;
    push( @{$missingData}, $struct );
  }
  $this->addMissingData( TAXONOMY, $missingData, $this->MISSING_TAXON_COUNT );
}

################################################################################
1;

__END__

=head1 NAME

NonFlu.pm

=head1 SYNOPSIS

  use ncbi::Genbank::NonFlu;

=head1 DESCRIPTION

This class defines a standard mechanism for extracting non flu (vipr) sequence 
records from genbank data and process them.

=head1 METHODS

The following methods are exported by this class.

=head2 B<new ncbi::Genbank::NonFlu(type, error_mgr, tools, utils, ncbi_utils)>

This is the constructor for the class.

=cut
