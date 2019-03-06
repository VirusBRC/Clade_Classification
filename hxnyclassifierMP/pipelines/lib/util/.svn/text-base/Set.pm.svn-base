package util::Set;
################################################################################
#
#				Required Modules
#
################################################################################

use strict;

use Pod::Usage;

use util::Constants;
use util::PerlObject;

use fields qw(
  error_mgr
  elems
  set_name
  sort_type
);

################################################################################
#
#			            Static Class Constants
#
################################################################################
###
### Set Separator
###
sub SET_SEPARATOR { return &util::Constants::COLON x 5; }
###
### Sorting
###
sub LEX_SORT { return 'lex'; }
sub NUM_SORT { return 'num'; }

################################################################################
#
#				Private Methods
#
################################################################################

sub _createKey {
  my util::Set $this = shift;
  my ( $key, $elem ) = @_;

  my $set_separator = SET_SEPARATOR;
  my %els = ( $elem => util::Constants::EMPTY_STR );
  foreach my $el ( split( /$set_separator/, $key ) ) {
    $els{$el} = util::Constants::EMPTY_STR;
  }
  return join( $set_separator, $this->_sortElems( keys %els ) );
}

sub _createSubsets {
  my util::Set $this = shift;
  my ( $set, $num ) = @_;
  $this->{error_mgr}->printDebug("num = $num start");
  my $numsets   = {};
  my $num_1sets = {};
  if ( $num == 1 ) {
    $this->{error_mgr}->printDebug("num = $num continuation");
    foreach my $elem ( keys %{$set} ) {
      $numsets->{$elem} = { $elem => util::Constants::EMPTY_STR };
    }
    $this->{error_mgr}->printDebug("num = $num continuation complete");
  }
  else {
    $this->{error_mgr}->printDebug("num = $num continuation");
    my $num_2sets = {};
    ( $num_1sets, $num_2sets ) = $this->_createSubsets( $set, $num - 1 );
    foreach my $elem ( keys %{$set} ) {
      foreach my $key ( keys %{$num_1sets} ) {
        my $num_1sets = $num_1sets->{$key};
        next if ( defined( $num_1sets->{$elem} ) );
        my $new_key = $this->_createKey( $key, $elem );
        next if ( defined( $numsets->{$new_key} ) );
        my $new_subset = { %{$num_1sets} };
        $new_subset->{$elem} = util::Constants::EMPTY_STR;
        $numsets->{$new_key} = $new_subset;
      }
    }
    foreach my $key ( keys %{$num_2sets} ) {
      $num_1sets->{$key} = $num_2sets->{$key};
    }
    $this->{error_mgr}->printDebug("num = $num continuation complete");
  }

  $this->{error_mgr}->printDebug(
    "num = $num end and num    sets = " . scalar keys %{$numsets} );
  $this->{error_mgr}->printDebug(
    "num = $num end and num -1 sets = " . scalar keys %{$num_1sets} );
  return ( $numsets, $num_1sets );
}

sub _getUniqueSubsets {
  my util::Set $this = shift;
  my ($sets)         = @_;
  my $set_separator  = SET_SEPARATOR;
  my @unique_subsets = ();
  foreach my $key ( sort keys %{$sets} ) {
    my @subset = split( /$set_separator/, $key );
    push( @unique_subsets, [@subset] );
  }
  return @unique_subsets;
}

sub num_sort { $a <=> $b; }

sub _sortElems {
  my util::Set $this = shift;
  my (@elems) = @_;
  return sort @elems if ( $this->{sort_type} eq LEX_SORT );
  return sort util::Set::num_sort @elems if ( $this->{sort_type} eq NUM_SORT );
}

################################################################################
#
#                           Public Methods
#
################################################################################

sub new($$;$) {
  my util::Set $this = shift;
  my ( $error_mgr, $universal_set ) = @_;
  $this = fields::new($this) unless ref($this);
  ###
  ### Initialize the Set
  ###
  $this->{elems}     = {};
  $this->{error_mgr} = $error_mgr;
  $this->{set_name}  = undef;
  $this->{sort_type} = LEX_SORT;

  if ( !util::Constants::EMPTY_LINE($universal_set)
    && ref($universal_set) eq util::PerlObject::ARRAY_TYPE
    && @{$universal_set} > 0 )
  {
    foreach my $elem ( @{$universal_set} ) {
      next if ( util::Constants::EMPTY_LINE($elem) );
      $this->{elems}->{$elem} = util::Constants::EMPTY_STR;
    }
  }

  return $this;
}

################################################################################
#
#			            Public Setter Methods
#
################################################################################

sub setSortType {
  my util::Set $this = shift;
  my ($sort_type) = @_;
  return
    if (
    util::Constants::EMPTY_LINE($sort_type)
    || ( $sort_type ne LEX_SORT
      && $sort_type ne NUM_SORT )
    );
  $this->{sort_type} = $sort_type;
}

sub setSetName {
  my util::Set $this = shift;
  my ($set_name) = @_;
  return if ( util::Constants::EMPTY_LINE($set_name) );
  $this->{set_name} = $set_name;
}

sub addElem ($$) {
  my util::Set $this = shift;
  my ($elem) = @_;
  return if ( util::Constants::EMPTY_LINE($elem) );
  $this->{elems}->{$elem} = util::Constants::EMPTY_STR;
}

sub deleteElem ($$) {
  my util::Set $this = shift;
  my ($elem) = @_;
  return if ( util::Constants::EMPTY_LINE($elem) );
  my $elems = $this->{elems};
  return if ( !defined( $elems->{$elem} ) );
  delete( $elems->{$elem} );
}

################################################################################
#
#			            Public Getter Methods
#
################################################################################

sub size {
  my util::Set $this = shift;
  my @elems = keys %{ $this->{elems} };
  return scalar @elems;
}

sub exists($$) {
  my util::Set $this = shift;
  my ($elem) = @_;
  return util::Constants::FALSE if ( util::Constants::EMPTY_LINE($elem) );
  my $elems = $this->{elems};
  return
    defined( $elems->{$elem} ) ? util::Constants::TRUE : util::Constants::FALSE;
}

sub getElems {
  my util::Set $this = shift;
  return $this->_sortElems( keys %{ $this->{elems} } );
}

sub getSetName {
  my util::Set $this = shift;
  return $this->{set_name};
}

sub getSubsets($) {
  my util::Set $this = shift;
  ###
  ### All the unique subsets (not including the empty set)
  ###
  my ( $numsets, $num_1sets ) =
    $this->_createSubsets( $this->{elems}, $this->size );
  ###
  ### Now create the unique set of subsets
  ###
  my @unique_subsets = $this->_getUniqueSubsets($num_1sets);
  push( @unique_subsets, $this->_getUniqueSubsets($numsets) );

  return @unique_subsets;
}

sub getPairwiseSubsets($) {
  my util::Set $this = shift;
  ###
  ### All the unique subsets (not including the empty set)
  ###
  my ( $numsets, $num_1sets ) = $this->_createSubsets( $this->{elems}, 2 );
  ###
  ### Now create the unique set of subsets
  ###
  return $this->_getUniqueSubsets($numsets);
}

sub intersect($$) {
  my util::Set $this = shift;
  my ($withSet) = @_;

  my @intersection = ();
  return @intersection if ( util::Constants::EMPTY_LINE($withSet) );
  my $ref_type = ref($withSet);
  return @intersection if ( $ref_type !~ /^util::Set/ );
  foreach my $elem ( keys %{ $this->{elems} } ) {
    next if ( !$withSet->exists($elem) );
    push( @intersection, $elem );
  }
  return $this->_sortElems(@intersection);
}

sub intersectWithSets($@) {
  my util::Set $this = shift;
  my (@withSets)     = @_;
  my @intersection   = ();
  return @intersection if ( @withSets == 0 );
  foreach my $withSet (@withSets) {
    return @intersection if ( util::Constants::EMPTY_LINE($withSet) );
    my $ref_type = ref($withSet);
    return @intersection if ( $ref_type !~ /^util::Set/ );
  }
OUTER_LOOP:
  foreach my $elem ( keys %{ $this->{elems} } ) {
    foreach my $withSet (@withSets) {
      next OUTER_LOOP if ( !$withSet->exists($elem) );
    }
    push( @intersection, $elem );
  }
  return $this->_sortElems(@intersection);
}

################################################################################

1;

__END__

=head1 NAME

Set.pm

=head1 DESCRIPTION

This class defines set semantics including the determination of
subsets of a set intersection.

=head1 STATIC CONSTANTS

The following static constants are exported that define the sort order
for elements.

   util::Set::LEX_SORT -- lexiographic sort (default sort order)
   util::Set::NUM_SORT -- numeric sort (for number elements)

=head1 METHODS

The following methods are exported by this class.

=head2 B<new util::Set(error_mgr[, universal_set])>

This is the constructor for the class.  The initial universal set is a
referenced Perl array of all the elements of the the set (only those
elements that are defined and are not empty).  If this parameter
undefined or empty, then the initial state of the class is the empty
set.  The default sort_type of the elements of the set is lexiographic
(B<LEX_SORT>).

=head1 SETTER METHODS

The following setter methods are exported

=head2 B<setSortType(sort_type)>

This method set the sorting typing for the set.  There are two sort types:

   util::Set::LEX_SORT -- lexiographic sort (default)
   util::Set::NUM_SORT -- numeric sort (numerical sort order)

=head2 B<setSetName(set_name)>

This method sets the optional set name, if set_name is defined and not
empty.

=head2 B<addElem(elem)>

This method adds the element to the set.  The elem must be defined and
not empty.  If it already exists, then no action is taken.

=head2 B<deleteElem(elem)>

This method deletes an element from the set, if it exists in the set.
Otherwise, no action is taken.

=head1 GETTER METHODS

The following getter methods are exported.

=head2 <exists(elem)>

This method return TRUE(1) if the elem exists in the set, otherwise
it returns FALSE(0).

=head2 <set_size = size>

This method returns the size of the set.

=head2 <$set_name = getSetName>

This method returns the set_name;

=head2 <@elems = getElems>

This method returns the unique set of elements currently defining the
set.  They are sorted according to the sort_type set for this set.

=head2 <@subsets = getSubsets>

The method returns the list of all distinct (non-empty) subsets of the
elements in the set.  Each element of the list is a referenced Perl
array of the elements of a subset of the set.  The list of subsets is
lexiographically sort ordered by the elements in the subsets. 

=head2 <@pairwise_subsets = getPairwiseSubsets>

This method returns the List of distinct subsets of size two (2) of
the elements in the set, where each item in the list is a referenced
Perl array of two elements of the list.  The list of subsets is
lexiographically sort ordered by the elements in the subsets.

=head2 <@elems = intersect(withSet)

This method takes an object of type B<util::Set>, B<withSet>, and
intersects it with this set and returns the list of common elements.

=head2 <@elems = intersectWithSets(@withSets)

This method takes an list of objects of type B<util::Set>,
B<@withSet>, and intersects them with this set and returns the list of
common elements.  If any of the sets is undefined or not a set, then
the intersection will be empty.

=cut
