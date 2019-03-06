package db::Schema;
################################################################################
#
#				Required Modules
#
################################################################################

use strict;

use Pod::Usage;

use util::Constants;
use util::PathSpecifics;

use db::ErrMsgs;
use db::Types;

use fields qw(
  bcp_directory
  error_mgr
  status
  files
);

################################################################################
#
#				   Constants
#
################################################################################
###
### Data Types
###
sub BCP_TYPE       { return 'bcp' }
sub KEY_TYPE       { return 'key'; }
sub NOT_NULL_TYPE  { return 'not_null'; }
sub ORDER_ORD_TYPE { return 'order_ord'; }
sub ORD_TYPE       { return 'ord'; }
sub VAL_TYPE       { return 'val'; }
###
### Column separators
###
sub RECORD_SEPARATOR { return 'record_separator'; }
sub FIELD_SEPARATOR  { return 'field_separator'; }
###
### Error Category
###
sub ERR_CAT { return db::ErrMsgs::SCHEMA_CAT; }

################################################################################
#
#				Private Methods
#
################################################################################

sub _dieOnError {
  my db::Schema $this = shift;
  my ($msg) = @_;
  $this->{error_mgr}->unsetHardDie if $this->{status};
  $this->{error_mgr}->exitProgram( ERR_CAT, 1, [$msg], $this->{status} );
}

sub _setStatus {
  my db::Schema $this = shift;
  my ($test) = @_;
  return if ( !defined($test) || !$test );
  $this->{status} = util::Constants::TRUE;
}

sub _getList {
  my db::Schema $this = shift;
  my ( $list_name, $file ) = @_;
  return undef if ( !$this->fileInSchema($file) );
  my $tstruct = $this->{files}->{$file};
  return @{ $tstruct->{$list_name} };
}

sub _getItem {
  my db::Schema $this = shift;
  my ( $item_name, $file ) = @_;
  return undef if ( !$this->fileInSchema($file) );
  my $tstruct = $this->{files}->{$file};
  return $tstruct->{$item_name};
}

sub _generateFiles {
  my db::Schema $this = shift;
  my ($table_info) = @_;

  my $files = {};
  $this->{files} = $files;
  foreach my $file ( keys %{$table_info} ) {
    my $file_data = $table_info->{$file};
    ###
    ### Validate data.
    ###
    $this->{error_mgr}->exitProgram(
      ERR_CAT, 1,
      [ "Invalid bcp file type\n" . "  file_type = " . $file_data->{type} ],
      !db::Types::isBcpFileType( $file_data->{type} )
    );
    my $vals          = $file_data->{vals};
    my $not_null      = $file_data->{not_null};
    my $order_ord     = $file_data->{order_ord};
    my $unique_cols   = {};
    my $not_null_cols = {};
    foreach my $col ( @{ $file_data->{key} } ) {
      $this->_setStatus( defined( $unique_cols->{$col} ) );
      $this->_dieOnError( "Repetition of Key column\n" . "  col = $col" );
      $unique_cols->{$col}   = util::Constants::EMPTY_STR;
      $not_null_cols->{$col} = util::Constants::EMPTY_STR;
    }
    if ( defined($vals) ) {
      foreach my $col ( @{$vals} ) {
        $this->_setStatus( defined( $unique_cols->{$col} ) );
        $this->_dieOnError( "Repetition of Vals column\n" . "  col = $col" );
        $unique_cols->{$col} = util::Constants::EMPTY_STR;
      }
    }
    if ( defined($not_null) ) {
      foreach my $col ( @{$not_null} ) {
        $this->_setStatus( !defined( $unique_cols->{$col} ) );
        $this->_dieOnError(
          "Not null Col not a column in file\n" . "  col = $col" );
        $not_null_cols->{$col} = util::Constants::EMPTY_STR;
      }
    }
    if ( defined($order_ord) ) {
      foreach my $col ( @{$order_ord} ) {
        $this->_setStatus( !defined( $unique_cols->{$col} ) );
        $this->_dieOnError(
          "Order Ord col not a column in file\n" . "  col = $col" );
      }
    }
    ###
    ### Store Data
    ###
    $file = lc($file);
    $files->{$file} = {
      &BCP_TYPE         => $file_data->{type},
      &FIELD_SEPARATOR  => db::Types::fieldSeparator( $file_data->{type} ),
      &RECORD_SEPARATOR => db::Types::recordSeparator( $file_data->{type} ),
      &ORD_TYPE         => [ @{ $file_data->{key} }, ],
      &KEY_TYPE         => [ @{ $file_data->{key} } ],
      &NOT_NULL_TYPE    => [ keys %{$not_null_cols} ],
      &ORDER_ORD_TYPE   => [],
      &VAL_TYPE         => [],
    };
    if ( defined($vals) ) {
      push( @{ $files->{$file}->{&VAL_TYPE} }, @{$vals} );
      push( @{ $files->{$file}->{&ORD_TYPE} }, @{$vals} );
    }
    push( @{ $files->{$file}->{&ORDER_ORD_TYPE} }, @{$order_ord} )
      if ( defined($order_ord) );
    ###
    ### Make all column lower-cased
    ###
    foreach my $list_type ( ORD_TYPE, KEY_TYPE, NOT_NULL_TYPE, ORDER_ORD_TYPE,
      VAL_TYPE )
    {
      foreach my $index ( 0 .. $#{ $files->{$file}->{$list_type} } ) {
        $files->{$file}->{$list_type}->[$index] =
          lc( $files->{$file}->{$list_type}->[$index] );
      }
    }
  }
}

################################################################################
#
#				 Public Methods
#
################################################################################

sub new {
  my db::Schema $this = shift;
  my ( $table_info, $bcp_directory, $error_mgr ) = @_;
  $this = fields::new($this) unless ref($this);

  $this->{bcp_directory} = getPath($bcp_directory);
  $this->{error_mgr}     = $error_mgr;
  $this->{files}         = undef;
  $this->{status}        = util::Constants::FALSE;
  ###
  ### Check BCP Directory
  ###
  $this->_setStatus( !-e $this->{bcp_directory} || !-d $this->{bcp_directory} );
  $this->_dieOnError( "Cannot Locate bcp directory\n"
      . "  bcp_directory = "
      . $this->{bcp_directory} );
  ###
  ### Setup File Information
  ###
  $this->_generateFiles($table_info);

  return $this;
}

################################################################################
#
#				 Getter Methods
#
################################################################################

sub bcpDirectory {
  my db::Schema $this = shift;
  return $this->{bcp_directory};
}

sub files {
  my db::Schema $this = shift;
  my $files = $this->{files};
  return () if ( !defined($files) );
  return sort keys %{$files};
}

sub fileInSchema {
  my db::Schema $this = shift;
  my ($file) = @_;
  return util::Constants::FALSE if ( $this->{status} );
  my $files = $this->{files};
  return defined( $files->{$file} );
}

sub colInFile {
  my db::Schema $this = shift;
  my ( $file, $col ) = @_;
  return util::Constants::FALSE
    if ( $this->{status}
    || !$this->fileInSchema($file) );
  foreach my $file_col ( $this->getColumnOrder($file) ) {
    return util::Constants::TRUE if ( $col eq $file_col );
  }
  return util::Constants::FALSE;
}

sub colInFileKey {
  my db::Schema $this = shift;
  my ( $file, $col ) = @_;
  return util::Constants::FALSE if ( !$this->colInFile( $file, $col ) );
  foreach my $key_col ( $this->getColumnKeys($file) ) {
    return util::Constants::TRUE if ( $col eq $key_col );
  }
  return util::Constants::FALSE;
}

sub getColumnOrder {
  my db::Schema $this = shift;
  my ($file) = @_;
  return $this->_getList( ORD_TYPE, $file );
}

sub getRowHash {
  my db::Schema $this = shift;
  my ($file)          = @_;
  my $row_hash        = {};
  foreach my $col ( $this->_getList( ORD_TYPE, $file ) ) {
    $row_hash->{$col} = undef;
  }
  return $row_hash;
}

sub getColumnKeys {
  my db::Schema $this = shift;
  my ($file) = @_;
  return $this->_getList( KEY_TYPE, $file );
}

sub getColumnVals {
  my db::Schema $this = shift;
  my ($file) = @_;
  return $this->_getList( VAL_TYPE, $file );
}

sub getColumnNotNull {
  my db::Schema $this = shift;
  my ($file) = @_;
  return $this->_getList( NOT_NULL_TYPE, $file );
}

sub getOrderOrd {
  my db::Schema $this = shift;
  my ($file) = @_;
  return $this->_getList( ORDER_ORD_TYPE, $file );
}

sub getBcpType {
  my db::Schema $this = shift;
  my ($file) = @_;
  return $this->_getItem( BCP_TYPE, $file );
}

sub getRecordSeparator {
  my db::Schema $this = shift;
  my ($file) = @_;
  return $this->_getItem( RECORD_SEPARATOR, $file );
}

sub getFieldSeparator {
  my db::Schema $this = shift;
  my ($file) = @_;
  return $this->_getItem( FIELD_SEPARATOR, $file );
}

################################################################################

1;

__END__

=head1 NAME

Schema.pm

=head1 SYNOPSIS

   use db::Schema;

=head1 DESCRIPTION

This class constructs the object for the schema defined by table_info.  This
class expects that the table_info data-structure is a (referenced) hash,
whose keys are table/file names (all table/file names will be lower-cased) and
whose values is a referenced hash with the following (key, value)-pairs:

      type      => a valid bcp file file as defined in db::Types; currently,
                   these include:
                   - db::Types::LINE_TYPE
                   - db::Types::MULTI_TYPE
                   - db::Types::TAB_TYPE
      key       => a referenced array of column names defining the key
      vals      => a referenced array of column names defining the other non-
                   key columns in the table (these columns can be NULL); this
                   array may be undefined.
      not_null  => a reference array of column names defining which columns
                   must be not null (do not need to include the key columns
                   since they are assumed not NULL); this array may be undefined
      order_ord => a referenced array of column names that will order the data
                   on reading from the database; this array may be undefined

=head1 METHODS

The following methods are exported by this class:

=head2 B<new db::Schema(table_info, bcp_directory, error_mgr)>

This method is the constructor of the class.  It requires the
B<table_info> data-structure for the data defined above.  The B<bcp_directory>
for the location of reading/generation/writing of bcp files and the
error_mgr which is the error messaging class instance L<util::ErrMgr>.

=head2 B<my $bcp_directory = bcpDirectory>

The method returns the bcp directory into which the bcp-files were
generated.

=head2 B<my @files = files>

The method returns the sorted lists of filenames for the schema.  If
there is none, it returns an empty list.

=head2 B<fileInSchema(file)>

The method returns TRUE (1) if the file is one of the bcp files in
the schema for the object, otherwise it returns FALSE (0).

=head2 B<colInFile(file, col)>

The method returns TRUE (1) if the file is one of the bcp files in the
schema for the object and the col is a column in this file, otherwise
it returns FALSE (0).

=head2 B<colInFileKey(file, col)>

The method returns TRUE (1) if the file is one of the bcp files in the
schema for the object and the col is key column in this file,
otherwise it returns FALSE (0).

=head2 B<my @cols = getColumnOrder(file)>

The method returns a list of columns for the file in the order that
they occur in a row.

=head2 B<my $row = getRowHash(file)>

The method returns a (referenced) hash containing all the columns for
a row in the file.

=head2 B<my @cols = getColumnKeys(file)>

The method returns a list of columns for the file that form the key
for the row.

=head2 B<my @cols = getColumnVals(file)>

The method returns a list of columns for the file that form the value
columns (non-key columns) for the row.

=head2 B<my @cols = getColumnNotNull(file)>

The method returns a list of columns for the file that must not be
null.

=head2 B<my @cols = getOrderOrd(file)>

The method returns the list of columns used to order the select query
from the database.

=head2 B<my $bcp_type = getBcpType(file)>

The method returns the type of the bcp file that will be generated.

=head2 B<my $record_separator = getRecordSeparator(file)>

The method returns record separators for the bcp file.

=head2 B<my $field_separator = getFieldSeparator(file)>

The method returns the field separator for the bcp file.

=cut
