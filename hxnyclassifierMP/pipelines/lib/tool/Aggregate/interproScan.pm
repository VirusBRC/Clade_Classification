package tool::Aggregate::interproScan;
################################################################################
#
#				Required Modules
#
################################################################################

use strict;

use Pod::Usage;
use FileHandle;

use util::Constants;
use util::Table;

use tool::ErrMsgs;

use base 'tool::Aggregate';

use fields qw(
  content
  primary_ids_found
  primary_ids_in_mapping
  secondary_ids_added
  secondary_ids_in_mapping
  total_ids_in
  total_ids_out
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
### Counting Results
###
sub PRIMARY_IDS_FOUND        { return 'primary_ids_found'; }
sub PRIMARY_IDS_IN_MAPPING   { return 'primary_ids_in_mapping'; }
sub SECONDARY_IDS_ADDED      { return 'secondary_ids_added'; }
sub SECONDARY_IDS_IN_MAPPING { return 'secondary_ids_in_mapping'; }
sub TOTAL_IDS_IN             { return 'total_ids_in'; }
sub TOTAL_IDS_OUT            { return 'total_ids_out'; }

sub REPORT_ORDER {
  return ( PRIMARY_IDS_IN_MAPPING, SECONDARY_IDS_IN_MAPPING, PRIMARY_IDS_FOUND,
    SECONDARY_IDS_ADDED, TOTAL_IDS_IN, TOTAL_IDS_OUT );
}
###
### Local Properties
###
sub LOCAL_PROPERTIES { return []; }

################################################################################
#
#                           Private Methods
#
################################################################################

sub _readFile {
  my tool::Aggregate::interproScan $this = shift;
  my ($dataFile) = @_;

  $this->{content} = {};
  return util::Constants::FALSE if ( -z $dataFile );

  my $content  = $this->{content};
  my $dataDups = $this->getDataDups;

  my $fh = new FileHandle;
  my $status = !$fh->open( $dataFile, '<' );
  if ($status) {
    $this->{error_mgr}->registerError( ERR_CAT, 7, [$dataFile], $status );
    $this->{tools}->setStatus( $this->{tools}->FAILED );
    return $status;
  }
  while ( !$fh->eof ) {
    my $line = $fh->getline;
    chomp($line);
    next if ( $line =~ /^[ \t]*$/ );
    my $comps = [ split( /\t/, $line ) ];
    my $id = $comps->[0];
    if ( !defined( $content->{$id} ) ) {
      $content->{$id} = {
        lines => [],
        sids  => [],
      };
      $this->{total_ids_in}++;
      $this->{total_ids_out}++;
      $this->{primary_ids_found}++ if ( $this->getDataDups->idInDataDups($id) );
      my @ids = $this->getDataDups->getDupIds($id);
      if ( @ids > 0 ) {
        push( @{ $content->{$id}->{sids} }, @ids );
        $this->{secondary_ids_added} += scalar @ids;
        $this->{total_ids_out}       += scalar @ids;
      }
    }
    push( @{ $content->{$id}->{lines} }, $comps );
  }
  $fh->close;
  return util::Constants::FALSE;
}

################################################################################
#
#                           Public Methods
#
################################################################################

sub new($$$$) {
  my ( $that, $utils, $error_mgr, $tools ) = @_;
  my tool::Aggregate::interproScan $this =
    $that->SUPER::new( 'interproScan', LOCAL_PROPERTIES, $utils, $error_mgr,
    $tools );

  $this->{content}                  = undef;
  $this->{primary_ids_found}        = undef;
  $this->{primary_ids_in_mapping}   = undef;
  $this->{secondary_ids_added}      = undef;
  $this->{secondary_ids_in_mapping} = undef;
  $this->{total_ids_in}             = undef;
  $this->{total_ids_out}            = undef;

  return $this;
}

sub initializeAggregator {
  my tool::Aggregate::interproScan $this = shift;

  $this->{content} = undef;
  foreach my $attr (REPORT_ORDER) { $this->{$attr} = 0; }

  my @ids = $this->getDataDups->getIds;
  $this->{primary_ids_in_mapping} += scalar @ids;
  foreach my $id (@ids) {
    my @sids = $this->getDataDups->getDupIds($id);
    $this->{secondary_ids_in_mapping} += scalar @sids;
  }
  ###
  ### Determine the delete files for family-based output
  ###
  my $familyNames = {};
  foreach my $id ( $this->getFamilyNames->getIds ) {
    my $familyName = $this->getFamilyNames->getFamilyName($id);
    if ( !defined( $familyNames->{$familyName} ) ) {
      my ( $fh, $status ) = $this->getOutputFh( $id, $this->DELETE_TYPE );
      return $status if ($status);
      $familyNames->{$familyName} = $fh;
    }
    $familyNames->{$familyName}->print("$id\n");
  }
  ###
  ### Singleton aggregate File
  ###
  my @fnames = sort keys %{$familyNames};
  if ( scalar @fnames == 0 ) {
    my ( $fh, $status ) = $this->getOutputFh( 0, $this->DELETE_TYPE );
    return $status if ($status);
    foreach my $id ( $this->getDataDups->getIds ) {
      $fh->print("$id\n");
      foreach my $dupId ( $this->getDataDups->getDupIds($id) ) {
        $fh->print("$dupId\n");
      }
    }
    $fh->close;
    return $this->initializeOutputFile( $this->getOutputFile );
  }
  ###
  ### Multiple output files
  ###
  my $familyNamePattern = $this->FAMILYNAMESFILE_PROP;
  foreach my $familyName (@fnames) {
    $familyNames->{$familyName}->close;
    my $fnFile = $this->getOutputFile;
    $fnFile =~ s/$familyNamePattern/$familyName/;
    my $status = $this->initializeOutputFile($fnFile);
    return $status if ($status);
  }
  return util::Constants::FALSE;
}

sub aggregateFile {
  my tool::Aggregate::interproScan $this = shift;
  my ($dataFile) = @_;

  $this->{error_mgr}->printMsg("Processing File");

  my $status = $this->_readFile($dataFile);
  return $status if ($status);

  my $fh = undef;
  foreach my $id ( keys %{ $this->{content} } ) {
    my $data = $this->{content}->{$id};
    ( $fh, $status ) = $this->getOutputFh( $id, $this->AGGREGATE_TYPE );
    next if ($status);
    foreach my $line ( @{ $data->{lines} } ) {
      $fh->print( join( util::Constants::TAB, @{$line} ) . "\n" );
    }
    $fh->close;
    foreach my $sid ( @{ $data->{sids} } ) {
      ( $fh, $status ) = $this->getOutputFh( $sid, $this->AGGREGATE_TYPE );
      next if ($status);
      foreach my $line ( @{ $data->{lines} } ) {
        my @comps = @{$line};
        shift(@comps);
        unshift( @comps, $sid );
        $fh->print( join( util::Constants::TAB, @comps ) . "\n" );
      }
      $fh->close;
    }
  }
  return util::Constants::FALSE;
}

sub postProcess {
  my tool::Aggregate::interproScan $this = shift;

  my $aggregatorType = $this->{aggregator_type};
  my $toolType       = $this->getToolType;

  my %cols = ( counter => 'Counter', total => 'Total' );
  my $table = new util::Table( $this->{error_mgr}, %cols );
  $table->setColumnOrder( 'counter', 'total' );
  $table->setColumnJustification( 'counter', $table->LEFT_JUSTIFY );
  $table->setInHeader(util::Constants::TRUE);
  my @data = ();
  foreach my $counter (REPORT_ORDER) {
    my $struct = {
      counter => $counter,
      total   => $this->{$counter}
    };
    push( @data, $struct );
  }
  $table->setData(@data);
  my $heading =
      "Aggregation Results\n"
    . "  Tool Type       = "
    . $this->getToolType . "\n"
    . "  Aggregator Type = "
    . $this->{aggregator_type};
  $table->generateTable($heading);
}
################################################################################

1;

__END__

=head1 NAME

interproScan.pm

=head1 DESCRIPTION

This concrete class class defines the aggregator for interproscan.

=head1 STATIC CONSTANTS


=head1 METHODS

The following methods are exported by this class.

=head2 B<new tool::Aggregate::interproScan(utils, error_mgr, tools)>

This is the constructor for the class.

=cut
