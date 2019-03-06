package tool::ErrMsgs;
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

sub ERROR_HEADER { return 'TOOL-ERROR: '; }

sub AGGREGATOR_CAT { return 100000; }    ### Aggregator Tool Class
sub ORTHOLOG_CAT   { return 110000; }    ### Ortholog Tool Class
sub FOMASNP_CAT    { return 120000; }    ### fomaSNP Tool Class

################################################################################
#
#			     Public Static Constant
#
################################################################################

sub ERROR_MSGS {
  my $errMsgs = {

    &AGGREGATOR_CAT => {

      1 => "Aggregator unable to read duplicate file\n" . "  dup_file  = __1__",

      2 => "Aggregator unable to remove output file\n"
        . "  output_file  = __1__",

      3 => "Aggregator unable to open output file\n" . "  output_file  = __1__",

      4 => "Aggregator unable to process data file\n" . "  data_file  = __1__",

      5 => "Aggregator unable to get output files file\n"
        . "  output_files  = __1__",

      6 => "Aggregator unable to read family name file\n"
        . "  family_name_file  = __1__",

      7 => "Aggregator unable to read data file\n" . "  data_file = __1__",

      8 => "Aggregator unable to open output file for id\n"
        . "  id   = __1__\n"
        . "  file = __2__",

      9 => "Uknown output file type for id\n"
        . "  id        = __1__\n"
        . "  file_type = __2__",

      10 => "Aggregator unable to create entity\n"
        . "  type = __1__\n"
        . "  file = __2__",

      11 => "Aggregator unable to write to output file\n"
        . "  output_file  = __1__",

      12 => "Aggregator unable to copy file\n"
        . "  dir  = __1__\n"
        . "  file = __2__",

      13 => "Aggregator unable to append file\n"
        . "  append = __1__\n"
        . "  file   = __2__",

      14 => "Aggregator unable to tar gzip files\n"
        . "  dir  = __1__\n"
        . "  type = __2__",

      15 => "Aggregator unable to read output data file\n" . "  file = __1__",

      16 => "Aggregator unable to remove directory\n" . "  dir = __1__",

    },

    &ORTHOLOG_CAT => {

      1 => "Cannot __2__ sequence map\n"
        . "  type = __1__\n"
        . "  file = __3__",

    },

    &FOMASNP_CAT => {

      1 => "Cannot read file\n" . "  type = __1__\n" . "  file = __2__",

      2 => "Cannot operate on file\n"
        . "  mode   = __1__\n"
        . "  file   = __2__\n"
        . "  errMsg = __3__",

      3 => "Cannot convert fasta file into clustalw file\n"
        . "  fasta    = __1__\n"
        . "  clustalw = __2__",

      4 => "Cannot create new clw strain name file\n"
        . "  tmp  = __1__\n"
        . "  file = __2__",

      5 => "Cannot zip clw file\n" . "  file = __1__\n" . "  zip = __2__",

      6 => "Cumulative frequency exceeds one (1.0)\n" . "  frequency = __1__",

      7 => "Cannot generate RPlot\n"
        . "  input  = __1__\n"
        . "  output = __2__\n"
        . "  type   = __3__",

      8 => "Cannot backup clw file\n" . "  file = __1__\n" . "  bak  = __2__",

      9 => "Issue with fasta header will not generate SNP alignment",

      10 => "problem with consensus sequence\n" . "  acc = __1__",

      11 => "gap start in all sequences",

      12 => "Cannot remove file\n" . " file = __1__",

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
  return {

    &AGGREGATOR_CAT => 'tool::Aggregator',
    &FOMASNP_CAT    => 'tool::fomaSNP',
    &ORTHOLOG_CAT   => 'tool::ortholog',
  };
}

################################################################################

1;

__END__

=head1 NAME

ErrMsgs.pm

=head1 SYNOPSIS

   use util::ErrMsgs;

   my $error_msgs  = util::ErrMsgs::ERROR_MSGS;
   my $error_names = util::ErrMsgs::ERROR_CATS;

=head1 DESCRIPTION

This static class returns the error message templates for parallel library.

=head1 CONSTANTS

The following constants define the pre-defined error message
categories define by this class.

   tool::ErrMsgs::AGGREGATOR_CAT  -- ( 100000) Aggregator Class
   tool::ErrMsgs::ORTHOLOG_CAT    -- { 110000) Ortholog Tool Class
   tool::ErrMsgs::FOMASNP_CAT     -- { 120000) fomaSNP Tool Class

=head1 STATIC CLASS METHODS

=head2 B<util::ErrMsgs::ERROR_MSGS>

This method returns a data-structure acceptable to the class
L<util::ErrMsg> method B<addErrorMsgs> that deploys error messages to
error categories and numbers.

=head2 B<util::ErrMsgs::ERROR_CATS>

This method returns a data-structure acceptable to the class
L<util::ErrMsg> method B<addErrorCats> that deploys that deploys
category names for statistics reporting.

=cut

