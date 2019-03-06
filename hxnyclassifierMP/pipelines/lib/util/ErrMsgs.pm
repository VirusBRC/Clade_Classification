package util::ErrMsgs;
################################################################################
#
#				Required Modules
#
################################################################################

use strict;

use Pod::Usage;

################################################################################
#
#			     Constant Class Methods
#
################################################################################

sub CAT_MAP { return 'CATEGORY_MAP'; }

sub PROG_CAT         { return -1000; }    ### Main Program Script
sub RANDOM_CAT       { return -2000; }    ### Random Class
sub TOOLS_CAT        { return -3000; }    ### Tools Class
sub STATS_CAT        { return -4000; }    ### Statistics Class
sub JSON_CAT         { return -5000; }    ### JSon Class
sub TABLEDATA_CAT    { return -6000; }    ### Table Data Class
sub CONFIGPARAMS_CAT { return -7000; }    ### ConfigParams Class

################################################################################
#
#			     Public Static Constant
#
################################################################################

sub ERROR_MSGS {
  return {

    &PROG_CAT => {

      1 => "Unable to perform operation on file, terminating...\n"
        . "  operation = __1__\n"
        . "  file_type = __2__\n"
        . "  file      = __3__\n"
        . "  errMsg    = __4__",

      3 => "Output directory is not a directory, terminating...\n"
        . "  output directory = __1__",

      4 => "Cannot create output directory, terminating...\n"
        . "  output directory = __1__\n"
        . "  ErrMsg           = __2__",

      5 => "Output Directory does not exist, terminating...\n"
        . "  output directory = __1__",

      10 => "Missing property value, exiting...\n"
        . "  property_file = __1__\n"
        . "  property      = __2__",

      102 => "Missing data\n" . "  error_msg = __1__",

    },

    &RANDOM_CAT => {

      1 => "Undefined population provided, exiting...",

      2 => "Invalid sample_size provided, exiting...\n"
        . "  sample_size = __1__",

      3 => "Cannot access file to read population, exiting...\n"
        . "  file = __1__",

      4 => "Cannot open file to read population, exiting...\n"
        . "  file = __1__",

      5 => "Cannot open file to write population, exiting...\n"
        . "  file = __1__",

    },

    &TOOLS_CAT => {

      1 => "Cannot add error messages and categories for class\n"
        . "  class  = __1__\n"
        . "  errMsg = __2__",

      2 => "Cannot Find __3__:\n"
        . "  name = __1__\n"
        . "  lib  = __2__\n"
        . "  type = __3__\n"
        . "  item = __4__",

      3 => "Missing property\n"
        . "  loading type  = __1__\n"
        . "  loaded        = __2__\n"
        . "  property      = __3__",

      4 => "Cannot set execution focus\n" . "  executionDir = __1__",

      5 => "Error executing tool\n" . "  msg = __1__\n" . "  cmd = __2__",

      6 => "Unknown status\n" . "  status = __1__",

      7 => "Unable to open status file for writing\n" . "  status file = __1__",

      8 => "Unable to open status file for reading\n" . "  status file = __1__",

      9 => "Cannot evaluate string\n"
        . "   eval_status = __1__\n"
        . "   eval_str    =\n__2__",

      10 => "Datum is not set\n" . " datum type = __1__",

      11 => "Datum is not constant\n"
        . "   datum type = __1__\n"
        . "   old datum  = __2__\n"
        . "   new datum  = __3__",

      12 => "Unknown tool name\n" . "  tool name = __1__",

      13 => "Unknown pipeline type\n" . "  pipeline type = __1__",

      14 => "Cannot Perl evaluate property\n"
        . "   property    = __1__\n"
        . "   value       = __2__\n"
        . "   data_type   = __3__\n"
        . "   eval_status = __4__",
      ###
      ### For feature variation tools
      ###
      101 => "MHC File Type unknown\n" . "  mhcFileType = __1__",

      102 => "MHC Reader Type unknown\n" . "  mhcReaderType = __1__",

      103 => "MHC Object Type unknown\n" . "  objectType = __1__",

      104 =>
"Unknown file type (not tab-separated, '.txt', nor Excel spreadsheet '.xls')\n"
        . "  file = __1__",

      105 => "Cannot open and write to file type file\n"
        . "  file type file = __1__",

      106 => "Cannot determine HLA file type for file\n" . "  file = __1__",

      108 =>
        "Cannot open '.txt' file to determine if line separator is ctrl-M\n"
        . "  file = __1__",

    },

    &STATS_CAT => {

      1 => "Cannot Instantiate Statistics since there is no (tag, list) data",

      2 => "Cannot Instantiate Statistics since tags and lists do NOT pair",

      3 => "Not a valid tag list (ie, referenced array)\n" . "  tag = __1__",

      4 => "Tag keys not paired in increment",

      5 => "Cannot find tag in increment\n" . "  tag = __1__",

      6 => "Cannot find (tag, key)-pair for item in increment\n"
        . "  tag = __1__\n"
        . "  key = __2__",

      7 => "Cannot find tag in increment key\n" . "  tag = __1__",

    },

    &JSON_CAT => {
          1 => "Unable to Convert Json to Perl\n"
        . "  errMsg = __1__\n"
        . "  str    = __2__",

    },

    &TABLEDATA_CAT => {
          1 => "Cannot read __3__ file content\n"
        . "  infix  = __1__\n"
        . "  file   = __2__",

      2 => "Cannot write file raw\n"
        . "  table_type = __1__\n"
        . "  file       = __2__",

      3 => "Cannot read file raw\n"
        . "  table_type = __1__\n"
        . "  file       = __2__",

    },

    &CONFIGPARAMS_CAT => {
      1 => "Cannot Load Config Params File\n" . "  file = __1__",

      2 => "Cannot deserialize Config Params\n" . "  file = __1__",

      3 => "Cannot remove file before storing Config Params\n"
        . "  file = __1__",

      4 => "Cannot read module for Config Params\n"
        . "  module  = __1__\n"
        . "  errMsg  = __2__\n"
        . "  refType = __3__",

    },

  };
}

sub ERROR_CATS {
  return {

    &PROG_CAT         => 'Main Program',
    &RANDOM_CAT       => 'util::Random',
    &TABLEDATA_CAT    => 'util::TableData',
    &TOOLS_CAT        => 'util::Tools',
    &STATS_CAT        => 'util::Statistics',
    &JSON_CAT         => 'util::JSon',
    &CONFIGPARAMS_CAT => 'util::ConfigParams',
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

This static class returns the error message templates for the util library.

=head1 CONSTANTS

The following constants define the pre-defined error message
categories define by this class.

   util::ErrMsgs::PROG_CAT         -- ( -1000) Main Program Script
   util::ErrMsgs::RANDOM_CAT       -- ( -2000) Random Class
   util::ErrMsgs::TOOLS_CAT        -- ( -3000) Tools Class
   util::ErrMsgs::STATS_CAT        -- ( -4000) Statistics Class
   util::ErrMsgs::JSON_CAT         -- ( -5000) JSon Class
   util::ErrMsgs::TABLEDATA_CAT    -- ( -6000) Table Data Class
   util::ErrMsgs::CONFIGPARAMS_CAT -- ( -7000) ConfigParams Class

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

