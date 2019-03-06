package asn::ErrMsgs;
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
sub ERROR_HEADER { return 'ASN-ERROR: '; }

sub ENTITY_CAT { return -11000; }    ### Entity Class
sub PARSER_CAT { return -12000; }    ### Parser Class
sub TOTEXT_CAT { return -13000; }    ### ToText Class

################################################################################
#
#			     Public Static Constant
#
################################################################################

sub ERROR_MSGS {
  my $errMsgs = {

    &ENTITY_CAT => {
      1 => "Cannot open file to print entity, terminating...\n"
        . "  file = __1__",
    },

    &PARSER_CAT => {

      1 => "Undefined entity tag, terminating...\n" . "  entity_tag = __1__",

      2 => "Un-open file handle to read, terminating...",

      3 => "Undefined file to read, terminating...\n" . "  file = __1__",

      4 => "Cannot open file to read, terminating...\n"
        . "  file      = __1__\n"
        . "  file type = __2__",

    },

    &TOTEXT_CAT => {
      1 => "Cannot open file, terminating...\n" . "  file = __1__",

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
    &ENTITY_CAT => 'asn::Entity',
    &PARSER_CAT => 'asn::Parser',
    &TOTEXT_CAT => 'asn::ToText',
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

   use asn::ErrMsgs;
   $errMsgs = asn::ErrMsgs::ERROR_MSGS

=head1 DESCRIPTION

This static class exports one the error messages for this library
which includes those for L<util::ErrMsgs>.

=head1 CONSTANT CLASS METHODS

The following constants define the error message categories:

   asn::ErrMsgs::ENTITY_CAT  -- ( 10000) Entity Class
   asn::ErrMsgs::PARSER_CAT  -- ( 20000) Parser Class
   asn::ErrMsgs::PARSER_CAT  -- ( 30000) ToText Class

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
