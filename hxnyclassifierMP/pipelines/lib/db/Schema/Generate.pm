package db::Schema::Generate;
################################################################################
#
#				Required Modules
#
################################################################################

use strict;

use Cwd 'chdir';
use FileHandle;
use Pod::Usage;

use util::Constants;
use util::PathSpecifics;

use base 'db::Schema';

use fields qw(
  bcp_files
  bcp_handles
  files_loaded
);

################################################################################
#
#				Private Methods
#
################################################################################

sub _closeHandleDieOnError {
  my db::Schema::Generate $this = shift;
  my ( $msg, $test ) = @_;
  return if ( !$test );
  $this->_setStatus($test);
  $this->_dieOnError($msg);
}

sub _printRowError {
  my db::Schema::Generate $this = shift;
  my ( $file, $column, $value, $msg ) = @_;
  return if ( !$this->{status} );
  $this->{error_mgr}->printError(
    "Undefined $msg column, not writing bcp file...\n"
      . "  file = $file\n"
      . "  col  = $column\n"
      . '  row  = ',
    util::Constants::TRUE
  );
  foreach my $col ( sort keys %{$value} ) {
    $this->{error_mgr}
      ->printError( "    $col = " . $value->{$col}, util::Constants::TRUE );
  }
  $this->_dieOnError("Terminating SchemaOutput on Error");
}

sub _getBcpHandle {
  my db::Schema::Generate $this = shift;
  my ($file) = @_;
  $this->_dieOnError(
    "Object is in error state will not open bcp file\n" . "  file = $file" );
  return $this->{bcp_handles}->{$file}
    if ( defined( $this->{bcp_handles}->{$file} ) );
  ###
  ### Is this file part of the database schema?
  ###
  $this->_setStatus( !$this->fileInSchema($file) );
  $this->_dieOnError("Unable to find file ($file) in schema");
  ###
  ### Open the bcp-handle for the file.
  ###
  $this->{bcp_handles}->{$file} = new FileHandle;
  my $bcp_file = $this->{bcp_files}->{$file};
  $this->_setStatus( !$this->{bcp_handles}->{$file}->open( $bcp_file, '>' ) );
  $this->_dieOnError("Unable to open bcp_file = $bcp_file");
  ###
  ### Make Unbuffered
  ###
  $this->{bcp_handles}->{$file}->autoflush(util::Constants::TRUE);
  return $this->{bcp_handles}->{$file};
}

sub _writeBcp {
  my db::Schema::Generate $this = shift;
  my ( $file, $value ) = @_;
  $this->_dieOnError( "Object is in error state will not write to bcp file\n"
      . "  file = $file" );
  $this->_setStatus( !defined($file) || $file eq util::Constants::EMPTY_STR );
  $this->_dieOnError("file is not defined");
  ###
  ### Check and write out row
  ###
  foreach my $column ( $this->getColumnNotNull($file) ) {
    $this->_setStatus( !defined( $value->{$column} )
        || $value->{$column} eq util::Constants::EMPTY_STR );
    $this->_printRowError( $file, $column, $value, 'non-nullable' );
  }
  foreach my $column ( $this->getColumnKeys($file) ) {
    $this->_setStatus( !exists( $value->{$column} ) );
    $this->_printRowError( $file, $column, $value, 'primary key' );
  }
  my $bcp_handle   = $this->_getBcpHandle($file);
  my $first_column = util::Constants::TRUE;
  foreach my $column ( $this->getColumnOrder($file) ) {
    $bcp_handle->print( $this->getFieldSeparator($file) ) if ( !$first_column );
    if ( defined( $value->{$column} )
      && $value->{$column} ne util::Constants::EMPTY_STR )
    {
      $bcp_handle->print( $value->{$column} );
    }
    $first_column = util::Constants::FALSE;
  }
  $bcp_handle->print( $this->getRecordSeparator($file) );
}

################################################################################
#
#				 Public Methods
#
################################################################################

sub new {
  my ( $that, $table_info, $bcp_directory, $error_mgr ) = @_;
  my db::Schema::Generate $this =
    $that->SUPER::new( $table_info, $bcp_directory, $error_mgr );

  chdir(util::Constants::DOT);
  $this->{bcp_files}    = {};
  $this->{bcp_handles}  = {};
  $this->{files_loaded} = [];
  ###
  ### Create File Names
  ###
  foreach my $file ( $this->files ) {
    $this->{bcp_files}->{$file} = join( util::Constants::SLASH,
      $this->{bcp_directory},
      join( util::Constants::DOT, $file, $this->BCP_TYPE )
    );
  }

  return $this;
}

################################################################################
#
#				 Setter Methods
#
################################################################################

sub generateRow {
  my db::Schema::Generate $this = shift;
  my ( $file, $entity ) = @_;
  eval { $this->_writeBcp( $file, $entity ); };
  my $status = $@;
  $this->_dieOnError(
    "Cannot write to file\n"
      . "  file   = $file\n"
      . "  errMsg = $status\n"
      . "  data   = ("
      . join( util::Constants::COMMA_SEPARATOR, %{$entity} ) . ")",
    defined($status) && $status
  );
}

sub closeBcpHandles {
  my db::Schema::Generate $this = shift;
  while ( my ( $filename, $file ) = each %{ $this->{bcp_files} } ) {
    if ( defined( $this->{bcp_handles}->{$filename} ) ) {
      $this->{error_mgr}->printMsg("Closing bcp-file for $filename");
      $this->{bcp_handles}->{$filename}->close();
      $this->{bcp_handles}->{$filename} = undef;
      push( @{ $this->{files_loaded} }, $filename );
    }
  }
}

################################################################################
#
#				 Getter Methods
#
################################################################################

sub fileCovered {
  my db::Schema::Generate $this = shift;
  my ( $file, @columns ) = @_;
  ###
  ### Setup the test column set
  ###
  my %column_finder = ();
  foreach my $column (@columns) {
    $column_finder{$column} = util::Constants::EMPTY_STR;
  }
  ###
  ### Check to see if there is a file
  ###
  my @file_columns = $this->getColumnOrder($file);
  $this->_setStatus( ( @file_columns > 0 ) );
  $this->_dieOnError( "File missing from schema\n" . "  file = $file" );
  ###
  ### Check coverage
  ###
  my $columns_check = util::Constants::TRUE;
  foreach my $column (@file_columns) {
    my $column_error =
      !defined( $column_finder{$column} )
      ? util::Constants::TRUE
      : util::Constants::FALSE;
    $this->{error_mgr}->printError(
      "Column missing in file\n" . "  file   = $file\n" . "  column = $column",
      $column_error
    );
    $columns_check = $column_error ? util::Constants::FALSE : $columns_check;
  }
  return $columns_check;
}

sub filesLoaded {
  my db::Schema::Generate $this = shift;
  return @{ $this->{files_loaded} };
}

################################################################################

1;

__END__

=head1 NAME

Generate.pm

=head1 SYNOPSIS

   use db::Schema::Generate;

=head1 DESCRIPTION

This module defines how bcp files are generated and is a subclass of
L<db::Schema>.

=head1 METHODS

The following methods are exported for this class.

=head2 B<new db::Schema::Generate(table_info, bcp_directory, error_mgr)>

This method is the constructor of the class.  It requires the
B<table_info>, to define the schema content and the B<bcp_directory>
for the location of generation of bcp files.  Finally, this method 
requires the error message manager B<error_mgr>, L<util::ErrMgr>.

=head2 B<generateRow(file, values)>

This method writes a row out to the bcp B<file> defined by the
referenced hash, B<values>.  If the bcp file is not open, then this
method will open the file names as follows:

   <bcp_directory>/<file>.bcp

For the given file, the schema defines the column order of the row,
which columns must not be null, and which ones are key columns.
Non-null columns must be defined in B<values> and be non-empty.  Key
column must exist in B<values>, but do not need to be defined unless
they are also non-null.

=head2 B<closeBcpHandles>

This method will close all bcp file handles that have been opened
by the B<run> method.

=head2 B<fileCovered(file, @columns)>

This method returns TRUE (1) if it determines that the list of B<@columns> 
include all columns defined for the bcp B<file> in the schema, otherwise
it returns FALSE (0).

=head2 B<my @files_loaded = filesLoaded>

This method returns the list of bcp-file names loaded after the bcp handles
have been closed by L<"closeBcpHandles">.

=cut
