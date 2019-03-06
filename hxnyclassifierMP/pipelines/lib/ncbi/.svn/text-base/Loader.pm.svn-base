package ncbi::Loader;
######################################################################
#                  Copyright (c) 2012 Northrop Grumman.
#                          All rights reserved.
######################################################################

use strict;

use Pod::Usage;

use util::Constants;
use util::DbQuery;

use ncbi::ErrMsgs;

use fields qw(
  error_mgr
  error_status
  ncbi_utils
  query_names
  queries
  run_dir
  seq_id_comp
  seq_id_query
  tools
  type
  utils
);

################################################################################
#
#			            Static Class Constants
#
################################################################################
###
### Sequence Id Generator Comp Name
###
sub SEQ_ID_COMP { return 'seq_id' }
###
### Error Category
###
sub ERR_CAT { return ncbi::ErrMsgs::LOADER_CAT; }

################################################################################
#
#				  Private Methods
#
################################################################################

sub _initQueries {
  my ncbi::Loader $this = shift;
  my ($query_names) = @_;

  my $ncbi_utils = $this->{ncbi_utils};
  my $properties = $ncbi_utils->getProperties;

  if ( !util::Constants::EMPTY_LINE( $this->{seq_id_query} ) ) {
    $this->{query_names}->{ $this->{seq_id_query} } =
      util::Constants::EMPTY_STR;
  }

  foreach my $query_name ( @{$query_names} ) {
    $this->{query_names}->{$query_name} = util::Constants::EMPTY_STR;
  }

  my $queries = $this->{queries};
  foreach my $queryName ( sort keys %{ $this->{query_names} } ) {
    $this->{error_mgr}->printHeader("Preparing $queryName");
    my $query = $properties->{$queryName};
    $queries->createQuery( $query->{name}, $query->{query}, $queryName );
    $queries->prepareQuery( $query->{name} );
  }
}

################################################################################
#
#				    Methods
#
################################################################################

sub new {
  my ncbi::Loader $this = shift;
  my ( $type, $seq_id_query, $query_names, $error_mgr, $tools, $utils,
    $ncbi_utils )
    = @_;
  $this = fields::new($this) unless ref($this);

  $this->{error_mgr}    = $error_mgr;
  $this->{ncbi_utils}   = $ncbi_utils;
  $this->{queries}      = new util::DbQuery( $tools->getSession );
  $this->{query_names}  = {};
  $this->{seq_id_comp}  = SEQ_ID_COMP;
  $this->{seq_id_query} = $seq_id_query;
  $this->{tools}        = $tools;
  $this->{type}         = $type;
  $this->{utils}        = $utils;

  $this->_initQueries($query_names);

  return $this;
}

sub setSeqIdComp {
  my ncbi::Loader $this = shift;
  my ($seq_id_comp) = @_;

  $this->{seq_id_comp} = $seq_id_comp;
}

sub executeUpdate {
  my ncbi::Loader $this = shift;
  my ( $queryName, $struct ) = @_;

  my $ncbi_utils  = $this->{ncbi_utils};
  my $queries     = $this->{queries};
  my $query_names = $this->{query_names};
  my $type        = $this->{type};

  my $properties = $ncbi_utils->getProperties;
  my $query      = $properties->{$queryName};

  $this->{error_mgr}
    ->printMsg("($this->{type}) Query Name = $queryName not defined")
    if ( !defined( $query_names->{$queryName} ) );
  return util::Constants::TRUE if ( !defined( $query_names->{$queryName} ) );

  my $status      = util::Constants::FALSE;
  my @query_array = ();
  foreach my $col ( @{ $query->{queryParams} } ) {
    push( @query_array, $struct->{$col} );
  }
  $queries->executeUpdate( $query->{name}, @query_array );
  if ( $queries->queryStatus( $query->{name} ) ) {
    $this->{error_mgr}->registerError( ERR_CAT, 1,
      [ $query->{name}, $struct->{gb_accession}, $struct->{na_sequence_id} ],
      util::Constants::TRUE );
    $status = util::Constants::TRUE;
    $ncbi_utils->addReport( "$type:  ERROR ("
        . $query->{name} . ') '
        . $struct->{gb_accession} . ', '
        . $struct->{na_sequence_id}
        . ")\n" );
  }
  return $status;
}

sub getSeqId {
  my ncbi::Loader $this = shift;
  my ($struct) = @_;

  my $ncbi_utils  = $this->{ncbi_utils};
  my $queries     = $this->{queries};
  my $seq_id_comp = $this->{seq_id_comp};
  my $type        = $this->{type};

  $this->{error_mgr}->printMsg("($this->{type}) Seq id query not defined")
    if ( !defined( $this->{seq_id_query} ) );
  return util::Constants::TRUE if ( !defined( $this->{seq_id_query} ) );

  my $properties = $ncbi_utils->getProperties;
  my $query      = $properties->{ $this->{seq_id_query} };

  my $status = util::Constants::FALSE;
  $queries->executeQuery( $query->{name} );
  if ( $queries->queryStatus( $query->{name} ) ) {
    $this->{error_mgr}->registerError( ERR_CAT, 2,
      [ $query->{name}, $struct->{gb_accession}, $struct->{na_sequence_id} ],
      util::Constants::TRUE );
    $status = util::Constants::TRUE;
    $ncbi_utils->addReport("$type:  ERROR generating sequence id rollback\n");
    return $status;
  }
  while ( my $row_ref = $queries->fetchRowRef( $query->{name} ) ) {
    $struct->{$seq_id_comp} = $row_ref->[0];
  }
  return $status;
}

################################################################################
1;

__END__

=head1 NAME

Loader.pm

=head1 SYNOPSIS

  use ncbi::Loader;

=head1 DESCRIPTION

The ncbi loader class

=head1 METHODS

The following methods are exported by this class.

=head2 B<new ncbi::Loader(error_mgr, tools, utils, ncbi_utils)>

This is the constructor for the class.

=cut
