package file::Chunk::Asn;
################################################################################
#
#				Required Modules
#
################################################################################

use strict;

use Pod::Usage;

use util::Constants;

use base 'file::Chunk';

use fields qw (
  entity_tag
  last_line
);

################################################################################
#
#				   Constants
#
################################################################################
###
### File Type
###
sub FILE_TYPE { return 'asn'; }
###
### Buffer Size
###
sub LOCAL_BUF_SIZE { return 100000000; }

################################################################################
#
#			     Private Methods
#
################################################################################

sub _getNextChunkFromStream {
  my file::Chunk::Asn $this = shift;
  $this->{lines} = [];
  my $buffer     = util::Constants::EMPTY_STR;
  my $entity_tag = $this->{entity_tag};
  ###
  ### Either use the last line or get the first (skip whitespace)
  ###
  if ( $this->{last_line} ne util::Constants::EMPTY_STR ) {
    push( @{ $this->{lines} }, $this->{last_line} );
    $this->{last_line} = util::Constants::EMPTY_STR;
  }
  else {
    while ( $this->{source_fh}->read( $buffer, $this->{size} ) ) {
      if ( $buffer =~ /$entity_tag/ ) {
        ###
        ### Remove the data prior to the start tag
        ### and use the rest
        ###
        my $col = $-[0];
        $buffer = substr( $buffer, $col );
        push( @{ $this->{lines} }, $buffer );
        last;
      }
    }
  }
  ###
  ### Get more data until have gotten at least one
  ### complete entity
  ###
  while ( $this->{source_fh}->read( $buffer, $this->{size} ) ) {
    if ( $buffer =~ /$entity_tag/ ) {
      my $col = $-[0];
      $this->{last_line} = substr( $buffer, $col );
      if ( $col - 1 >= 0 ) {
        $buffer = substr( $buffer, 0, $col );
        push( @{ $this->{lines} }, $buffer );
      }
      last;
    }
    push( @{ $this->{lines} }, $buffer );
  }
  return ( @{ $this->{lines} } > 0 );
}

################################################################################
#
#				 Public Methods
#
################################################################################

sub new {
  my ( $that, $entity_tag, $directory, $error_mgr ) = @_;
  my file::Chunk::Asn $this =
    $that->SUPER::new( FILE_TYPE, LOCAL_BUF_SIZE, $directory, $error_mgr );

  $this->{entity_tag} = $entity_tag;
  $this->{last_line}  = undef;

  $this->setLineSeparator(util::Constants::EMPTY_STR);

  return $this;
}

sub chunkFile {
  my file::Chunk::Asn $this = shift;
  $this->{file_index} = {};
  $this->{files}      = [];
  $this->{last_line}  = util::Constants::EMPTY_STR;
  my $initial_chunk_index = $this->{chunk_index};
  if ( $this->{size} eq $this->ALL_FILE ) {
    $this->writeChunk;
  }
  else {
    while ( $this->_getNextChunkFromStream ) {
      push( @{ $this->{lines} }, util::Constants::NEWLINE );
      $this->writeChunk;
    }
    $this->closeSourceFile;
  }
  return ( $this->{chunk_index} - $initial_chunk_index );
}

################################################################################

1;

__END__

=head1 NAME

Asn.pm

=head1 SYNOPSIS

This concrete class provides the mechanism to chunk an ASN1 file into
smaller chunks for processing and is subclass of L<file::Chunk>.

=head1 METHODS

The following methods are exported from the class.

=head2 B<new file::Chunk::Asn(entity_tag, directory, error_mgr)>

This is the constructor of the class and requires the entity_tag that
defines the top-level tag for the ASN1 data.  Also, the directory
where the chunks will be generated.  The constructor set the stream
buffer size to 100 Mbytes.

=head2 B<chunkFile>

This method takes the stream represented by the file handle, fh and
chunks it into buffer_size chunks making sure that ASN1 top-level
entity boundaries are not violated.  Each chunk will be generated into
a gzipped filename, where N is the chunk number (N >= 0) and
B<directory> and B<chunk_prefix> are the attributes of the object:

  <directory>/<chunk_prefix>.000N.asn.gz,         N < 10
  <directory>/<chunk_prefix>.00N.asn.gz,  10   <= N < 100
  <directory>/<chunk_prefix>.0N.asn.gz,   100  <= N < 1000
  <directory>/<chunk_prefix>.N.asn.gz,    1000 <= N < 10000

This method returns the number of chunks created.

=cut
