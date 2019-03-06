package file::ErrMsgs;
################################################################################
#
#				Required Modules
#
################################################################################

use strict;

use Pod::Usage;

use util::ErrMsgs;

################################################################################
#
#			     Constant Class Methods
#
################################################################################

###
### Error Messages Header
###
sub ERROR_HEADER { return 'FILE-ERROR: '; }

sub STRUCT_CAT       { return -1001000; }    ### Struct Class
sub STRUCTASN_CAT    { return -1002000; }    ### Struct Asn Class
sub CHUNK_CAT        { return -1003000; }    ### Chunk Class
sub INDEX_CAT        { return -1004000; }    ### Index Class
sub FASTA_CAT        { return -1005000; }    ### Fasta Class
sub STRUCTBCP_CAT    { return -1006000; }    ### Struct Bcp Class
sub STRUCTEXCEL_CAT  { return -1007000; }    ### Struct Excel Class
sub HLA_CAT          { return -1008000; }    ### Hla Class
sub HLACONVERTER_CAT { return -1009000; }    ### HLA File Converter Class

################################################################################
#
#			     Public Static Constant
#
################################################################################

sub ERROR_MSGS {
  my $errMsgs = {

    &STRUCT_CAT =>
      { 1 => "Error has occurred, exting program...\n" . "  errMgs = __1__", },

    &STRUCTASN_CAT => {
      1 => "Cannot open file to write object, terminating...\n"
        . "  file = __1__",

      2 => "Parent not an util::AsnEntity, terminating...\n"
        . "  path = (__1__)",

      3 => "Parent not an util::AsnEntity, terminating...\n"
        . "  attr = __1__\n"
        . "  path = (__2__)",

    },

    &CHUNK_CAT => {
      1 => "Cannot open chunk file chunk_file, terminating...\n"
        . "  file = __1__",

      3 => "Unable to open gzip source file, terminating...\n"
        . "  file = __1__",

      4 => "Unable to open plain source file, terminating...\n"
        . "  file = __1__",

      5 => "Incorrect size specification, terminating...\n" . "  size = __1__",

      6 => "Incorrect chunker_index specification, terminating...\n"
        . "  chunker_index = __1__",

      7 => "Directory does not exist, terminating...\n" . "  directory = __1__",

      8 => "Cannot shred Xml data, terminating...\n"
        . "  directory   = __1__\n"
        . "  source_file = __2__\n"
        . "  errMsg      = __3__",

      9 => "No file column order, terminating...\n" . "  type = __1__",

      10 => "No line separator provided, terminating...",

      11 => "No source file to copy to chunk_file, exiting..."
        . "  chunk_file = __1__",

      12 => "Unable to copy source file to chunk_file, exiting..."
        . "  source_file = __1__\n"
        . "  chunk_file  = __2__",

    },

    &INDEX_CAT => {
      1 => "Index not defined, terminating...\n" . "  operation = __1__",

      2 => "Tie failed, terminating...\n"
        . "  operation   = __1__\n"
        . "  child_error = __2__\n"
        . "  errno       = __3__",

      3 => "Unable to open gzip source file, terminating...\n"
        . "  file = __1__",

      4 => "Unable to open plain source file, terminating...\n"
        . "  file = __1__",

      5 => "Undefined index, terminating...",

      6 => "Accession is not mapped, terminating...\n" . "  accession = __1__",

      7 => "Uncompressing file temporarily to read index, terminating...\n"
        . "  source_file = __1__\n"
        . "  cmd         = __2__",

      8 =>
        "Remove temporary uncompressed file for reading index, terminating...\n"
        . "  source_file = __1__",

      9 => "Not expected index, terminating...\n"
        . "  actual index   = __1__\n"
        . "  expected index = __2__",

    },

    &FASTA_CAT => {
          1 => "Invalid Tag and/or type, terminating...\n"
        . "  defline type = __1__\n"
        . "  type         = __2__\n"
        . "  tag          = __3__",

      2 => "Invalid type for defline format, terminating...\n"
        . "  defline type = __1__\n"
        . "  type         = __2__\n"
        . "  tag          = __3__",

    },

    &STRUCTBCP_CAT => {
          1 => "Invalidate class type, exiting...\n"
        . "  expected = __1__\n"
        . "  actual   = __2__",

    },

    &STRUCTEXCEL_CAT => {
          1 => "Invalidate class type, exiting...\n"
        . "  expected = __1__\n"
        . "  actual   = __2__",

    },

    &HLA_CAT => {

      1 => "HLA Locus Name is not defined for taxon\n"
        . "  locus_name = __1__\n"
        . "  taxon_id   = __2__",

      2 => "File type incorrect or did not find locus names\n"
        . "  file type          = __1__\n"
        . "  file type checked  = __2__\n"
        . "  header val         = __3__\n"
        . "  header val checked = __4__",

      3 => "Filename is not tab-separated (ie, suffix '.txt')\n"
        . "  source = __1__\n"
        . "  file   = __2__",

      4 => "Error opening tab-separated file to write data\n"
        . "  source = __1__\n"
        . "  file   = __2__",

      5 => "Unknown file type\n" . "  file type = __1__",

      6 => "The class of the file reader is not consistent with this class\n"
        . "  this class type        = __1__\n"
        . "  file reader class type = __2__",

      7 => "File reader does not contain data for the row number ID\n"
        . "  row number ID = __1__",

      8 =>
        "The id of the row in the file reader is not the same as this class\n"
        . "  this row ID        = __1__\n"
        . "  file reader row ID = __2__\n",

      9 =>
        "The type of the class is not the same as the type of the file reader\n"
        . "  this file type        = __1__\n"
        . "  file reader file type = __2__",

    },

    &HLACONVERTER_CAT => {

      1 => "The source hla reader not of the correct class type (file::Hla)\n"
        . "  source reader type = __1__",

      2 => "Destination hla file type is neither HLA Typing Template\n"
        . "nor Pypop\n"
        . "  dest_type = __1__",

      3 => "Filename is not tab-separated (ie, suffix '.txt')\n"
        . "  source = __1__\n"
        . "  file   = __2__",

      4 => "Error opening tab-separated file to write data\n"
        . "  source = __1__\n"
        . "  file   = __2__",

      5 => "Column Pair Does not have the same locus\n"
        . "  col_1   = __1__\n"
        . "  locus_1 = __2__\n"
        . "  col_2   = __3__\n"
        . "  locus_2 = __4__",

    },

  };
  ###
  ### Now add the util::ErrMsgs categories
  ###
  my $utilMsgs = util::ErrMsgs::ERROR_MSGS;
  while ( my ( $category, $msgs ) = each %{$utilMsgs} ) {
    $errMsgs->{$category} = $msgs;
  }
  return $errMsgs;
}

sub ERROR_CATS {
  my $errCats = {
    &STRUCT_CAT       => 'file::Struct',
    &STRUCTASN_CAT    => 'file::Struct::Asn',
    &CHUNK_CAT        => 'file::Chunk',
    &INDEX_CAT        => 'file::Index',
    &FASTA_CAT        => 'file::Index::Fasta',
    &HLA_CAT          => 'file::Hla',
    &HLACONVERTER_CAT => 'file::HlaConverter',
    &STRUCTBCP_CAT    => 'file::Struct::Bcp',
    &STRUCTEXCEL_CAT  => 'file::Struct::Excel',

  };
  ###
  ### Now add the util::ErrMsgs categories
  ###
  my $utilCats = util::ErrMsgs::ERROR_CATS;
  while ( my ( $category, $name ) = each %{$utilCats} ) {
    $errCats->{$category} = $name;
  }
  return $errCats;
}

################################################################################

1;

__END__

=head1 NAME

ErrorMsg.pm

=head1 SYNOPSIS

   use file::ErrMsgs;
   $errMsgs = file::ErrMsgs::ERROR_MSGS

=head1 DESCRIPTION

This static class exports one the error messages for this library
which includes those for L<util::ErrMsgs>.

=head1 CONSTANT CLASS METHODS

The following constants define the error message categories:

   file::ErrMsgs::STRUCT_CAT       -- ( -1001000) Struct Class
   file::ErrMsgs::STRUCTASN_CAT    -- ( -1002000) Struct Asn Class
   file::ErrMsgs::CHUNK_CAT        -- ( -1003000) Chunk Class
   file::ErrMsgs::INDEX_CAT        -- ( -1004000) Index Class
   file::ErrMsgs::FASTA_CAT        -- ( -1005000) Fasta Class
   file::ErrMsgs::STRUCTBCP_CAT    -- ( -1006000) Struct Bcp Class
   file::ErrMsgs::STRUCTEXCEL_CAT  -- ( -1007000) Struct Excel Class
   file::ErrMsgs::HLA_CAT          -- ( -1008000) Hla Class
   file::ErrMsgs::HLACONVERTER_CAT -- ( -1009000) HLA File Converter Class

=head1 STATIC CLASS METHODS

=head2 B<ncbi::ErrMsgs::ERROR_MSGS>

This method returns a data-structure acceptable to the class
L<util::ErrMsg> method B<addErrorMsgs> that deploys error messages to
error categories and numbers.  It includes the error categories and
messages in L<util::ErrMsgs>.

=head2 B<ncbi::ErrMsgs::ERROR_CATS>

This method returns a data-structure acceptable to the class
L<util::ErrMsg> method B<addErrorCats> that deploys that deploys
category names for statistics reporting.  It includes the error
category names in L<util::ErrMsgs>.

=cut
