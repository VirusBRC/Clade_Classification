package ncbi::Taxonomy;
######################################################################
#                  Copyright (c) 2012 Northrop Grumman.
#                          All rights reserved.
######################################################################

use strict;

use FileHandle;
use Getopt::Std;
use Pod::Usage;

use util::Constants;

use parallel::Query;

use ncbi::ErrMsgs;

use fields qw(
  data
  error_mgr
  file
  query
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
sub ERR_CAT { return ncbi::ErrMsgs::TAXONOMY_CAT; }
###
### Standard Taxon Data
###
sub FILE_COL_SEPARATOR { return "\t|\t"; }
sub FILE_ROW_SEPARATOR { return "\t|\n"; }

sub _QUERY_ {
  return {
    maxElements     => 500,
    queryParamSubs  => {},
    queryParams     => [],
    queryResultsOrd => ['taxon_id'],
    queryId         => 'taxon_id',
    query           => "select taxon_id from sres.taxon",
  };
}

################################################################################
#
#				    Methods
#
################################################################################

sub new {
  my ncbi::Taxonomy $this = shift;
  my ( $error_mgr, $tools ) = @_;
  $this = fields::new($this) unless ref($this);

  $this->{data}      = {};
  $this->{error_mgr} = $error_mgr;
  $this->{file}      = undef;
  $this->{query}     = _QUERY_;
  $this->{tools}     = $tools;

  return $this;
}

sub getTaxons {
  my ncbi::Taxonomy $this = shift;

  $this->{data} = {};

  if ( $this->haveTaxonFile ) {
    my $fh                    = new FileHandle;
    my $previousFileSeparator = $/;
    $/ = FILE_ROW_SEPARATOR;
    $fh->open( $this->getTaxonFile, '<' );
    my $col_separator = FILE_COL_SEPARATOR;
    while ( !$fh->eof ) {
      my $line = $fh->getline;
      chomp($line);
      my @comps = split( /$col_separator/, $line );
      $this->{data}->{ $comps[0] } = util::Constants::EMPTY_STR;
    }
    $fh->close;
    $/ = $previousFileSeparator;
    return;
  }
  my $query = new parallel::Query( undef, $this->{error_mgr}, $this->{tools} );
  my @data = $query->getData( $this->{query} );
  $this->{error_mgr}->exitProgram( ERR_CAT, 1, [ $this->{query}->{query}, ],
    $query->getErrorStatus );
  foreach my $struct (@data) {
    $this->{data}->{ $struct->{ $this->{query}->{queryId} } } =
      util::Constants::EMPTY_STR;
  }
}

sub setTaxonFile {
  my ncbi::Taxonomy $this = shift;
  my ($file) = @_;

  $this->{file} = $file;
}

sub getTaxonFile {
  my ncbi::Taxonomy $this = shift;

  return $this->{file};
}

sub haveTaxonFile {
  my ncbi::Taxonomy $this = shift;

  return !util::Constants::EMPTY_LINE( $this->getTaxonFile );
}

sub taxonDefined {
  my ncbi::Taxonomy $this = shift;
  my ($taxon_id) = @_;
  return util::Constants::FALSE
    if ( util::Constants::EMPTY_LINE($taxon_id) || $taxon_id !~ /^\d+$/ );

  my $taxons = $this->{data};
  return defined( $taxons->{$taxon_id} )
    ? util::Constants::TRUE
    : util::Constants::FALSE;
}

################################################################################
1;

__END__

=head1 NAME

Taxonomy.pm

=head1 SYNOPSIS

  use ncbi::Taxonomy;

=head1 DESCRIPTION

The ncbi taxonomy data.

=head1 METHODS

The following methods are exported by this class.

=head2 B<new ncbi::Taxonomy(error_mgr, tools)>

This is the constructor for the class.

=cut
