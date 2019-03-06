package parallel::ErrMsgs;
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

sub ERROR_HEADER { return 'PARALLEL-ERROR: '; }

sub JOBS_CAT       { return 10000; }    ### Jobs Class
sub COMPONENT_CAT  { return 11000; }    ### Component Class
sub UTILS_CAT      { return 12000; }    ### Types Class
sub LOCK_CAT       { return 13000; }    ### Lock Class
sub QUERY_CAT      { return 14000; }    ### Query Class


################################################################################
#
#			     Public Static Constant
#
################################################################################

sub ERROR_MSGS {
  my $errMsgs = {

    &JOBS_CAT => {

      1 => "Terminating run, terminate forked process\n" . "  pid = __1__",

      2 => "Terminating controller since component failed\n"
        . "  component type = __1__",

      3 => "Failed to fork process on retry\n" . "  cmd = __1__",

      4 => "Failed to fork process\n" . "  cmd = __1__",

    },

    &UTILS_CAT => {

      1 => "Missing standard property\n"
        . "  entity type = __1__\n"
        . "  property    = __2__",

      2 => "Missing entity type property\n"
        . "  entity type = __1__\n"
        . "  property    = __2__",

      3 => "Terminating since unable to create component\n"
        . "  class  = __1__\n"
        . "  errMsg = __2__",

      4 => "Terminating since unable to create tool\n"
        . "  class  = __1__\n"
        . "  errMsg = __2__",

      5 => "Cannot open file\n"
        . "  operation = __1__\n"
        . "  file      = __2__\n"
        . "  msg       = __3__",

    },

    &COMPONENT_CAT => {
          1 => "Unable to open file\n"
        . "  file_type = __1__\n"
        . "  file      = __2__",

      2 => "Unable to read file\n"
        . "  file_type = __1__\n"
        . "  file      = __2__",

      3 => "Unable to launch component\n"
        . "  component_type = __1__\n"
        . "  subtype        = __2__",

      4 => "Unable to store data output files\n"
        . "  component_type = __1__\n"
        . "  output_files   = __2__\n"
        . "  output_file    = __3__",

      5 => "Unable to to obtain lock for data output files\n"
        . "  component_type = __1__\n"
        . "  output_files   = __2__\n"
        . "  output_file    = __3__\n"
        . "  lock_file      = __4__\n",

      6 => "Unable to to remove lock for data output files\n"
        . "  component_type = __1__\n"
        . "  output_files   = __2__\n"
        . "  output_file    = __3__\n"
        . "  lock_file      = __4__\n",

      7 => "Unable to read data output files\n"
        . "  component_type = __1__\n"
        . "  output_files   = __2__",

      8 => "Unable to find Directory\n"
        . "  dir_type = __1__\n"
        . "  dir      = __2__",

      9 => "Unable to find PDB ID in file\n" . "  file = __1__",

      10 => "Cannot find bl2seq blast tool",

      11 => "Cannot untar file\n" . "  file = __1__\n" . "  dir  = __2__",

      12 => "Cannot execute query\n" . "  query = __1__",

    },

    &LOCK_CAT => {
      1 => "Locking directory does not exist\n" . "  lock directory = __1__",

      2 => "Unable to unlock the lock file\n"
        . "  lock_directory = __1__\n"
        . "  lock_file      = __2__",

    },

    &QUERY_CAT => {
      1 => "Unable to open values file\n" . "  file = __1__",

      2 => "Values file for parameter has no values\n"
        . "  param = __1__\n"
        . "  file  = __2__",

      3 => "Parameter substitution is not a non-empty filename or array\n"
        . "  param = __1__",

      4 => "Unable to execute query since multiple substitutions max elements\n"
        . "  max elements = __1__\n"
        . "  param 1      = __2__\n"
        . "  param 2      = __3__",

      5 => "Parameter substitutiion data type unknown\n"
        . "  param     = __1__\n"
        . "  data_type = __2__",

      6 => "Parameter in parameter order does not have a value\n"
        . "  param = __1__",

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

    &COMPONENT_CAT  => 'parallel::Component',
    &JOBS_CAT       => 'parallel::Jobs',
    &LOCK_CAT       => 'parallel::Lock',
    &UTILS_CAT      => 'parallel::Utils',
    &QUERY_CAT      => 'parallel::Query',
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

   parallel::ErrMsgs::JOBS_CAT        -- ( 10000) Jobs Class
   parallel::ErrMsgs::COMPONENT_CAT   -- ( 11000) Component Class
   parallel::ErrMsgs::UTILS_CAT       -- ( 12000) Utils Class
   parallel::ErrMsgs::LOCK_CAT        -- ( 13000) Lock Class
   parallel::ErrMsgs::QUERY_CAT       -- ( 14000) Query Class

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

