package db::ErrMsgs;
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
sub ERROR_HEADER { return 'DB-ERROR: '; }

sub SCHEMA_CAT { return -101000; }    ### Schema Class

################################################################################
#
#			     Public Static Constant
#
################################################################################

sub ERROR_MSGS {
  my $errMsgs = {

    &SCHEMA_CAT =>
      { 1 => "Terminal Error, exiting....\n" . "  errMsg\n__1__", },

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
  my $errCats = { &SCHEMA_CAT => 'db::Schema', };
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

   use db::ErrMsgs;
   $errMsgs = db::ErrMsgs::ERROR_MSGS

=head1 DESCRIPTION

This static class exports one the error messages for this library
which includes those for L<util::ErrMsgs>.

=head1 CONSTANT CLASS METHODS

The following constants define the error message categories:

   db::ErrMsgs::SCHEMA_CAT -- ( -101000) Schema Class

=head1 STATIC CLASS METHODS

=head2 B<db::ErrMsgs::ERROR_MSGS>

This method returns a data-structure acceptable to the class
L<util::ErrMsg> method B<addErrorMsgs> that deploys error messages to
error categories and numbers.  It includes the error categories and
messages in L<util::ErrMsgs>.

=head2 B<db::ErrMsgs::ERROR_CATS>

This method returns a data-structure acceptable to the class
L<util::ErrMsg> method B<addErrorCats> that deploys that deploys
category names for statistics reporting.  It includes the error
category names in L<util::ErrMsgs>.

=cut
