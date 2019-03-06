package ncbi::Genbank::Flu;
######################################################################
#                  Copyright (c) 2012 Northrop Grumman.
#                          All rights reserved.
######################################################################

use strict;

use Pod::Usage;

use util::Constants;

use ncbi::InfluenzaNa;

use base 'ncbi::Genbank';

use fields qw(
  flu_accs
);

################################################################################
#
#			            Static Class Constants
#
################################################################################
###
### MISSING TABLE DATABASE OPERATIONS
###
sub INFLUENZA { return 'influenza'; }
sub TAXONOMY  { return 'taxonomy'; }

sub DB_QUERIES {
  return {
    &INFLUENZA => {
      delete => {
        name  => 'Missing Flu Delete',
        query => "
delete from dots.daily_flu_missing_influ_na
where  flu_file_process_date = to_date(?, 'YYYY-MM-DD')
",
      },

      insert => {
        name        => 'Missing Flu Insert',
        queryParams => [ 'gb_accession', 'file_process_date', ],
        query       => "
insert into dots.daily_flu_missing_influ_na
  (gb_accession,
   record_date,
   flu_file_process_date)
values
  (?, 
   sysdate, 
   to_date(?, 'YYYY-MM-DD'))
",
      },
    },

    &TAXONOMY => {
      delete => {
        name  => 'Missing Taxonomy Delete',
        query => "
delete from dots.daily_flu_missing_taxonomy
where  flu_file_process_date = to_date(?, 'YYYY-MM-DD')
",
      },

      insert => {
        name        => 'Missing Taxonomy Insert',
        queryParams => [ 'gb_accession', 'taxon_id', 'file_process_date', ],
        query       => "
insert into dots.daily_flu_missing_taxonomy
  (gb_accession,
   taxon_id,
   record_date,
   flu_file_process_date)
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
  my ncbi::Genbank::Flu $this =
    $that->SUPER::new( 'flu', DB_QUERIES, $error_mgr, $tools, $utils,
    $ncbi_utils );

  $this->{flu_accs} =
    new ncbi::InfluenzaNa( $error_mgr, $tools, $utils, $ncbi_utils );

  return $this;
}

sub setMissingData {
  my ncbi::Genbank::Flu $this = shift;

  my $missing = {
    &INFLUENZA => {},
    &TAXONOMY  => {},
  };
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

  $this->deleteData( INFLUENZA );
  $missingData = [];
  foreach my $struct ( $this->gbData ) {
    next
      if (
      !(
        $struct->{load_type} eq $this->LOADABLE_COUNT
        && !$this->{flu_accs}->accDefined( $struct->{gb_accession} )
      )
      );
    my $gb_accession = $struct->{gb_accession};
    next if ( defined( $missing->{&INFLUENZA}->{$gb_accession} ) );
    $missing->{&INFLUENZA}->{$gb_accession} = util::Constants::EMPTY_STR;
    push( @{$missingData}, $struct );
  }
  $this->addMissingData( INFLUENZA, $missingData, $this->MISSING_FLU_COUNT );
}

################################################################################
1;

__END__

=head1 NAME

Flu.pm

=head1 SYNOPSIS

  use ncbi::Genbank::Flu;

=head1 DESCRIPTION

This class defines a standard mechanism for extracting flu sequences
records from genbank data and process them

=head1 METHODS

The following methods are exported by this class.

=head2 B<new ncbi::Genbank::Flu(type, error_mgr, tools, utils, ncbi_utils)>

This is the constructor for the class.

=cut
