package ncbi::DatabaseSequences;
######################################################################
#                  Copyright (c) 2012 Northrop Grumman.
#                          All rights reserved.
######################################################################

use strict;

use FileHandle;
use Pod::Usage;

use util::Constants;
use util::FileTime;
use util::Table;

use parallel::Query;

use ncbi::ErrMsgs;

use fields qw(
  data
  date_col
  description_col
  error_mgr
  ncbi_utils
  properties
  query
  taxon_col
  tools
);

################################################################################
#
#			            Static Class Constants
#
################################################################################
###
### Error Category
###
sub ERR_CAT { return ncbi::ErrMsgs::DATABASESEQUENCES_CAT; }

################################################################################
#
#				    Methods
#
################################################################################

sub new {
  my ncbi::DatabaseSequences $this = shift;
  my ( $error_mgr, $tools, $ncbi_utils ) = @_;
  $this = fields::new($this) unless ref($this);

  my $properties = $ncbi_utils->getProperties;
  $this->{data}       = {};
  $this->{error_mgr}  = $error_mgr;
  $this->{ncbi_utils} = $ncbi_utils;
  $this->{properties} = $properties->{dbProperties};
  $this->{query}      = $properties->{dbQuery};
  $this->{tools}      = $tools;

  $this->{date_col}        = $this->{query}->{dateCol};
  $this->{description_col} = $this->{query}->{descriptionCol};
  $this->{taxon_col}       = $this->{query}->{taxonCol};

  return $this;
}

sub getData {
  my ncbi::DatabaseSequences $this = shift;

  my $ncbi_utils = $this->{ncbi_utils};
  my $properties = $ncbi_utils->getProperties;

  $this->{data} = {};

  my $query = new parallel::Query( undef, $this->{error_mgr}, $this->{tools} );
  foreach my $property ( @{ $this->{properties} } ) {
    $this->{query}->{$property} = $properties->{$property};
  }
  my @data = $query->getData( $this->{query} );
  $this->{error_mgr}->exitProgram( ERR_CAT, 1, [ $this->{query}->{query}, ],
    $query->getErrorStatus );
  foreach my $struct (@data) {
    $this->{data}->{ $struct->{ $this->{query}->{queryId} } } = $struct;
  }
}

sub write {
  my ncbi::DatabaseSequences $this = shift;
  my ($file) = @_;

  my %cols = ();
  foreach my $col ( @{ $this->{query}->{queryResultsOrd} } ) {
    $cols{$col} = $col;
  }
  my $table = new util::Table( $this->{error_mgr}, %cols );
  $table->setColumnOrder( @{ $this->{query}->{queryResultsOrd} } );
  $table->setData( values %{ $this->{data} } );
  $table->generateTabFile($file);
}

sub gbAccDefined {
  my ncbi::DatabaseSequences $this = shift;
  my ($gbAcc) = @_;

  my $data = $this->{data};
  return defined( $data->{$gbAcc} )
    ? util::Constants::TRUE
    : util::Constants::FALSE;
}

sub getGbAccComponent {
  my ncbi::DatabaseSequences $this = shift;
  my ( $gbAcc, $component ) = @_;

  return undef if ( !$this->gbAccDefined($gbAcc) );
  my $data = $this->{data}->{$gbAcc};
  return $data->{$component};
}

sub gbAccLater {
  my ncbi::DatabaseSequences $this = shift;
  my ( $gbAcc, $date ) = @_;

  return util::Constants::FALSE
    if ( util::Constants::EMPTY_LINE($gbAcc)
    || util::Constants::EMPTY_LINE($date) );
  return util::Constants::TRUE if ( !$this->gbAccDefined($gbAcc) );
  my $data = $this->{data}->{$gbAcc};
  return util::Constants::TRUE
    if ( util::Constants::EMPTY_LINE( $data->{ $this->dateCol } )
    || util::Constants::EMPTY_LINE( $data->{ $this->taxonCol } ) );
  return &later_than( &get_ncbi_time($date),
    &get_str_date( $data->{ $this->dateCol } ) );
}

sub getAccs {
  my ncbi::DatabaseSequences $this = shift;

  return sort keys %{ $this->{data} };
}

sub dateCol {
  my ncbi::DatabaseSequences $this = shift;
  return $this->{date_col};
}

sub descriptionCol {
  my ncbi::DatabaseSequences $this = shift;
  return $this->{description_col};
}

sub taxonCol {
  my ncbi::DatabaseSequences $this = shift;
  return $this->{taxon_col};
}

################################################################################
1;

__END__

=head1 NAME

DatabaseSequences.pm

=head1 SYNOPSIS

  use ncbi::DatabaseSequences;

=head1 DESCRIPTION

The ncbi sequences of interest.

=head1 METHODS

The following methods are exported by this class.

=head2 B<new ncbi::DatabaseSequences(error_mgr, tools, ncbi_utils)>

This is the constructor for the class.

=cut
