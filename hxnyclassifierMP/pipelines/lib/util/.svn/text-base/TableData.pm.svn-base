package util::TableData;
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
use util::Table;

use util::ErrMsgs;

use fields qw (
  error_mgr
  table_data
  infix
  strip_whitespace
  tools
);

################################################################################
#
#				Constants
#
################################################################################

###
### Error Category
###
sub ERR_CAT { return util::ErrMsgs::TABLEDATA_CAT; }

################################################################################
#
#				Private Methods
#
################################################################################

sub _generateSortFunc {
  my util::TableData $this = shift;
  my ( $table, $sort_ord ) = @_;

  return
    if ( util::Constants::EMPTY_LINE($sort_ord)
    || ref($sort_ord) ne $this->{tools}->serializer->ARRAY_TYPE
    || scalar @{$sort_ord} == 0 );

  my $sort_func = 'sub {';
  foreach my $tag ( @{$sort_ord} ) {
    if ( $sort_func ne 'sub {' ) { $sort_func .= ' or '; }
    $sort_func .= '$a->{"' . $tag . '"} cmp $b->{"' . $tag . '"}';
  }
  $sort_func .= ';}';
  $table->setRowOrder($sort_func);
}

sub _generateTable {
  my util::TableData $this = shift;
  my ( $col_ord, $name_ord, $sort_ord ) = @_;

  my %cols = ();
  foreach my $index ( 0 .. $#{$col_ord} ) {
    $cols{ $col_ord->[$index] } = $name_ord->[$index];
  }
  my $table = new util::Table( $this->{error_mgr}, %cols );
  $table->setColumnOrder( @{$col_ord} );
  $table->setEmptyField(util::Constants::HYPHEN);
  $table->setContinuation(util::Constants::EMPTY_STR);
  $table->setInHeader(util::Constants::TRUE);
  $this->_generateSortFunc( $table, $sort_ord );
  foreach my $col ( @{$col_ord} ) {
    $table->setColumnJustification( $col, $table->LEFT_JUSTIFY );
  }
  return $table;
}

################################################################################
#
#				Constructor Method
#
################################################################################

sub new($$$$) {
  my util::TableData $this = shift;
  my ( $infix, $tools, $error_mgr ) = @_;
  $this = fields::new($this) unless ref($this);

  $this->{table_data}       = {};
  $this->{error_mgr}        = $error_mgr;
  $this->{infix}            = $infix;
  $this->{strip_whitespace} = util::Constants::TRUE;
  $this->{tools}            = $tools;

  return $this;
}

################################################################################
#
#				High-Level Read/Write Methods
#
################################################################################

sub setTableInfo {
  my util::TableData $this = shift;
  my ( $table_type, $separator ) = @_;

  my $file = $this->getFile($table_type);
  return if ( util::Constants::EMPTY_LINE($file) );
  $this->{table_data}->{$table_type}->{data} =
    $this->readFile( $file, $this->getOrd($table_type),
    $table_type, $separator );
}

sub setTableInfoRaw {
  my util::TableData $this = shift;
  my ( $table_type, $separator ) = @_;

  $separator =
    ( !util::Constants::EMPTY_LINE($separator) )
    ? $separator
    : util::Constants::TAB;

  my $data = $this->getTableInfo($table_type);
  my $file = $this->getFile($table_type);
  my $ord  = $this->getOrd($table_type);
  return if ( !defined($file) );
  my $fh = new FileHandle;
  $this->{error_mgr}->exitProgram(
    ERR_CAT, 3,
    [ $table_type, $file, ],
    !$fh->open( $file, '<' )
  );

  while ( !$fh->eof ) {
    my $line = $fh->getline;
    chomp($line);
    my @row = split( /$separator/, $line );
    my $struct = $this->createTableStruct($table_type);
    foreach my $index ( 0 .. $#{$ord} ) {
      last if ( $index > $#row );
      if ( $this->{strip_whitespace} ) {
        $struct->{ $ord->[$index] } = strip_whitespace( $row[$index] );
      }
      else {
        $struct->{ $ord->[$index] } = $row[$index];
      }
    }
    push( @{$data}, $struct );
  }
  $fh->close;
}

sub writeTableInfo {
  my util::TableData $this = shift;
  my ($table_type) = @_;

  my $ord     = $this->getOrd($table_type);
  my $names   = $this->getNames($table_type);
  my $data    = $this->getTableInfo($table_type);
  my $sortOrd = $this->getSortOrd($table_type);
  my $file    = $this->getFile($table_type);
  return if ( !defined($ord) || scalar @{$data} == 0 );
  my $table = $this->_generateTable( $ord, $names, $sortOrd );
  $table->setData( @{$data} );
  $table->generateTabFile($file);
}

sub writeTableInfoRaw {
  my util::TableData $this = shift;
  my ($table_type) = @_;

  my $data = $this->getTableInfo($table_type);
  my $file = $this->getFile($table_type);
  my $ord  = $this->getOrd($table_type);
  return if ( !defined($data) || scalar @{$data} == 0 );
  my $fh = new FileHandle;
  $this->{error_mgr}->exitProgram(
    ERR_CAT, 2,
    [ $table_type, $file, ],
    !$fh->open( $file, '>' )
  );
  $fh->autoflush(util::Constants::TRUE);

  foreach my $struct ( @{$data} ) {
    my @row = ();
    foreach my $col ( @{$ord} ) {
      push( @row, $struct->{"$col"} );
    }
    $fh->print( join( util::Constants::TAB, @row ) . util::Constants::NEWLINE );
  }
  $fh->close;
}

################################################################################
#
#				Getter Methods
#
################################################################################

sub infix {
  my util::TableData $this = shift;

  $this->{infix};
}

sub tableTypes {
  my util::TableData $this = shift;

  return sort keys %{ $this->{table_data} };
}

sub isTableType {
  my util::TableData $this = shift;
  my ($table_type) = @_;

  foreach my $type ( $this->tableTypes ) {
    return util::Constants::TRUE if ( $type eq $table_type );
  }
  return util::Constants::FALSE;
}

sub getOrd {
  my util::TableData $this = shift;
  my ($table_type) = @_;

  my $table_data = $this->{table_data}->{$table_type};
  return undef if ( !defined($table_data) );
  return [ @{ $table_data->{ord} } ];

}

sub getNames {
  my util::TableData $this = shift;
  my ($table_type) = @_;

  my $table_data = $this->{table_data}->{$table_type};
  return undef if ( !defined($table_data) );
  return [ @{ $table_data->{names} } ];

}

sub getSortOrd {
  my util::TableData $this = shift;
  my ($table_type) = @_;

  my $table_data = $this->{table_data}->{$table_type};
  return undef if ( !defined($table_data) );
  return [ @{ $table_data->{sort_ord} } ];

}

sub getFile {
  my util::TableData $this = shift;
  my ($table_type) = @_;

  my $table_data = $this->{table_data}->{$table_type};
  return undef if ( !defined($table_data) );
  return $table_data->{file};
}

sub getTableInfo {
  my util::TableData $this = shift;
  my ($table_type) = @_;

  my $table_data = $this->{table_data}->{$table_type};
  return undef if ( !defined($table_data) );
  return $table_data->{data};
}

sub createStruct {
  my util::TableData $this = shift;
  my ($cols) = @_;

  my $struct = {};
  foreach my $col ( @{$cols} ) {
    $struct->{"$col"} = util::Constants::EMPTY_STR;
  }
  return $struct;
}

sub createTableStruct {
  my util::TableData $this = shift;
  my ( $table_type, $datum ) = @_;

  my $ord    = $this->getOrd($table_type);
  my $struct = $this->createStruct($ord);
  foreach my $index ( 0 .. $#{$ord} ) {
    last if ( $index > $#{$datum} );
    next if ( util::Constants::EMPTY_LINE( $datum->[$index] ) );
    $struct->{ $ord->[$index] } = $datum->[$index];
  }
  return $struct;
}

sub createTableDatum {
  my util::TableData $this = shift;
  my ( $table_type, $struct ) = @_;

  my $datum = [];
  foreach my $col ( @{ $this->getOrd($table_type) } ) {
    push( @{$datum}, $struct->{$col} );
  }
  return $datum;
}

################################################################################
#
#				Setter Methods
#
################################################################################

sub setStripWhiteSpace {
  my util::TableData $this = shift;
  my ($strip_whitespace) = @_;

  return if ( util::Constants::EMPTY_LINE($strip_whitespace) );
  $this->{strip_whitespace} =
    $strip_whitespace ? util::Constants::TRUE : util::Constants::FALSE;
}

sub initializeTableData {
  my util::TableData $this = shift;

  foreach my $table_type ( $this->tableTypes ) {
    $this->{table_data}->{$table_type}->{data} = [];
  }
}

sub setTableData {
  my util::TableData $this = shift;
  my ( $name, $ord, $sort_ord, $names ) = @_;

  my $table_data = $this->{table_data};
  return
    if ( util::Constants::EMPTY_LINE($name)
    || util::Constants::EMPTY_LINE($ord)
    || ref($ord) ne $this->{tools}->serializer->ARRAY_TYPE
    || scalar @{$ord} == 0 );
  my $sord = [];
  if ( !util::Constants::EMPTY_LINE($sort_ord)
    && ref($sort_ord) eq $this->{tools}->serializer->ARRAY_TYPE
    && scalar @{$sort_ord} > 0 )
  {
    $sord = [ @{$sort_ord} ];
  }
  $table_data->{$name} = {
    file     => undef,
    ord      => [ @{$ord} ],
    sort_ord => $sord,
    data     => [],
    names    => [ @{$ord} ],
  };
  if ( !util::Constants::EMPTY_LINE($names)
    && ref($names) eq $this->{tools}->serializer->ARRAY_TYPE
    && scalar @{$names} == scalar @{$ord} )
  {
    $table_data->{$name}->{names} = [ @{$names} ];
  }
}

sub addTableRow {
  my util::TableData $this = shift;
  my ( $table_type, $datum ) = @_;

  my $data = $this->getTableInfo($table_type);
  return if ( !defined($data) );
  my $struct = $this->createTableStruct( $table_type, $datum );
  push( @{$data}, $struct );
}

sub setFile {
  my util::TableData $this = shift;
  my ( $table_type, $file ) = @_;

  my $table_data = $this->{table_data}->{$table_type};
  return if ( !defined($table_data) );
  $table_data->{file} = getPath($file);
}

################################################################################
#
#				Low-Level Read and Write Methods
#
################################################################################

sub readFile {
  my util::TableData $this = shift;
  my ( $file, $ord, $msg, $separator ) = @_;

  $separator =
    ( !util::Constants::EMPTY_LINE($separator) )
    ? $separator
    : util::Constants::TAB;

  $file = getPath($file);
  my $fh = new FileHandle;
  $this->{error_mgr}->exitProgram(
    ERR_CAT, 1,
    [ $this->infix, $file, $msg, ],
    !$fh->open( $file, '<' )
  );
  my %cols_map = ();
  foreach my $col ( @{$ord} ) { $cols_map{$col} = $col; }
  my $rowNum    = 0;
  my @file_cols = ();
  my $data      = [];

  while ( !$fh->eof ) {
    $rowNum++;
    my $line = $fh->getline;
    chomp($line);
    my @row = split( /$separator/, $line );
    if ( $rowNum == 1 ) {
      @file_cols = ();
      foreach my $col (@row) {
        push( @file_cols, strip_whitespace($col) );
      }
      next;
    }
    my $struct = $this->createStruct($ord);
    foreach my $index ( 0 .. $#row ) {
      last if ( $index > $#file_cols );
      my $col = $file_cols[$index];
      next if ( !defined( $cols_map{$col} ) );
      my $val = $row[$index];
      next if ( util::Constants::EMPTY_LINE($val) );
      if ( $this->{strip_whitespace} ) {
        $val = strip_whitespace($val);
        next if ( util::Constants::EMPTY_LINE($val) );
      }
      $struct->{$col} = $val;
    }
    push( @{$data}, $struct );
  }
  $fh->close;
  return $data;
}

sub generateTableFile {
  my util::TableData $this = shift;
  my ( $col_ord, $sort_ord, $file_comps, $data ) = @_;

  my $tools = $this->{tools};
  my $file  = join( util::Constants::SLASH,
    $tools->executionDir,
    join( util::Constants::DOT,
      $tools->scriptPrefix, $tools->getProperty( $tools->LOG_INFIX_PROP ),
      @{$file_comps},       'xls'
    )
  );
  my $table = $this->_generateTable( $col_ord, $col_ord, $sort_ord );
  $table->setData( @{$data} );
  $table->generateTabFile($file);
}

################################################################################

1;

__END__

=head1 NAME

TableData.pm

=head1 DESCRIPTION

This concreate class defines the standard mechanism for reading and
writing standard sets of tab-separated files

=head1 CONSTANTS


=head1 METHODS

The following methods are exported by this class.

=head2 B<new util::TableData(infix, tools, error_mgr)>

This is the constructor for the class.  The B<infix> defines the set
of tab-separated files and is used in error messages.

=head2 B<initializeTableData>

This method removes all loaded/added data for all table types defined
for the object.

=head2 B<writeTableInfo(table_type)>

This method writes the current content of the B<table_type> to the as
a tab-separated file into the file defined by B<setFile>.  This method
only writes the content is there is any and will inserts a header row
as the first row in the file.

=head2 B<writeTableInfoRaw(table_type)>

This method writes the current content of the B<table_type> to the as
a tab-separated file into the file defined by B<setFile>.  This method
only writes the content is there is any and does B<NOT> insert a
header row as the first row in the file.

=head2 B<generateTableFile(col_ord, sort_ord, file_comps, data)>

This method is a low-level method for writting a tab-separated file
whose ordered columns are B<col_ord> (referenced Perl array) and whose
rows are ordered by B<sort_ord> (referenced Perl array).  The B<data>
(referenced Perl array of referenced Perl hashes) is a set of
data-structure containing the columns B<col_ord> that will be written
to the tab-separated file.  The referenced Perl array B<file_comps>
will be the infix components of the file name as follows:

   <execution_directory>/<script_prefix>.<log_infix>.<file_comps_with_dots>.xls

where B<file_comps_with_dots> is the join of the the components in
B<file_comps> with dot (B<'.'>).

=head1 GETTER METHODS

The following getter methods are exported by this class.

=head2 B<$struct = createStruct(cols)>

This method takes a reference Perl array of column headers and creates
a referenced Perl hash with these columns set to the empty-string.

=head2 B<$struct = createTableStruct(table_type, datum)>

This method takes a B<table_type> defined by B<setTableData> and a
B<datum> (referenced Perl array of data) and creates a reference Perl
hash whose keys are the columns for the B<table_type> and values are
defined positional by B<datum>.

=head2 B<$datum = createTableDatum(table_type, struct)>

This method tables a B<table_type> defined by B<setTableData> and
B<struct> ( referenced Perl hash) and returns a referenced Perl array
whose positional values are the values of the columns defined by
B<table_type> using B<struct>.

=head2 B<$infix = infix>

This method returns the B<infix> for the object.

=head2 B<@table_types = tableTypes>

This method return the list of table types currently defined for the
the object.

=head2 B<$ord = getOrd(table_type)>

This method return a referenced Perl array of the ordered columns for
a B<table_type>.

=head2 B<$names = getNames(table_type)>

This method returns a referenced Perl array of column headers for the
B<table_type>.

=head2 B<$sort_ord = getSortOrd(table_type)>

This method return a referenced Perl array of the sorting columns for
the table_type.

=head2 B<$file = getFile(table_type)>

This method returns the file name set for the the B<table_type>

=head2 B<$data = getTableInfo(table_type)>

This method returns the referenced Perl array of the content for the
B<table_type>.  each component is a referenced Perl hash containing
the columns for the B<table_type>.

=head1 SETTER METHODS

The following setter methods are exported by this class.

=head2 B<setTableData(name, ord, sort_ord[, names])>

This method defines a B<table_type> whose name is B<name> and whose
ordered columns are defined the referenced Perl array B<ord>.  The
referenced Perl array B<sort_ord> defines how the row of data will be
sorted using the columns defined by B<ord>.  The optional referenced
Perl array defines the column header names.  If B<names> is not
defined or empty, then the column header names are those for B<ord>.
If there column header names, differ from the names in B<ord>, then a
file written by B<writeTableInfo> will not be readable by
B<setTableInfo>.

=head2 B<addTableRow(table_type, datum)>

This method takes a B<table_type> defined by <setTableData> and a
B<datum> (referenced Perl array of data), generates a referenced Hash
data-structure for the B<table_type> and B<datum> and adds it to the
current data for B<table_type>.

=head2 B<setFile(table_type, file)>

This method takes a B<table_type> defined by <setTableData> and a
B<file> and sets the output/input filename for B<table_type>.

=head2 B<setTableInfo(table_type, separator)>

This method reads the file defined by B<setFile> using the definition
of B<table_type> as defined by B<setTableData>.  The data read by this
method is available via B<getTableInfo>.  This method assumes that the
first line of the tab-separated file contains the file headers and
that these headers correspond to one defined by B<setTableData>.
If the separator is provided and not empty, it is used, otherwise
tab-character is used.

=head2 B<setTableInfoRaw(table_type, separator)>

This method reads the file defined by B<setFile> using the definition
of B<table_type> as defined by B<setTableData>.  The data read by this
method is available via B<getTableInfo>.  This method assumes that
there is no header line (first line in the file).
If the separator is provided and not empty, it is used, otherwise
tab-character is used.

=cut
