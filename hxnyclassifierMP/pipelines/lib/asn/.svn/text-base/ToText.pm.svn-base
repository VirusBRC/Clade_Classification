package asn::ToText;
################################################################################
#
#				Required Modules
#
################################################################################

use strict;

use File::Basename;
use FileHandle;
use Pod::Usage;

use util::Constants;
use util::PathSpecifics;

use asn::ErrMsgs;

use base 'asn::Parser';

use fields qw (
  index
  print_fh
);

################################################################################
#
#				   Constants
#
################################################################################
###
### Error Category
###
sub ERR_CAT { return asn::ErrMsgs::TOTEXT_CAT; }

################################################################################
#
#			     Private Methods
#
################################################################################

sub _printFile {
  my asn::ToText $this = shift;
  $this->{index}++;
  return getPath(
    join( util::Constants::DOT, basename( $this->file ), $this->{index} ) );
}

sub _printOpen {
  my asn::ToText $this = shift;
  return ( defined( $this->{print_fh}->fileno ) )
    ? util::Constants::TRUE
    : util::Constants::FALSE;
}

################################################################################
#
#				 Public Methods
#
################################################################################

sub new {
  my ( $that, $asn_tag, $source_file, $error_mgr ) = @_;
  my asn::ToText $this = $that->SUPER::new( $asn_tag, $error_mgr );

  $this->{index}    = 0;
  $this->{print_fh} = new FileHandle;

  $this->setFile($source_file);

  return $this;
}

sub setPrint {
  my asn::ToText $this = shift;
  $this->{print_fh}->close if ( $this->_printOpen );
  my $print_file = $this->_printFile;
  $this->{error_mgr}->exitProgram( ERR_CAT, 1, [$print_file],
    !$this->{print_fh}->open( $print_file, '>' ) );
  $this->{print_fh}->autoflush(util::Constants::TRUE);
}

sub processFile {
  my asn::ToText $this = shift;
  my $local_count = 0;
  $this->setBufferSize(10000000);
  my @entities = $this->readEntities;
  while ( @entities > 0 ) {
    foreach my $entity (@entities) {
      if ( $this->_printOpen ) { $this->{print_fh}->print( $entity->showStr ); }
      else                     { $entity->show( $this->_printFile ); }
    }
    @entities = $this->readEntities;
  }
  $this->{print_fh}->close if ( $this->_printOpen );
  return $this->parsedEntities;
}

################################################################################

1;

__END__

=head1 NAME

AsnToText.pm

=head1 SYNOPSIS

This concrete class is a subclass of L<asn::Parser>implements the ASN1 
parser that generates parsed text files in L<asn::Entity> format.

=head1 METHODS

The following methods are exported from the class.

=head2 B<new asn::ToText(asn_tag, source_file, error_mgr)>

This is the constructor for this class.  It sets the top-level ASN1
tag asn_tag and opens the source_file and initializes the parse.

=head2 B<setPrint>

This method opens a single output stream for all entities to be
written. If the current output stream is open, this method closes that
current stream and opens a new one.  The name of the file is:

   <execution_focus>/basename(source_file).index

where index starts at one (1) and incremented each time this method is
called.

=head2 B<processFile>

This method prints the ASN entities out to a file.  If setPrint has
been executed then, each entity is written to a single file, otherwise
each entity is written to a separate file of the format:

   <execution_focus>/basename(source_file).index

where index is incremented by one for each file and starts at one.

=cut
