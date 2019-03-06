package file::Chunk::Excel;
################################################################################
#
#				Required Modules
#
################################################################################

use strict;

use Pod::Usage;
use Spreadsheet::ParseExcel;

use util::Constants;
use util::PathSpecifics;

use file::ErrMsgs;

use base 'file::Chunk';

use fields qw (
  entities
  entity
  field_separator
  sheet_index
  row_index
  worksheets
  ord
);

################################################################################
#
#				   Constants
#
################################################################################
###
### File Type
###
sub FILE_TYPE { return 'tsf'; }
###
### Buffer Size
###
sub LOCAL_BATCH_SIZE { return 100000; }
###
### work sheet attribute for an entity
###
sub WORKSHEET_NUMBER_COL { return '__Excel_worksheet_number_Excel__'; }
###
### Error Category
###
sub ERR_CAT { return file::ErrMsgs::CHUNK_CAT; }

################################################################################
#
#			     Private Methods
#
################################################################################

sub _readExcelEntity {
  my file::Chunk::Excel $this = shift;
  my $found_entity = util::Constants::FALSE;
  if ( !defined( $this->{sheet_index} ) ) {
    $this->{sheet_index} = 0;
    $this->{row_index}   = 0;
    $this->{worksheets}  = {};
    if ( defined( $this->serializer ) ) {
      my $print_workbook = { %{ $this->{source_fh} } };
      $this->{error_mgr}->printHeader("Workbook Data-Structure");
      $this->{error_mgr}->printMsg(
        "workbook = "
          . $this->serializer->serializeObject(
          $print_workbook, $this->serializer->PERL_OBJECT_WRITE_OPTIONS
          )
      );
    }
  }
  return $found_entity
    if ( $this->{sheet_index} > $#{ $this->{source_fh}->{Worksheet} } );
  my $sheet = $this->{source_fh}->{Worksheet}->[ $this->{sheet_index} ];
  if ( $this->{row_index} > $sheet->{MaxRow} ) {
    my $found_sheet = util::Constants::FALSE;
    foreach my $sheet_index (
      ( $this->{sheet_index} + 1 ) .. $#{ $this->{source_fh}->{Worksheet} } )
    {
      $sheet = $this->{source_fh}->{Worksheet}->[$sheet_index];
      next
        if ( $sheet->{MaxRow} == 0
        && $sheet->{MinRow} == $sheet->{MaxRow}
        && $sheet->{MaxCol} == 0
        && $sheet->{MinCol} == $sheet->{MaxCol} );
      $this->{row_index}   = 0;
      $this->{sheet_index} = $sheet_index;
      $found_sheet         = util::Constants::TRUE;
      last;
    }
    if ( !$found_sheet ) {
      $this->{sheet_index}++;
      return $found_entity;
    }
  }
  if ( defined( $this->serializer ) && $this->{row_index} == 0 ) {
    my $print_sheet = { %{$sheet} };
    $this->{error_mgr}->printHeader("Worksheet ($sheet) Data-Structure");
    $this->{error_mgr}->printMsg(
      "worksheet = "
        . $this->serializer->serializeObject(
        $print_sheet, $this->serializer->PERL_OBJECT_WRITE_OPTIONS
        )
    );
  }
  my $sheet_num = int($sheet);
  $this->{worksheets}->{$sheet_num} = util::Constants::EMPTY_STR;
  $found_entity = util::Constants::TRUE;
  $this->{entity} = { &WORKSHEET_NUMBER_COL => $sheet_num, };
  foreach my $col ( @{ $this->{ord} } ) { $this->{entity}->{$col} = undef; }
  my $index = 0;
  foreach my $col ( $sheet->{MinCol} .. $sheet->{MaxCol} ) {
    my $cell = $sheet->Cell( $this->{row_index}, $col );
    my $value = undef;
    if ( defined($cell) ) { $value = $cell->{Val}; }
    if ( !util::Constants::EMPTY_LINE($value) ) {
      $this->{entity}->{ $this->{ord}->[$index] } = $value;
    }
    $index++;
  }
  ###
  ### Before return increment row count for next row.
  ###
  $this->{row_index}++;

  return $found_entity;
}

sub _getLine {
  my file::Chunk::Excel $this = shift;
  my @cols = ();
  foreach my $col ( @{ $this->{ord} } ) {
    push( @cols, $this->{entity}->{$col} );
  }
  return join( $this->{field_separator}, @cols );
}

################################################################################
#
#				 Public Methods
#
################################################################################

sub new {
  my ( $that, $directory, $file_ord, $error_mgr ) = @_;
  my file::Chunk::Excel $this =
    $that->SUPER::new( FILE_TYPE, LOCAL_BATCH_SIZE, $directory, $error_mgr );

  $this->{field_separator} = util::Constants::TAB;
  $this->{ord}             = $file_ord;
  $this->{row_index}       = undef;
  $this->{sheet_index}     = undef;
  $this->{worksheets}      = undef;

  $this->{error_mgr}->exitProgram( ERR_CAT, 9, [ ref($this) ],
        !defined( $this->{ord} )
      || ref( $this->{ord} ) ne 'ARRAY'
      || @{ $this->{ord} } == 0 );

  return $this;
}

sub setSourceFile {
  my file::Chunk::Excel $this = shift;
  my ($file) = @_;
  $this->{source_file} = getPath($file);
  $this->{file_kind}   = xml::Types::PLAIN_FILE_TYPE;
  $this->{source_fh}   = Spreadsheet::ParseExcel::Workbook->Parse($file);
}

sub closeSourceFile($) {
  my file::Chunk::Excel $this = shift;
  ###
  ### NO-OP
  ###
}

sub chunkFile {
  my file::Chunk::Excel $this = shift;
  $this->{file_index} = {};
  $this->{files}      = [];
  $this->{lines}      = [];
  my $entity_count = 0;
  while ( $this->_readExcelEntity ) {
    $entity_count++;
    push( @{ $this->{lines} }, $this->_getLine );
    $this->writeChunk if ( $entity_count % $this->{size} == 0 );
  }
  $this->writeChunk;
  $this->closeSourceFile;
  return scalar @{ $this->{files} };
}

sub readExcelFile {
  my file::Chunk::Excel $this = shift;
  $this->{entities} = [];
  while ( $this->_readExcelEntity ) {
    push( @{ $this->{entities} }, $this->{entity} );
  }
  $this->closeSourceFile;
}

sub getEntities {
  my file::Chunk::Excel $this = shift;
  return $this->{entities};
}

sub _orderWorkSheets { $a <=> $b; }

sub getWorksheetNums {
  my file::Chunk::Excel $this = shift;
  return
    sort file::Chunk::Excel::_orderWorkSheets keys %{ $this->{worksheets} };
}

sub getWorksheet {
  my file::Chunk::Excel $this = shift;
  my ($worksheet_num) = @_;

  my @entities   = ();
  my $worksheets = $this->{worksheets};
  return @entities if ( !defined( $worksheets->{$worksheet_num} ) );
  my $first_entity = util::Constants::TRUE;
  foreach my $entity ( @{ $this->getEntities } ) {
    my $ews_num = $entity->{&WORKSHEET_NUMBER_COL};
    push( @entities, $entity ) if ( $ews_num == $worksheet_num );
    if ( $first_entity && $ews_num == $worksheet_num ) {
      $first_entity = util::Constants::FALSE;
    }
    last if ( !$first_entity && $ews_num != $worksheet_num );
  }
  return @entities;
}

################################################################################

1;

__END__

=head1 NAME

Excel.pm

=head1 SYNOPSIS

This concrete class provides the mechanism to chunk a MicroSoft Excel
spreedsheet into tab-separated field, new-line row chunk files using
the order specification provided.  Also, each entity has a class
defined attribute:

  file::Chunk::Excel::WORKSHEET_NUMBER_COL -- __Excel_worksheet_number_Excel__

that defines the worksheet from which entity come in the Excel file.

=head1 METHODS

The following methods are exported from the class.

=head2 B<new file::Chunk::Excel(directory, file_order, error_mgr)>

This is the constructor of the class and requires the file_order
(referenced) array that defines the names of the columns in the in the
cells of the Excel file.  Each row in the Excel file is treated as a
record.  Also, the directory is where the chunks will be generated.
The constructor set the size to 5000 defined rows.  The construct sets
the file order using the reference non-empty array B<file_order>.

=head2 B<chunkFile>

This method takes the stream represented by the file handle, fh and
chunks it size entities where entity boundaries are not violated.
Each chunk will be generated into a gzipped filename, where N is the
chunk number (N >= 0) and B<directory> and B<chunk_prefix> are the
attributes of the object:

  <directory>/<chunk_prefix>.000N.bcp.gz,         N < 10
  <directory>/<chunk_prefix>.00N.bcp.gz,  10   <= N < 100
  <directory>/<chunk_prefix>.0N.bcp.gz,   100  <= N < 1000
  <directory>/<chunk_prefix>.N.bcp.gz,    1000 <= N < 10000

This method returns the number of chunks created.

=head2 B<readExcelFile>

This method reads the source_file into the entities array which is a
list of hash entries with the keys defined by the file order.

=head2 B<$entities = getEntities>

This method returns the array of entities generated by
L<"readExcelFile">.

=head2 B<@workshet_nums = getWorksheetNums>

This method return the list of worksheet numbers in order for which
there is daata read from the Excel file.

=head2 B<@entities  = getWorksheet(worksheet_num)>

This method returns the list of entities that are in the given
worksheet number.

=cut
