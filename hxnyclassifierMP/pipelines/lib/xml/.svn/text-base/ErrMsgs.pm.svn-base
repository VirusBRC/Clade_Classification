package xml::ErrMsgs;
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
sub ERROR_HEADER { return 'XML-ERROR: '; }

sub PARSER_CAT { return -1000000000; }    ### XML Perl Parser

################################################################################
#
#			     Public Static Constant
#
################################################################################

sub ERROR_MSGS {

  my $errMsgs = {

    &PARSER_CAT => {

      3 =>
"getProperty:  Unknown property name for tag in File (writeback error)\n"
        . "  tag           = __1__\n"
        . "  property name = __2__",

      4 => "getDate:  GBW date format is incorrect in File\n"
        . "  tag           = __1__\n"
        . "  property name = __2__\n"
        . "  date value    = __3__\n"
        . "  errMsg        = __4__",

      5 => "getBoolean:  Undefined Boolean value in File\n"
        . "  tag           = __1__\n"
        . "  property name = __2__",

      6 => "Force Attribute Hash:\n"
        . "Attempt to add simple leaf structure to nested structure\n"
        . "  name        = __1__\n"
        . "  key         = __2__\n"
        . "  force_tag   = __3__\n"
        . "  force_key   = __4__\n"
        . "  force_value = __5__",

      7 => "Force Element Hash:\n"
        . "Key value is not Simple\n"
        . "  name        = __1__\n"
        . "  force_tag   = __2__\n"
        . "  force_key   = __3__\n"
        . "  force_value = __4__",

      8 => "Name Reference must be an ARRAY or HASH\n"
        . "  name = __1__\n"
        . "  ref  = __2__",

      9 => "Current Object is NOT a Hash\n"
        . "  name  = __1__\n"
        . "  ref   = __2__",

      10 => "Force as an Array Undefined For Simple Value\n"
        . "  name      = __1__\n"
        . "  text-node = __2__",

      11 => "Force as an Array Undefined For Simple Value\n"
        . "  name      = __1__\n"
        . "  text-node = __2__",

      12 => "Cannot open xml file\n" . "  file = __1__",

      13 => "Unknown Force Hash Type\n" . "  force_type = __1__",

      14 => "Cannot Parse File\n"
        . "  source_file = __1__\n"
        . "  errMsg      = __2__",

      15 => "getSubObject:  Path expression error\n"
        . "  path expr   = __1__\n"
        . "  comp        = __2__\n"
        . "  object type = __3__",

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

    &PARSER_CAT => 'xml::Parser',
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

ErrMsgs.pm

=head1 SYNOPSIS

   use xml::ErrMsgs;

   my $error_msgs  = xml::ErrMsgs::ERROR_MSGS;
   my $error_names = xml::ErrMsgs::ERROR_CATS;

=head1 DESCRIPTION

This static class returns the error message templates for the util library.

=head1 CONSTANTS

The following constants define the pre-defined error message
categories define by this class.

   xml::ErrMsgs::PARSER_CAT -- ( -10000000001) XML Perl Parser

=head1 STATIC CLASS METHODS

=head2 B<xml::ErrMsgs::ERROR_MSGS>

This method returns a data-structure acceptable to the class
L<util::ErrMsg> method B<addErrorMsgs> that deploys error messages to
error categories and numbers.

=head2 B<xml::ErrMsgs::ERROR_CATS>

This method returns a data-structure acceptable to the class
L<util::ErrMsg> method B<addErrorCats> that deploys that deploys
category names for statistics reporting.

=cut

