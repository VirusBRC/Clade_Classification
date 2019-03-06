package util::Statistics;
################################################################################
#
#				Required Modules
#
################################################################################

use strict;
use Pod::Usage;

use util::Constants;
use util::ErrMsgs;
use util::PerlObject;
use util::Table;

use fields qw(
  count_col
  epilogue
  error_mgr
  header
  item
  last_rows
  show_total
  table
  tag_order
  tags
);

################################################################################
#
#				   Constants
#
################################################################################
###
### Item ID Separator
###
my $TAG_SEPARATOR = '~,~';
###
### Formating Constants
###
sub COUNT { return 'COUNT'; }
sub TOTAL { return 'TOTAL'; }
###
### Error Category
###
sub ERR_CAT { return util::ErrMsgs::STATS_CAT; }

################################################################################
#
#			       Private Static Methods
#
################################################################################

sub GET_BLANKS {
  my ( $col_width, $col_name ) = @_;
  my $blank = util::Constants::SPACE;
  return $blank x ( $col_width - length($col_name) );
}

################################################################################
#
#				Private Methods
#
################################################################################

sub _createTable {
  my util::Statistics $this = shift;
  my (@tags_to_use) = @_;

  my %cols = ( &COUNT => $this->{count_col} );
  my @ord = ();
  foreach my $col (@tags_to_use) {
    $cols{"$col"} = $col;
    push( @ord, $col );
  }
  push( @ord, COUNT );

  $this->{table} = new util::Table( $this->{error_mgr}, %cols );
  $this->{table}->setColumnOrder(@ord);
  my $index   = 0;
  my $ord_fcn = "sub {";
  foreach my $index ( 0 .. $#tags_to_use ) {
    my $col = $tags_to_use[$index];
    $this->{table}->setColumnJustification( $col, util::Table::LEFT_JUSTIFY );
    if ( $index > 0 ) { $ord_fcn .= ' or '; }
    $ord_fcn .=
      '$a->{' . "'" . $col . "'" . '} cmp $b->{' . "'" . $col . "'" . '}';
  }
  $ord_fcn .= ";}";
  $this->{table}->setRowOrder($ord_fcn);
  $this->{table}->setInHeader(util::Constants::TRUE);
}

sub _createStruct {
  my util::Statistics $this = shift;

  my $struct = { &COUNT => util::Constants::EMPTY_STR };
  foreach my $col ( @{ $this->{tag_order} } ) {
    $struct->{"$col"} = util::Constants::EMPTY_STR;
  }
  return $struct;
}

sub _generateLastRows {
  my util::Statistics $this = shift;
  my ( $last_tag, $last_col_len, $count ) = @_;

  return if ( !$this->{show_total} );
  ###
  ### Summary total underline row
  ###
  my $struct = $this->_createStruct;
  $struct->{&COUNT} = &util::Constants::HYPHEN x length( $this->{count_col} );
  push( @{ $this->{last_rows} }, $struct );
  ###
  ### Summary total row
  ###
  $struct = $this->_createStruct;
  $struct->{"$last_tag"} = &GET_BLANKS( $last_col_len, TOTAL ) . &TOTAL;
  $struct->{&COUNT} = $count;
  push( @{ $this->{last_rows} }, $struct );
}

sub _getTagId {
  my util::Statistics $this = shift;
  my ( $ignore_missing_tag, @tag_data ) = @_;

  $this->{error_mgr}
    ->exitProgram( ERR_CAT, 4, [], @tag_data > 0 && @tag_data % 2 != 0 );
  ###
  ### Make sure all tags are part of this item
  ###
  my $tags = {};
  while ( @tag_data != 0 ) {
    my $tag      = shift(@tag_data);
    my $key      = shift(@tag_data);
    my $tag_vals = $this->{tags}->{$tag};
    $this->{error_mgr}->exitProgram( ERR_CAT, 5, [$tag], !defined($tag_vals) );
    $this->{error_mgr}->exitProgram( ERR_CAT, 6, [ $tag, $key ],
      !defined( $tag_vals->{$key} ) );
    $tags->{$tag} = $key;
  }
  ###
  ### Create tag_id (make sure all expected tags appear)
  ###
  my $tag_id = util::Constants::EMPTY_STR;
  foreach my $tag ( @{ $this->{tag_order} } ) {
    if ( !defined( $tags->{$tag} ) ) {
      $this->{error_mgr}
        ->exitProgram( ERR_CAT, 7, [$tag], !$ignore_missing_tag );
      next;
    }
    my $key = $tags->{$tag};
    if ( util::Constants::EMPTY_LINE($tag_id) ) { $tag_id = $key; }
    else { $tag_id .= $TAG_SEPARATOR . $key; }
  }
  return $tag_id;
}

sub _generateAllTagSets {
  my util::Statistics $this = shift;
  my ( $index, $tag_sets ) = @_;
  ###
  ### Is the tag set empty
  ###
  my $tag_sets_empty =
    ( @{$tag_sets} == 0 ) ? util::Constants::TRUE: util::Constants::FALSE;
  ###
  ### Finished
  ###
  return $tag_sets if ( $index > $#{ $this->{tag_order} } );
  ###
  ### Get the tag and iterate
  ###
  my $new_tag_sets = [];
  my $tag          = $this->{tag_order}->[$index];
  foreach my $val ( keys %{ $this->{tags}->{$tag} } ) {
    my @tag_val = ( $tag, $val );
    if ($tag_sets_empty) {
      my $tag_array = [@tag_val];
      push( @{$new_tag_sets}, $tag_array );
    }
    else {
      foreach my $tag_array ( @{$tag_sets} ) {
        my $new_tag_array = [ @{$tag_array}, @tag_val ];
        push( @{$new_tag_sets}, $new_tag_array );
      }
    }
  }
  return $this->_generateAllTagSets( $index + 1, $new_tag_sets );
}

sub _determineTagsToUse {
  my util::Statistics $this = shift;
  my (@tags) = @_;
  ###
  ### If there are no tags, the use all tags
  ###
  if ( scalar @tags == 0 ) {
    my $last_tag = $this->{tag_order}->[ $#{ $this->{tag_order} } ];
    return ( $last_tag, @{ $this->{tag_order} } );
  }
  ###
  ### Determine the set of tags to use
  ###
  my %tags = ();
  foreach my $tag (@tags) {
    $tags{"$tag"} = util::Constants::EMPTY_STR;
  }
  my @tags_to_use = ();
  foreach my $tag ( @{ $this->{tag_order} } ) {
    next if ( !defined( $tags{"$tag"} ) );
    push( @tags_to_use, $tag );
  }
  my $last_tag = $tags_to_use[$#tags_to_use];
  return ( $last_tag, @tags_to_use );
}

sub _generateKeyAndStruct {
  my util::Statistics $this = shift;
  my ( $tag_id, @tags ) = @_;

  my @tag_vals = split( /$TAG_SEPARATOR/, $tag_id );
  my $struct = {};
  foreach my $index ( 0 .. $#tag_vals ) {
    my $col = $this->{tag_order}->[$index];
    $struct->{"$col"} = $tag_vals[$index];
  }
  my $key = util::Constants::EMPTY_STR;
  foreach my $tag (@tags) {
    my $tag_val = $struct->{"$tag"};
    if ( util::Constants::EMPTY_LINE($key) ) { $key = $tag_val; }
    else { $key .= $TAG_SEPARATOR . $tag_val; }
  }

  return ( $key, $struct );
}

sub _generateTable {
  my util::Statistics $this = shift;
  my (@tags) = @_;
  ###
  ### Determine the tags to use
  ###
  my ( $last_tag, @tags_to_use ) = $this->_determineTagsToUse(@tags);
  ###
  ### Determine the total count and data
  ###
  my %data         = ();
  my $total_count  = 0;
  my $last_col_len = length($last_tag);
  foreach my $tag_id ( keys %{ $this->{item} } ) {
    $total_count += $this->{item}->{$tag_id};
    my ( $key, $struct ) =
      $this->_generateKeyAndStruct( $tag_id, @tags_to_use );
    if ( !defined( $data{$key} ) ) {
      $data{$key} = $struct;
      $struct->{&COUNT} = 0;
      my $col_len = length( $struct->{"$last_tag"} );
      if ( $col_len > $last_col_len ) {
        $last_col_len = $col_len;
      }
    }
    $data{$key}->{&COUNT} += $this->{item}->{$tag_id};
  }
  ###
  ### If there is no data, do not generate table
  ###
  my @data = values %data;
  $this->{last_rows} = [];
  return util::Constants::FALSE if ( @data == 0 );
  ###
  ### Create the table and set its configuration
  ###
  $this->_createTable(@tags_to_use);
  ###
  ### Generate table if there is data.
  ###
  $this->{table}->setData(@data);
  $this->_generateLastRows( $last_tag, $last_col_len, $total_count );
  return util::Constants::TRUE;
}

################################################################################
#
#				    Methods
#
################################################################################

sub new {
  my util::Statistics $this = shift;
  my ( $header, $epilogue, $error_mgr, @tag_data ) = @_;
  $this = fields::new($this) unless ref($this);
  $this->{error_mgr}  = $error_mgr;
  $this->{count_col}  = COUNT;
  $this->{header}     = $header;
  $this->{epilogue}   = $epilogue;
  $this->{item}       = {};
  $this->{last_rows}  = [];
  $this->{show_total} = util::Constants::TRUE;
  $this->{tag_order}  = [];
  $this->{tags}       = {};
  ###
  ### Make sure that tag data is correctly specified
  ###
  $this->{error_mgr}->exitProgram( ERR_CAT, 1, [], @tag_data == 0 );
  $this->{error_mgr}->exitProgram( ERR_CAT, 2, [], @tag_data % 2 != 0 );
  ###
  ### Setting the tag/value sets
  ###
  while ( @tag_data != 0 ) {
    my $tag  = shift(@tag_data);
    my $tags = shift(@tag_data);
    $this->{error_mgr}->exitProgram( ERR_CAT, 3, [$tag],
      ref($tags) ne util::PerlObject::ARRAY_TYPE );
    $this->{tags}->{$tag} = {};
    foreach my $val ( @{$tags} ) {
      $this->{tags}->{$tag}->{$val} = util::Constants::EMPTY_STR;
    }
    push( @{ $this->{tag_order} }, $tag );
  }
  ###
  ### return object
  ###
  return $this;
}

sub increment {
  my util::Statistics $this = shift;
  my (@tag_data) = @_;
  ###
  ### Get the tag ID
  ###
  my $tag_id = $this->_getTagId( util::Constants::FALSE, @tag_data );
  ###
  ### Increment tag id
  ###
  if ( util::Constants::EMPTY_LINE( $this->{item}->{$tag_id} ) ) {
    $this->{item}->{$tag_id} = 0;
  }
  $this->{item}->{$tag_id}++;
}

sub decrement {
  my util::Statistics $this = shift;
  my (@tag_data) = @_;
  ###
  ### Get the tag ID
  ###
  my $tag_id = $this->_getTagId( util::Constants::FALSE, @tag_data );
  ###
  ### Decrement tag id
  ###
  if ( util::Constants::EMPTY_LINE( $this->{item}->{$tag_id} ) ) {
    $this->{item}->{$tag_id} = 0;
  }
  ###
  ### Do not decrement below zero!
  ###
  return if ( $this->{item}->{$tag_id} == 0 );

  $this->{item}->{$tag_id}--;
}

sub incrementCount {
  my util::Statistics $this = shift;
  my ( $count, @tag_data ) = @_;
  ###
  ### Only increment positive counts!
  ###
  return if ( util::Constants::EMPTY_LINE($count) );
  $count = int($count);
  return if ( $count <= 0 );
  ###
  ### Get the tag ID
  ###
  my $tag_id = $this->_getTagId( util::Constants::FALSE, @tag_data );
  ###
  ### Increment tag id
  ###
  if ( util::Constants::EMPTY_LINE( $this->{item}->{$tag_id} ) ) {
    $this->{item}->{$tag_id} = 0;
  }
  $this->{item}->{$tag_id} += $count;
}

sub print {
  my util::Statistics $this = shift;
  my (@tags) = @_;

  return if ( !$this->_generateTable(@tags) );
  $this->{table}->generateTable( $this->{header}, $this->{epilogue},
    @{ $this->{last_rows} } );
}

sub printStr {
  my util::Statistics $this = shift;
  my (@tags) = @_;

  return util::Constants::EMPTY_STR if ( !$this->_generateTable(@tags) );
  return $this->{table}->generateTableStr( $this->{header}, $this->{epilogue},
    @{ $this->{last_rows} } );
}

################################################################################
#
#                              Setter Methods
#
################################################################################

sub setCountColName {
  my util::Statistics $this = shift;
  my ($count_col) = @_;

  return if ( util::Constants::EMPTY_LINE($count_col) );
  $this->{count_col} = $count_col;
}

sub setShowTotal {
  my util::Statistics $this = shift;
  my ($show_total) = @_;
  $this->{show_total} =
    ( !util::Constants::EMPTY_LINE($show_total) && $show_total )
    ? util::Constants::TRUE
    : util::Constants::FALSE;
}

sub setCountsToZero {
  my util::Statistics $this = shift;
  my $all_tag_sets = [];
  $all_tag_sets = $this->_generateAllTagSets( 0, $all_tag_sets );
  foreach my $tag_data ( @{$all_tag_sets} ) {
    my $tag_id = $this->_getTagId( util::Constants::FALSE, @{$tag_data} );
    $this->{item}->{$tag_id} = 0;
  }
}

sub setHeader {
  my util::Statistics $this = shift;
  my ($header) = @_;
  $this->{header} = $header;
}

sub setEpilogue {
  my util::Statistics $this = shift;
  my ($epilogue) = @_;
  $this->{epilogue} = $epilogue;
}

################################################################################
#
#                              Getter Methods
#
################################################################################

sub count {
  my util::Statistics $this = shift;
  my (@tag_data) = @_;
  ###
  ### tag ID for tag data
  ###
  my $my_tag_id = $this->_getTagId( util::Constants::TRUE, @tag_data );
  ###
  ### Tags to use
  ###
  my @tags = ();
  while ( @tag_data != 0 ) {
    my $tag = shift(@tag_data);
    my $key = shift(@tag_data);
    push( @tags, $tag );
  }
  my ( $last_tag, @tags_to_use ) = $this->_determineTagsToUse(@tags);
  ###
  ### Determine count
  ###
  my $count = 0;
  foreach my $tag_id ( keys %{ $this->{item} } ) {
    my $item_count = $this->{item}->{$tag_id};
    my ( $key, $struct ) =
      $this->_generateKeyAndStruct( $tag_id, @tags_to_use );
    next if ( $my_tag_id ne $key );
    $count += $item_count;
  }
  return $count;
}

################################################################################

1;

__END__

=head1 NAME

Statistics.pm

=head1 DESCRIPTION

This concrete class provides a simple yet general mechanism for
tracking counts of occurrences of an Item based on tags and tag value
lists (referenced Perl arrays), and printing the summary tabulation of
results to the log.

=head1 USAGE

In this Usage Section, an example usage is presented.

The tags for the statistics will be B<'Locus Name'> and
B<'Ambiguous Status'> and the tag values are defined below.  This
class requires finite pre-defined tag value lists.

  use util::Statistics;
  use util::ErrMgr;

  my $error_mgr = new util::ErrMgr();

  my @LOCUS_VALUES =
    ('HLA-A',
     'HLA-B',
     'HLA-C',
     'HLA-DRB1',
     );
  my @AMBIGUOUS_STATUS_VALUES =
    ('Ambiguous',
     'Not Ambiguous');

Instance object for tracking counts based on parent_type and
child_type tags using the above tag values arrays.

   my $ambiguous_stats =
     new util::Statistics
       ('Summary of Ambiguity Counts by Locus',
        "An ambiguous typing result is one that contains\n"
        . "more than one allele.  Only typing results with no\n"
        . "errors are counted in this table.",
        $error_mgr,
        'Locus Name',       \@LOCUS_VALUES,
        'Ambiguous Status', \@AMBIGUOUS_STATUS_VALUES);

The first parameter to the instantation is the B<Header>, while the
second is the B<Epilogue> (see below for the example generation).  The
epilogue can be empty (undef).  Then a sequence of
(tag, tag-value-list)-pairs where the tag-value-list is an array
reference to the list of possible tag values for the tag.  The order
of the pairs defines the order of the columns that are generated
output (see below).

Other setter method are also provided:

   $ambiguous_stats->setCountColName( 'Number of Allele Sets' );
                                        ### By default, the count column name
                                        ### is 'COUNT'. It is overridden by
                                        ### by providing a non-empty string

   $ambiguous_stats->setShowTotal( 1 ); ### By default, the total is shown.
                                        ### Zero (0) will remove total.

   $ambiguous_stats->setCountsToZero;   ### By default, zero value tag-tuples
                                        ### are NOT generated (see below).
                                        ### This method causes all tag-tuples
                                        ### will be generated.

Now through the course of the program in which the statistic are to
be gathered, increment various ('Locus Name', 'Ambiguous Status')-tuples for
the two tags.  For example,

   $ambiguous_stats->increment
     ('Ambiguous Status', 'Not Ambiguous',
      'Locus Name',       'HLA-B');

   $ambiguous_stats->increment
     ('Ambiguous Status', 'Ambiguous',
      'Locus Name',       'HLA-A');
   ...

At some point, in the program generate the summary results for the
object.

   $comp_stats->print;

For this printout, the output would look like the following.  Only
tag-value tuples that have been incremented are printed.  The
total for tag-value tuple is provided in the COUNT column ('Number of
Types Alleles') and the summary total is provided at the bottom.  The
tuples are ordered by the tag order provided in the instantiation and
within each tag lexiographically by the tag values.  Only tuples that
have a count assigned to them are presented in the summary.


   ###############################################################
   ###                                                         ###
   ###  Summary of Ambiguity Counts by Locus                   ###
   ###                                                         ###
   ###  Locus Name  Ambiguity Status  Number of Typed Alleles  ###
   ###  ----------  ----------------  -----------------------  ###
   ###  HLA-A       Ambiguous                             113  ###
   ###  HLA-A       Not Ambiguous                          31  ###
   ###  HLA-B       Ambiguous                              60  ###
   ###  HLA-B       Not Ambiguous                          76  ###
   ###  HLA-C       Ambiguous                             110  ###
   ###  HLA-C       Not Ambiguous                          98  ###
   ###  HLA-DRB1    Ambiguous                               0  ###
   ###  HLA-DRB1    Not Ambiguous                           0  ###
   ###                                -----------------------  ###
   ###                         TOTAL                      488  ###
   ###                                                         ###
   ###                                                         ###
   ###  An ambiguous typing result is one that contains        ###
   ###  more than one allele.  Only typing results with no     ###
   ###  errors are counted in this table.                      ###
   ###                                                         ###
   ###############################################################


=head1 METHODS

The following methods are exported by this class.

=head2 B<new util::Statistics(header, epilogue, error_mgr, tag_1, tag_value_list_1, tag_2, tag_value_list_2, ...)>

The new method is the constructor for this Object class.  It sets the
initial header and epilogue strings and creates the (tag,
tag_value_list)-pairs and tag-tuple (tag_1, tag_2, ...)  for managing
counts for the object.  The B<error_mgr> is an instance of
L<util::ErrMgr>.  The list
B<tag_1, tag_value_list_1, tag_2, tag_value_list_2, ...> is the list
of (B<tag>, B<tag_value_list>)-pairs.  The B<tag> is a string and the
B<tag_value_list> is a referenced Perl array of possible tag values
for the tag.  Each tag defines a category of values that will be
counted.  This list also defines the tag-tuple (list of categories)
B<(tag_1, tag_2, ...)> for tracking counts, where for each tag
B<tag_i> the set of possible values is defined in the referenced Perl
array list B<tag_value_list_i>.

The following statistic attributes can be modified (see L<"SETTER METHODS">
below).

=over 4

=item B<Header>

The B<Header> is the name of the statistic for which the counts are
managed.  By default, it is the value provided to the constructor.  It
can be changed by L<"setHeader(header)">.

=item B<Epilogue>

The B<Epilogue> is the further information related to the statistic.
By default, it is the value provided to the constructor.  It can be
changed by L<"setEpilogue(epilogue)">.

=item B<Count Column Header>

By default, the count column header is B<COUNT>.  It can be change by
L<"setCountColName(count_col)">.

=item B<Show Total>

By default, the total count of all tuples is shown.  It can be changed by 
L<"setShowTotal(show_total)">.

=item B<Initialize Counts to Zero>

By default, counts for all tuples are not initialized.  Therefore only
those tuples that contain a positive count value will be generated
into the statistic.  To change this use L<"setCountsToZero">.

=back

=head2 B<increment(tag_1, tag_value_list_value_1, tag_2, tag_value_list_value_2, ...)>

This method increments by one (1) the count for tuple identified by
(B<tag_value_list_value_1>, B<tag_value_list_value_2>, ...)-tuple
where the value B<tag_value_list_value_i> must be a tag-value in
tag-value referenced array defined by the tag B<tag_i>.

=over 4

=item B<tag_1, tag_value_list_value_1, tag_2, tag_value_list_value_2, ...>

The ordered pair list of (tag, tag-value)-pairs that identifies the
ordered tuple to increment by one for the given Item.  The only
requirement on the ordered pair list is that each tag defined by the
statistic occurs in the list and the corresponding tag-value exists in
the tag-value array list identified by the tag.

=back

=head2 B<print([@tags_to_use])>

=head2 B<$print_str = printStr([@tags_to_use])>

This method prints the summary results for the object (see
L<"USAGE">).  If the object has had no counts added to it by the
B<increment> method, the statistic is not generated.  The print method
uses the class L<util::Table> to generate the statistic results.

If the list of tags B<@tag_to_use> is empty, then all tags defined in
the constructor are used to generate the statistic result.  If the
list of tags is not empty, then only these tags are used to report
results.  Note that any tag in the list that is not a tag in the
constructor is ignored.  Also, the order of the tags that are reported
in the result is the tag order defined in the constructor.

=head2 B<count(tag_1, tag_value_list_value_1, tag_2, tag_value_list_value_2, ...)>

This method returns the current count for the tag-value tuples
identified by the 
(B<tag_value_list_value_1>, B<tag_value_list_value_2>,...)-tuple
where the value B<tag_value_list_value_i> must be a tag-value in tag
reference array determined by the tag B<tag_i>.

=over 4

=item B<tag_1, tag_value_list_value_1, tag_2, tag_value_list_value_2, ...>

The list of (tag, tag-value)-pairs that identifies the tuple to
determine the given tag-value tuple.  The only requirement on the
ordered pair list is that each tag defined by the item template occurs
in the list and the corresponding tag-value exists in the tag-value
array list identified by the tag.  Not all tags defined in the
constructor need be represented in the list.

=back

=head1 SETTER METHODS

The following setter methods are exported

=head2 B<setHeader(header)>

This method sets the header.  Initially, the header is set in the
constructor.

=head2 B<setEpilogue(epilogue)>

This method sets the epilogue. Initially, the epilogue is set in the
constructor.

=head2 B<setCountColName(count_col)>

This method sets the B<COUNT> column name. By default, it is B<COUNT>.
The count_col must be non-empty, otherwise the count column is not
changed.

=head2 B<setShowTotal(show_total)>

This method sets whether the total is displayed (show_total TRUE(1))
or not (show_total FALSE(0)) when the statistic are printed.  By
default, the total is printed.

=head2 B<setCountsToZero>

This method initializes all possible tag-tuple counts for the
statistic to zero.  This will cause all tag-tuples (including zero
counts) to be printed.  Initially, only counts for tuples that have a
positive count will be displayed.

=cut
