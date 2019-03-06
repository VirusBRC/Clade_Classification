package file::Struct::Bcp::Spaces;
################################################################################
#
#				Required Modules
#
################################################################################

use strict;

use Pod::Usage;

use file::Chunk::Bcp::Spaces;

use base 'file::Struct::Bcp';

################################################################################
#
#				 Object Methods
#
################################################################################
###
### Constructor Method
###
sub new {
  my ( $that, $file, $list_types, $error_mgr ) = @_;
  my file::Struct::Bcp::Spaces $this =
    $that->SUPER::new( $file, $list_types, $error_mgr );

  return $this;
}

sub setChunker {
  my file::Struct::Bcp::Spaces $this = shift;
  ###
  ### Create the Perl Generator
  ###
  $this->{chunker} =
    new file::Chunk::Bcp::Spaces( undef, $this->getFileOrder,
    $this->{error_mgr} );
}

################################################################################

1;

__END__

=head1 NAME

Spaces.pm

=head1 DESCRIPTION

This abstract class for spaces-separated bcp-files is a subclass of
L<file::Struct::Bcp> and implements this super class's abstract method
B<setChunker>. This class is abstract since it does not define the
abstract methods B<setFileOrder> that is used to set the column
definitions, nor does it implement the abstract method B<computeLists>
that is used in B<readFile>.

=head1 METHODS

The following methods are defined for this class.

=head2 B<new file::Struct::Bcp::Spaces(file, list_types, error_mgr)>

This method is the constructor for the spaces-separated file reader
class.  The result of reading the file is an array of referenced
hashes for each line with the keys defined by L<"setFileOrder">.  and
a set of lists described in L<file::Struct>.  This object is a
B<HASH> Perl object.  The B<list_types> is a referenced array, mapping
the component lists to the the entity types.  The error_mgr is an
instance of the L<util::ErrMgr> class and is required for registering
errors.

=head1 SETTER METHODS

The following setter methods are defined for this class.

=head2 B<setChunker>

This concrete method instantiates the spaces chunker for this class and
uses the file_order attribute to determine the file order for the
spaces-separated file.

=cut
