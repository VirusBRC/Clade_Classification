package db::Types;
################################################################################
#
#				Required Modules
#
################################################################################

use strict;

use Pod::Usage;

use util::Constants;
use util::ErrMsgs;

################################################################################
#
#			     Static Class Constants
#
################################################################################
###
### Bcp File Reader Types
###
sub LINE_TYPE  { return 'file::Chunk::Bcp::LineProps'; }
sub MULTI_TYPE { return 'file::Chunk::Bcp::MultiProps'; }
sub TAB_TYPE   { return 'file::Chunk::Bcp::Tab'; }
###
### Bcp File Seperator
###
sub _FIELD_SEPARATORS_ {
  return {
    &LINE_TYPE  => '~,~',
    &MULTI_TYPE => '~,~',
    &TAB_TYPE   => util::Constants::TAB,
  };
}

sub _RECORD_SEPARATORS_ {
  return {
    &LINE_TYPE  => util::Constants::NEWLINE,
    &MULTI_TYPE => '~.~',
    &TAB_TYPE   => util::Constants::NEWLINE,
  };
}
###
### Error Category
###
sub ERR_CAT { return util::ErrMsgs::PROG_CAT; }

################################################################################
#
#				Public Methods
#
################################################################################

sub isBcpFileType {
  my ($file_type) = @_;
  return ( $file_type eq LINE_TYPE
      || $file_type eq MULTI_TYPE
      || $file_type eq TAB_TYPE )
    ? util::Constants::TRUE
    : util::Constants::FALSE;
}

sub fieldSeparator {
  my ($file_type) = @_;
  return undef if ( !isBcpFileType($file_type) );
  my $fields = _FIELD_SEPARATORS_;
  return $fields->{$file_type};
}

sub recordSeparator {
  my ($file_type) = @_;
  return undef if ( !isBcpFileType($file_type) );
  my $records = _RECORD_SEPARATORS_;
  return $records->{$file_type};
}

################################################################################

1;

__END__

=head1 NAME

Types.pm

=head1 DESCRIPTION

The static class defines the basic file-types for loading and dumping
database tables and other database-related operations.

=head1 CONSTANTS

The following static constants representing the bcp-file types are
exported from this class

   db::Types::LINE_TYPE  -- file::Chunk::Bcp::LineProps
   db::Types::MULTI_TYPE -- file::Chunk::Bcp::MultiProps
   db::Types::TAB_TYPE   -- file::Chunk::Bcp::Tab

=head1 METHODS

The following static methods are exported by this class.

=head2 B<db::Types::isBcpFileType(file_type)>

The method returns TRUE (1) if the file_type is a valid bcp file type,
otherwise it returns FALSE (0).  Currently, valid types include:

   LINE_TYPE  -- file::Chunk::Bcp::LineProps
   MULTI_TYPE -- file::Chunk::Bcp::MultiProps
   TAB_TYPE   -- file::Chunk::Bcp::Tab

=head2 B<db::Types::fieldSeparator(file_type)>

This method returns the field separator for a given bcp file type.  If
it is not known, then B<undef> is returned.


=head2 B<db::Types::recordSeparator(file_type)>

This method returns the record separator for a given bcp file type.
If it is not known, then B<undef> is returned.

=cut
