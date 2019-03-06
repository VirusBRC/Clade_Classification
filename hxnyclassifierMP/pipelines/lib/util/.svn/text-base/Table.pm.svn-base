package util::Table;
################################################################################
#
#				Required Modules
#
################################################################################

use strict;

use FileHandle;
use Pod::Usage;

use util::Constants;
use util::PathSpecifics;
use util::PerlObject;

use fields qw(
  col_justify
  col_lens
  col_ord
  col_restrict
  continuation
  cols
  data
  empty_field
  error_mgr
  indent
  in_header
  ord_fcn
  spacing
  serializer
);

################################################################################
#
#			            Static Class Constants
#
################################################################################
###
### Set Separator
###
sub DEFAULT_SEPARATION { return 2; }
###
### Justification
###
sub LEFT_JUSTIFY   { return 'left'; }
sub RIGHT_JUSTIFY  { return 'right'; }
sub CENTER_JUSTIFY { return 'center'; }

################################################################################
#
#				Private Methods
#
################################################################################

sub _generateColSegments {
  my util::Table $this = shift;
  my ( $col, $cell, $header ) = @_;

  my $col_restrict = $this->{col_restrict};
  my @col_segments = ();
  if ( util::Constants::EMPTY_LINE($cell) ) {
    ###
    ### an empty cell is returned 'as-is'
    ###
    push( @col_segments, $cell );
    return @col_segments;
  }
  elsif ( !defined( $col_restrict->{$col} ) || $header ) {
    ###
    ### return the line segments if the colum is unrestricted
    ###
    @col_segments = split( /\n/, $cell );
    return @col_segments;
  }
  ###
  ### If the cell does not exceed max length,
  ### then return it immediately
  ###
  my $max_len = $col_restrict->{$col};
  if ( $max_len >= length($cell) ) {
    push( @col_segments, $cell );
    return @col_segments;
  }
  ###
  ### Now construct the restricted column segments
  ###
  my $current_seg = util::Constants::EMPTY_STR;
  my @comps = split( /\n| +/, $cell );
  while ( scalar @comps > 0 ) {
    my $current_comp     = $comps[0];
    my $current_comp_len = length($current_comp);
    my $current_seg_len  = length($current_seg);
    my $new_seg_len      = $current_seg_len + $current_comp_len + 1;
    if ( length($current_seg) == 0 ) {
      if ( $current_comp_len < $max_len ) {
        $current_seg = $current_comp;
        shift(@comps);
      }
      elsif ( $current_comp_len == $max_len ) {
        push( @col_segments, $current_comp );
        shift(@comps);
      }
      else {
        my $substr = substr( $current_comp, 0, $max_len - 1 );
        push( @col_segments, $substr . $this->{continuation} );
        $comps[0] = substr(
          $current_comp,
          $max_len - 1,
          $current_comp_len - $max_len + 1
        );
      }
    }
    elsif ( $new_seg_len < $max_len ) {
      $current_seg .= " $current_comp";
      shift(@comps);
    }
    elsif ( $new_seg_len == $max_len ) {
      push( @col_segments, "$current_seg $current_comp" );
      shift(@comps);
      $current_seg = util::Constants::EMPTY_STR;
    }
    else {
      push( @col_segments, $current_seg );
      $current_seg = util::Constants::EMPTY_STR;
    }
  }
  if ( length($current_seg) > 0 ) {
    push( @col_segments, $current_seg );
  }

  return @col_segments;
}

sub _colLen {
  my util::Table $this = shift;
  my ($col) = @_;
  ###
  ### Must determine segment length
  ###
  my $col_len = 0;
  my @col_segs = split( /\n/, $this->{cols}->{"$col"} );
  foreach my $seg (@col_segs) {
    my $seg_len = length($seg);
    next if ( $seg_len <= $col_len );
    $col_len = $seg_len;
  }
  return $col_len;
}

sub _setColumnLengths {
  my util::Table $this = shift;
  my (@last_rows) = @_;
  ###
  ### Columns must contain the column header
  ###
  $this->{col_lens} = {};
  foreach my $col ( @{ $this->{col_ord} } ) {
    $this->{col_lens}->{"$col"} = $this->_colLen($col);
  }
  ###
  ### Determine Maximum Lengths
  ###
  my $empty_field_len = length( $this->{empty_field} );
  my @data            = @{ $this->{data} };
  push( @data, @last_rows );
  foreach my $datum (@data) {
    foreach my $col ( @{ $this->{col_ord} } ) {
      if ( util::Constants::EMPTY_LINE( $datum->{"$col"} ) ) {
        next if ( $this->{col_lens}->{"$col"} >= $empty_field_len );
        $this->{col_lens}->{"$col"} = $empty_field_len;
        next;
      }
      my @datum_segments =
        $this->_generateColSegments( $col, $datum->{"$col"},
        util::Constants::FALSE );
      my $len = 0;
      foreach my $datum_segment (@datum_segments) {
        my $seg_length = length($datum_segment);
        next if ( $seg_length <= $len );
        $len = $seg_length;
      }
      next if ( $this->{col_lens}->{"$col"} >= $len );
      $this->{col_lens}->{"$col"} = $len;
    }
  }
}

sub _generateCol {
  my util::Table $this = shift;
  my ( $col, $cell ) = @_;

  if ( util::Constants::EMPTY_LINE($cell) ) {
    $cell = $this->{empty_field};
  }
  my $spaces_len = $this->{col_lens}->{"$col"} - length($cell);
  my $spaces     = &util::Constants::SPACE x $spaces_len;
  my $val        = util::Constants::EMPTY_STR;
  if ( $this->{col_justify}->{"$col"} eq LEFT_JUSTIFY ) {
    $val = $cell . $spaces;
  }
  elsif ( $this->{col_justify}->{"$col"} eq RIGHT_JUSTIFY ) {
    $val = $spaces . $cell;
  }
  elsif ( $this->{col_justify}->{"$col"} eq CENTER_JUSTIFY ) {
    my $left_len     = int( $spaces_len / 2 );
    my $right_len    = $spaces_len - $left_len;
    my $left_spaces  = &util::Constants::SPACE x $left_len;
    my $right_spaces = &util::Constants::SPACE x $right_len;
    $val = $left_spaces . $cell . $right_spaces;
  }

  return $val;
}

sub _generateRow {
  my util::Table $this = shift;
  my ( $datum, $header ) = @_;

  $header =
    ( !util::Constants::EMPTY_LINE($header) && $header )
    ? util::Constants::TRUE
    : util::Constants::FALSE;
  ###
  ### Generate the segments
  ###
  my $cols     = {};
  my $max_rows = 0;
  foreach my $col ( @{ $this->{col_ord} } ) {
    my $cell           = $datum->{"$col"};
    my $col_vals       = [];
    my @datum_segments = $this->_generateColSegments( $col, $cell, $header );
    foreach my $segment (@datum_segments) {
      my $val = $this->_generateCol( $col, $segment );
      push( @{$col_vals}, $val );
    }
    $cols->{"$col"} = $col_vals;
    if ( $max_rows < scalar @{$col_vals} ) { $max_rows = scalar @{$col_vals}; }
  }
  my $blank_cols = {};
  foreach my $col ( @{ $this->{col_ord} } ) {
    my $col_vals = $cols->{"$col"};
    next if ( $max_rows <= scalar @{$col_vals} );
    $blank_cols->{"$col"} =
      &util::Constants::SPACE x $this->{col_lens}->{"$col"};
  }
  ###
  ### now process the segments into rows
  ###
  my @rows = ();
  foreach my $index ( 0 .. ( $max_rows - 1 ) ) {
    my $row = util::Constants::EMPTY_STR;
    foreach my $col ( @{ $this->{col_ord} } ) {
      if ( !util::Constants::EMPTY_LINE($row) ) {
        $row .= &util::Constants::SPACE x $this->{spacing};
      }
      my $col_vals = $cols->{"$col"};
      my $val      = undef;
      if ( $index <= $#{$col_vals} ) {
        $val = $col_vals->[$index];
      }
      else {
        $val = $blank_cols->{"$col"};
      }
      $row .= $val;
    }
    $row = $this->{indent} . $row . &util::Constants::NEWLINE;
    push( @rows, $row );
  }

  return join( util::Constants::EMPTY_STR, @rows );
}

sub _generateColumnHeadings {
  my util::Table $this = shift;
  return $this->_generateRow( $this->{cols}, util::Constants::TRUE );
}

sub _generateUnderLine {
  my util::Table $this = shift;
  my $datum = {};
  foreach my $col ( @{ $this->{col_ord} } ) {
    $datum->{"$col"} = &util::Constants::HYPHEN x $this->{col_lens}->{"$col"};
  }
  return $this->_generateRow($datum);
}

sub _sortData {
  my util::Table $this = shift;
  my $ord_fcn = $this->{ord_fcn};
  return @{ $this->{data} }
    if ( util::Constants::EMPTY_LINE($ord_fcn) );
  return sort $ord_fcn @{ $this->{data} };
}

sub _getValues {
  my util::Table $this = shift;
  my ($datum) = @_;

  my @values = ();
  foreach my $col ( @{ $this->{col_ord} } ) {
    my $val = $datum->{"$col"};
    $val =~ s/\n/ /g;
    push( @values, $val );
  }
  return @values;
}

sub _generateTable($;$$@) {
  my util::Table $this = shift;
  my ( $heading, $epilogue, @last_rows ) = @_;

  my $print_heading =
    ( util::Constants::EMPTY_LINE($heading) )
    ? util::Constants::FALSE
    : util::Constants::TRUE;

  my $print_epilogue =
    ( util::Constants::EMPTY_LINE($epilogue) )
    ? util::Constants::FALSE
    : util::Constants::TRUE;

  $this->_setColumnLengths(@last_rows);
  my $table = util::Constants::EMPTY_STR;
  $table .= $this->_generateColumnHeadings . $this->_generateUnderLine;
  foreach my $datum ( $this->_sortData ) {
    $table .= $this->_generateRow($datum);
  }
  foreach my $row (@last_rows) {
    $table .= $this->_generateRow($row);
  }
  return ( $print_heading, $print_epilogue, $table );
}

################################################################################
#
#                           Public Methods
#
################################################################################

sub new($$%) {
  my util::Table $this = shift;
  my ( $error_mgr, %cols ) = @_;
  $this = fields::new($this) unless ref($this);
  ###
  ### Initialize Table
  ###
  $this->{cols}      = {%cols};
  $this->{error_mgr} = $error_mgr;

  $this->{col_justify}  = {};
  $this->{col_ord}      = [ sort keys %{ $this->{cols} } ];
  $this->{col_lens}     = undef;
  $this->{col_restrict} = {};
  $this->{continuation} = util::Constants::HYPHEN;
  $this->{data}         = [];
  $this->{empty_field}  = util::Constants::EMPTY_STR;
  $this->{indent}       = util::Constants::EMPTY_STR;
  $this->{in_header}    = util::Constants::FALSE;
  $this->{ord_fcn}      = undef;
  $this->{spacing}      = DEFAULT_SEPARATION;

  foreach my $col ( keys %{ $this->{cols} } ) {
    $this->{col_justify}->{"$col"} = RIGHT_JUSTIFY;
  }

  $this->{serializer} =
    new util::PerlObject( undef, undef, $this->{error_mgr} );

  return $this;
}

################################################################################
#
#			            Public Setter Methods
#
################################################################################

sub setIndent ($$) {
  my util::Table $this = shift;
  my ($indent) = @_;
  return if ( util::Constants::EMPTY_LINE($indent) || int($indent) < 0 );
  $indent = int($indent);
  $this->{indent} = &util::Constants::SPACE x $indent;
}

sub setColumnJustification($$$) {
  my util::Table $this = shift;
  my ( $col, $justification ) = @_;
  my $cols = $this->{cols};
  return
    if (
    !defined( $cols->{"$col"} )
    || ( $justification ne LEFT_JUSTIFY
      && $justification ne RIGHT_JUSTIFY
      && $justification ne CENTER_JUSTIFY )
    );
  $this->{col_justify}->{"$col"} = $justification;
}

sub setColumnOrder($@) {
  my util::Table $this = shift;
  my (@ord)            = @_;
  my $cols             = $this->{cols};
  my $col_ord          = [];
  foreach my $col (@ord) {
    next if ( !defined( $cols->{"$col"} ) );
    push( @{$col_ord}, $col );
  }
  return if ( @{$col_ord} == 0 );
  $this->{col_ord} = $col_ord;
}

sub setColumnSeparation($$) {
  my util::Table $this = shift;
  my ($separation) = @_;
  $separation = int($separation);
  return if ( $separation <= 0 );
  $this->{spacing} = $separation;

}

sub setEmptyField($$) {
  my util::Table $this = shift;
  my ($empty_field) = @_;

  if ( util::Constants::EMPTY_LINE($empty_field) ) {
    $empty_field = util::Constants::EMPTY_STR;
  }
  $empty_field = strip_whitespace($empty_field);
  $this->{empty_field} = $empty_field;
}

sub setRowOrder($$) {
  my util::Table $this = shift;
  my ($ord_function) = @_;
  ###
  ### Unset the row order function
  ###
  if ( util::Constants::EMPTY_LINE($ord_function) ) {
    $this->{ord_fcn} = undef;
    return;
  }
  ###
  ### Check that string is an anonymous function
  ###
  return if ( $ord_function !~ /^\s*sub\s*\{/ );
  ###
  ### Now eval order function
  ###
  my $ord_fcn = eval $ord_function;
  my $status  = $@;
  $this->{error_mgr}->printWarning(
    "Ord function does not eval\n" . "  ord_function =\n  $ord_function",
    defined($status) && $status );
  return
    if ( ( defined($status) && $status )
    || ref($ord_fcn) ne util::PerlObject::CODE_TYPE );
  $this->{ord_fcn} = $ord_fcn;
}

sub setInHeader($$) {
  my util::Table $this = shift;
  my ($in_header) = @_;
  return if ( util::Constants::EMPTY_LINE($in_header) );
  $this->{in_header} =
    ($in_header) ? util::Constants::TRUE : util::Constants::FALSE;
}

sub setData($@) {
  my util::Table $this = shift;
  my (@data) = @_;
  $this->{data} = [];
  foreach my $datum (@data) {
    next
      if ( util::Constants::EMPTY_LINE($datum)
      || ref($datum) ne util::PerlObject::HASH_TYPE );
    push( @{ $this->{data} }, $datum );
  }
}

sub setColumnWidth {
  my util::Table $this = shift;
  my ( $col, $width ) = @_;

  my $cols = $this->{cols};
  $width = int($width);
  ###
  ### Return immediately if column is not in the column set
  ### or the column width is negative
  ###
  return if ( !defined( $cols->{"$col"} ) || $width < 0 );
  ###
  ### If column width is zero, then remove restriction
  ### if it is there
  ###
  my $col_restrictions = $this->{col_restrict};
  if ( $width == 0 ) {
    if ( defined( $col_restrictions->{"$col"} ) ) {
      delete( $col_restrictions->{"$col"} );
    }
    return;
  }
  ###
  ### Determine that a positive column width is legitimate
  ### If it is set it, otherwise return
  ###
  my $min_col_width = $this->_colLen($col);
  return if ( $width < $min_col_width );
  $col_restrictions->{"$col"} = $width;
}

sub setContinuation {
  my util::Table $this = shift;
  my ($continuation) = @_;

  return if ( !defined($continuation) );
  $this->{continuation} = $continuation;
}

################################################################################
#
#			            Public Getter Methods
#
################################################################################

sub generateTableStr($;$$@) {
  my util::Table $this = shift;
  my ( $heading, $epilogue, @last_rows ) = @_;

  my ( $print_heading, $print_epilogue, $table ) =
    $this->_generateTable( $heading, $epilogue, @last_rows );
  if ($print_heading)  { $table = "$heading\n\n$table"; }
  if ($print_epilogue) { $table = "$table\n\n$epilogue"; }
  return "$table\n";
}

sub generateTable($;$$@) {
  my util::Table $this = shift;
  my ( $heading, $epilogue, @last_rows ) = @_;

  my ( $print_heading, $print_epilogue, $table ) =
    $this->_generateTable( $heading, $epilogue, @last_rows );
  my $indent = length( $this->{indent} );
  if ( $this->{in_header} ) {
    if ($print_heading)  { $table = "$heading\n\n$table"; }
    if ($print_epilogue) { $table = "$table\n\n$epilogue"; }
    $this->{error_mgr}->printHeader( $table, $indent );
  }
  else {
    $this->{error_mgr}->printHeader( $heading, $indent )
      if ($print_heading);
    $this->{error_mgr}->printMsg($table);
    $this->{error_mgr}->printHeader( $epilogue, $indent )
      if ($print_epilogue);
  }
}

sub generateTabFile($$;@) {
  my util::Table $this = shift;
  my ( $filename, @last_rows ) = @_;
  $filename = getPath($filename);
  my $fh  = new FileHandle;
  my $tab = util::Constants::TAB;
  my $nl  = util::Constants::NEWLINE;
  $this->{error_mgr}
    ->dieOnError( "Cannot open " . $filename, !$fh->open( $filename, '>' ) );
  $fh->autoflush(util::Constants::TRUE);

  $fh->print( join( $tab, $this->_getValues( $this->{cols} ) ) . $nl );

  foreach my $datum ( $this->_sortData ) {
    $fh->print( join( $tab, $this->_getValues($datum) ) . $nl );
  }
  foreach my $row (@last_rows) {
    $fh->print( join( $tab, $this->_getValues($row) ) . $nl );
  }
  $fh->close;
}

################################################################################

1;

__END__

=head1 NAME

Table.pm

=head1 DESCRIPTION

This class defines the class for generating a table to the log using
L<util::ErrMgr> or generating a tab-separated file with the tabular
content.  Column cells can contain multi-line data and column can 
be restricted by maximum column widths.

=head1 STATIC CONSTANTS

The following static constants are exported for the specification of
column justification:

   util::Table::LEFT_JUSTIFY   -- left
   util::Table::RIGHT_JUSTIFY  -- right
   util::Table::CENTER_JUSTIFY -- center

=head1 USAGE

In this Usage Section, an example usage is illustrated.

   use util::Table;
   use util::ErrMgr;

   my $error_mgr = new util::ErrMgr();

   my %SUBGENOTYPE_COLS = (
     allele_1  => 'AlleleSet 1',
     type_1    => 'Type 1',
     cwd_1     => 'CWD 1',
     reg_cwd_1 => 'Reg-CWD 1',
   
     allele_2  => 'AlleleSet 2',
     type_2    => 'Type 2',
     cwd_2     => 'CWD 2',
     reg_cwd_2 => 'Reg-CWD 2'
   );
   
   my @SUBGENOTYPE_ORD = (
     'allele_1', 'type_1', 'cwd_1', 'reg_cwd_1', 
     'allele_2', 'type_2', 'cwd_2', 'reg_cwd_2');

   my $TABLE_ORDER =
     'sub {'
     . $a->{allele_1} cmp $b->{allele_1}'
     . ' or '
     . $a->{allele_2} cmp $b->{allele_2}'
     . ';}';

   my $table = new util::Table( $error_mgr, %SUBGENOTYPE_COLS );
   $table->setColumnOrder(@SUBGENOTYPE_ORD);
   $table->setColumnJustification( 'allele_1', $table->LEFT_JUSTIFY );
   $table->setColumnJustification( 'allele_2', $table->LEFT_JUSTIFY );
   $table->setEmptyField('-');
   $table->setRowOrder($TABLE_ORDER);
   $table->setInHeader(1);
   ###
   ### Assume the array is generated as follows:
   ###
   my @tableSubGenotypes =
   (
    { allele_1  => 'C*07:02', type_1 => 'allele', cwd_1 => 1, reg_cwd_1 => 1,
      allele_2  => 'C*08:01', type_2 => 'allele', cwd_2 => 1, reg_cwd_2 => 1, },
    { allele_1  => 'C*07:03', type_1 => 'allele', cwd_1 => 0, reg_cwd_1 => 1,
      allele_2  => 'C*08:01', type_2 => 'allele', cwd_2 => 1, reg_cwd_2 => 1, },
    { allele_1  => 'C*07:02', type_1 => 'allele', cwd_1 => 1, reg_cwd_1 => 1,
      allele_2  => 'C*08:06', type_2 => 'allele', cwd_2 => 1, reg_cwd_2 => undef, }
   );
   $table->setData(@tableSubGenotypes);
   ###
   ### Define the header
   ###
   my $header = 
     "SubGenotypes Data\n"
     . "  Population Area = South-East Asia\n"
     . "  Genotype ID     = SJMAM01\n"
     . "  Locus Col Names = HLA-C Allele 1, HLA-C Allele 2\n"
     . "  Row Nums        = (1, 2, 3)";
   ###
   ### Generate the table
   ###
   $table->generateTable($header);

The result of the generateTable is in the log file:

   ######################################################################################
   ###                                                                                ###
   ###  SubGenotypes Data                                                             ###
   ###    Population Area = South-East Asia                                           ###
   ###    Genotype ID     = SJMAM01                                                   ###
   ###    Locus Col Names = HLA-C Allele 1, HLA-C Allele 2                            ###
   ###    Row Nums        = (1, 2, 3)                                                 ###
   ###                                                                                ###
   ###  AlleleSet 1  Type 1  CWD 1  Reg-CWD 1  AlleleSet 2  Type 2  CWD 2  Reg-CWD 2  ###
   ###  -----------  ------  -----  ---------  -----------  ------  -----  ---------  ###
   ###  C*07:02      allele      1          1  C*08:01      allele      1          1  ###
   ###  C*07:02      allele      1          1  C*08:06      allele      1          -  ###
   ###  C*07:03      allele      0          1  C*08:01      allele      1          1  ###
   ###                                                                                ###
   ###                                                                                ###
   ######################################################################################


=head1 METHODS

The following methods are exported by this class.

=head2 B<new util::Table(error_mgr, %cols)>

This is the constructor of the class.  It requires the output stream
B<error_mgr> an object of L<util::ErrMgr> and the specification of the
column names B<%cols>.  The hash %cols contains the designator for the
B<column name> (key) and its corresponding B<column header name>
(value).  Initially, the table has no data.  To add the data to table,
use the method L<"setData(@data)">.

The following table attributes can be modified (see L<"SETTER METHODS"> 
below).

=over 4

=item B<Order of Columns>

The order of columns defines what columns will be generated into the
table.  By default, all columns will be generated into the table in
lexiographic order of the column names.  To change the column order
use L<"setColumnOrder(@ord)">

=item B<Column Justification>

All columns are right justified. To change the column justification
(left, right, center) use L<"setColumnJustification(col,
jusification)">.

=item B<Column Separation>

All columns are separated by two (2) spaces (' ').  To change column
separation use L<"setColumnSeparation(separation)">.

=item B<Maximum Column Width>

The maximum width of a column can be set.  By default, no column has a
column width restriction.  To set a maximum width use
"setColumnWidth(col, width)".  A column can have a value with multiple
lines.  If a column is not restricted, the each line in a multi-line
value, will be generated into a separate with justificaton, as
necessary.  For the semantics of columns with restriction see
L<"setColumnWidth(col, width)">.

=item B<Empty Field Designator>

By default, a column value for a column that is an empty or undefined
(undef) string will be generated in the table as an empty string.  To
change this use L<"setEmptyField(empty_field)">.

=item B<Row Ordering>

By default, no row ordering is defined.  The rows will be output in
the order that they have been input into the table by
L<"setData(@data)">.  To change the row ordering use
L<"setRowOrder(ord_function)">.

=item B<Table Header and Epilogue>

The table will be generated with a header and epilogue specified in
the method L<"generateTable([heading[, epilogue, [@last_rows]])">.
The header and epilogue can be empty (empty string or undef).

=item B<Table Indention>

By default, table indention is zero (0) spaces.  To change this use
L<"setIndent(indent)">.

=item B<Print Table in Header Message>

By default, the table will be generated outside a header message.  To
change this use L<"setInHeader(in_header)">.

=item B<Set the Data in Table>

Initially, the table is empty.  To add data use L<"setData(@data)">.
Each time this method is called the current data is replaced by the
data provided to the method.

=back

=head2 B<generateTable([heading[, epilogue, [@last_rows]])>

This method generates a table with the optional B<heading> and
B<epilogue> using the current attributes as set by the constructor and
the various setter methods below.  Also, if B<@last_rows> array is
provided, then these rows will be added as rows at end of the file
B<'as-is'>.  That is, they will not be ordered but written out in the
order that they appear in @last_rows.  A row in the @last_rows array
will be a referenced Perl hash containing the column names as keys.

=head2 B<generateTabFile(filename[, @last_rows])>

This method generates a tab-separated file (B<filename>) of the
current data in the table including the optional B<@last_rows> rows.
The order of the columns is the column order currently defined and the
data is the data currently set.  The rows are sorted by the row
ordering function if specified, otherwise they are provided in the
order of the data.  The first row in the file contains the column
header names as specified by the constructor.  Also, if B<@last_rows>
array is provided, then these rows will be added as rows at end of the
file B<'as-is'>.  That is, they will not be ordered but written out in
the order that they appear in @last_rows.  A row in the @last_rows
array will be a referenced Perl hash containing the column names as
keys.

=head1 SETTER METHODS

The following setter methods are exported

=head2 B<setColumnSeparation(separation)>

This method sets the column separation where the separation is a
positive integer.  The default is two (2) spaces.

=head2 B<setColumnOrder(@ord)>

This method sets the column order where the elements of B<@ord> are
column names defined by the constructor.  Note that any value in @ord
that is not a column name is ignored.  Also, not all column names need
appear in @ord.  Only those columns in @ord will be generated into the
table.  By default, all columns will be generated into the table in
lexiographic order of the column names defined in the constructor.

=head2 B<setColumnWidth(col, width)>

The B<col> and B<width> are a legitimate column restriction if the col
is a column name defined in the constructor and the width must be a
zero or positive integer. A zero value indicates that the column is
not restricted in width. A positive value must be at least as wide as
the column header for the column name, otherwise the restriction is
ignored.  By default, all columns are unrestricted.

If a column has a legitimate maximum column width, then a value for
the column that is greater than maximum column width will be broken
into segments that are length less than or equal to the maximum column
width.  If the value contains spaces and/or multiple lines, then these
separators are used to break the value into components.  If not, then
the value is a single compoent.  Segments are generated from these
components so that the maximum column width is satisfied.  If a
component is longer than the maximum column width, then the component
is will be broken into maximum column width segments.  All segments
for column value will be broken into separate rows that are justified
as specified for the column.

=head2 B<setIndent(indent)>

This method sets the indention in number of indent spaces where
B<indent> is a non-negative integer.  By default, the indention
is zero (0), that is, no indention.

=head2 B<setColumnJustification(col, jusification)>

This method sets the justification of B<col>, a column name defined in
the construcor, with B<justification> which is one of the of
following:

   util::Table::LEFT_JUSTIFY   -- left justify the column
   util::Table::RIGHT_JUSTIFY  -- right justify the column
   util::Table::CENTER_JUSTIFY -- center the column

By default, each column name will be B<right> justified.

=head2 B<setEmptyField(empty_field)>

The method sets the empty field to be generated in a table if a given
column's value is empty (undefined or empty string).  The default,
empty field value is the empty string ('').  If the empty_field is
undefined, it is set to the empty string.  Also all whitespace at the
beginning and end of the empty_field is removed before it is set.

=head2 B<setInHeader(in_header)>

This method determines whether the table is generated in a message
header (in_header TRUE(1)) or not (in_header FASLSE(0)).  By default,
a table is not generated in a message header.

=head2 B<setRowOrder(ord_function)>

This method set the row order function, B<ord_function>, which must be
a string defining defining a Perl sort function using B<$a> and B<$b>
assuming the elements in the list are referenced Perl hashes with keys
that columns names as defined in the constructor.  See L<"USAGE">
above to see and example ord_function string.  If the B<ord_function>
is undefined (B<undef>) or an empty string, then the ord function is
set to undefined.  By default, the ord function is undefined.  That
is, when the table is generated with no ord function, the order of the
rows is the order in which the data is provided in
L<"setData(@data)">.

=head2 B<setData(@data)>

This method set the list of rows (B<@data>) when generating the table.
Each element of the list of rows is a referenced Perl hash containing
the values of the column names (keys in the hash) as defined in the
constructor.  Initially, the table has no data.  This method sets the
data.  Each time this method is executed, the data that was previously
in the table is replaced by the @data.  If there is no ord function,
the order of @data defines the order in which the rows will be
generated into the table, otherwise the ord_function defines the order
of the rows.

=head2 B<setContinuation(continuation)>

This method sets the continuation string for long cell values that
cannot be broken by spaces.  By default, the continuaion string is a
hyphen ('-').  The continuation string must be defined to be set.

=cut
