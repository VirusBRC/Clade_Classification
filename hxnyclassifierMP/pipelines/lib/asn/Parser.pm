package asn::Parser;
################################################################################
#
#				Required Modules
#
################################################################################

use strict;

use FileHandle;
use Pod::Usage;

use util::Constants;
use util::PathSpecifics;

use asn::Entity;
use asn::ErrMsgs;
use asn::ParseState;

use xml::Types;

use fields qw (
  brace_level
  buffer_size
  check_braces
  entity_tag
  error_mgr
  fh
  file
  last_line
  lines
  parsed_entities
);

################################################################################
#
#				   Constants
#
################################################################################
###
### Buffer Size
###
sub LOCAL_BUF_SIZE { return 1000000; }
###
### Error Category
###
sub ERR_CAT { return asn::ErrMsgs::PARSER_CAT; }

################################################################################
#
#			     Private Methods
#
################################################################################

sub _trackBraceLevel {
  my asn::Parser $this = shift;
  my ($line) = @_;
  return if ( !$this->{check_braces} );
  foreach my $index ( 0 .. ( length($line) - 1 ) ) {
    my $char = substr( $line, $index, 1 );
    if ( $char eq asn::ParseState::TAG_OPEN ) {
      $this->{brace_level}++;
    }
    elsif ( $char eq asn::ParseState::TAG_CLOSE ) {
      $this->{brace_level}--;
    }
  }
}

sub _getNextRecordFromStream {
  my asn::Parser $this = shift;
  $this->{brace_level} = 0;
  $this->{lines}       = [];
  my $buffer     = util::Constants::EMPTY_STR;
  my $entity_tag = $this->{entity_tag};
  ###
  ### Either use the last line or get the first (skip whitespace)
  ###
  if ( $this->{last_line} ne util::Constants::EMPTY_STR ) {
    $this->_trackBraceLevel( $this->{last_line} );
    push( @{ $this->{lines} }, $this->{last_line} );
    $this->{last_line} = util::Constants::EMPTY_STR;
  }
  else {
    while ( $this->{fh}->read( $buffer, $this->{buffer_size} ) ) {
      if ( $buffer =~ /$entity_tag/ ) {
        ###
        ### Remove the data prior to the start tag
        ### and use the rest
        ###
        my $col = $-[0];
        $buffer = substr( $buffer, $col );
        $this->_trackBraceLevel($buffer);
        push( @{ $this->{lines} }, $buffer );
        last;
      }
    }
  }
  ###
  ### Get more data until have gotten at least one
  ### complete entity
  ###
  while ( $this->{fh}->read( $buffer, $this->{buffer_size} ) ) {
    if ( $buffer =~ /$entity_tag/ ) {
      my $col = $-[0];
      $this->{last_line} = substr( $buffer, $col );
      if ( $col - 1 >= 0 ) {
        $buffer = substr( $buffer, 0, $col );
        push( @{ $this->{lines} }, $buffer );
        $this->_trackBraceLevel($buffer);
      }
      last;
    }
    push( @{ $this->{lines} }, $buffer );
    $this->_trackBraceLevel($buffer);
    last if ( $this->{brace_level} == 0 );
  }
  if ( @{ $this->{lines} } > 0 && $this->{brace_level} != 0 ) {
    my $last_lines = util::Constants::EMPTY_STR;
    foreach my $index ( ( $#{ $this->{lines} } - 2 ) .. $#{ $this->{lines} } ) {
      $last_lines .= $this->{lines}->[$index];
    }
    $this->{error_mgr}
      ->printWarning( "{} mismatch: \n" . $last_lines, util::Constants::TRUE );
  }
  return ( @{ $this->{lines} } > 0 );
}

sub _divideIntoEntities {
  my asn::Parser $this = shift;
  my $entity_tag       = $this->{entity_tag};
  my $entities         = [];
  my $current_entity   = undef;
  foreach my $line ( @{ $this->{lines} } ) {
    while ( $line =~ /^(.|\n)+?($entity_tag)/ ) {
      my $col = $-[2];
      my $entity_line = substr( $line, 0, $col );
      $line = substr( $line, $col );
      if ( !defined($current_entity) ) {
        $current_entity = [];
        push( @{$entities}, $current_entity );
      }
      push( @{$current_entity}, $entity_line );
      $current_entity = undef;
    }
    if ( length($line) > 0 ) {
      if ( !defined($current_entity) ) {
        $current_entity = [];
        push( @{$entities}, $current_entity );
      }
      push( @{$current_entity}, $line );
    }
  }
  return $entities;
}

sub _parseAsn {
  my asn::Parser $this = shift;
  my ( $parseState, $struct ) = @_;
  while ( $parseState->nextToken ) {
    my $token = $parseState->getToken;
    if ( $token eq asn::ParseState::TAG_OPEN ) {
      my $last_child = $struct->getLastChild;
      $this->_parseAsn( $parseState, $last_child );
    }
    elsif ( $token eq asn::ParseState::TAG_CLOSE ) {
      last;
    }
    elsif ( $token eq asn::ParseState::TAG_COMMA ) {
      $struct->setChild( new asn::Entity( $this->{error_mgr} ) );
    }
    else {
      my $last_child = $struct->getLastChild;
      if ( $last_child->getTag eq util::Constants::EMPTY_STR ) {
        if ( $token =~ /^".*"$/ ) {
          $last_child->setValue($token);
        }
        else {
          $last_child->setTag($token);
        }
      }
      else {
        if ( $last_child->getValue ne util::Constants::EMPTY_STR ) {
          $last_child->setTag( $last_child->getTag
              . util::Constants::SPACE
              . $last_child->getValue );
        }
        $last_child->setValue($token);
      }
    }
  }
  return util::Constants::TRUE;
}

sub _parseEntity {
  my asn::Parser $this = shift;
  my ( $entities, $entity_lines ) = @_;
  my $parseState =
    new asn::ParseState( $entity_lines, 0, 0, $this->{error_mgr} );
  my $parsed_lines = util::Constants::FALSE;
  my $entity       = new asn::Entity( $this->{error_mgr} );
  my $count        = 0;
  while ( $parseState->nextToken ) {
    my $token = $parseState->getToken;
    $count++;
    last if ( $token eq asn::ParseState::TAG_OPEN );
    if   ( $count == 1 ) { $entity->setTag($token); }
    else                 { $entity->setValue($token); }
  }
  $parsed_lines = $this->_parseAsn( $parseState, $entity );
  my @attr_keys     = keys %{ $entity->getAttrs };
  my $parsed_entity = (
    $parsed_lines && ( defined( $entity->getValue )
      || @attr_keys > 0
      || @{ $entity->getChildren } > 0 )
  );
  if ($parsed_entity) {
    $entity->generatePaths;
    push( @{$entities}, $entity );
  }
  return $parsed_entity;
}

################################################################################
#
#				 Public Methods
#
################################################################################

sub new {
  my asn::Parser $this = shift;
  my ( $entity_tag, $error_mgr ) = @_;
  $this = fields::new($this) unless ref($this);
  $error_mgr->exitProgram( ERR_CAT, 1, [],
    util::Constants::EMPTY_LINE($entity_tag) );

  $this->{brace_level}     = undef;
  $this->{buffer_size}     = LOCAL_BUF_SIZE;
  $this->{check_braces}    = util::Constants::FALSE;
  $this->{entity_tag}      = $entity_tag;
  $this->{error_mgr}       = $error_mgr;
  $this->{fh}              = undef;
  $this->{file}            = undef;
  $this->{last_line}       = undef;
  $this->{lines}           = undef;
  $this->{parsed_entities} = util::Constants::FALSE;

  return $this;
}

sub setBufferSize {
  my asn::Parser $this = shift;
  my ($buffer_size) = @_;
  return if ( !defined($buffer_size) );
  $buffer_size = int($buffer_size);
  return if ( $buffer_size <= 0 );
  $this->{buffer_size} = $buffer_size;
}

sub setBraceLevelCheck {
  my asn::Parser $this = shift;
  my ($check_braces) = @_;
  $this->{check_braces} =
    ( defined($check_braces) && $check_braces )
    ? util::Constants::TRUE
    : util::Constants::FALSE;
}

sub initializeParse {
  my asn::Parser $this = shift;
  my ($fh) = @_;
  $this->{error_mgr}->exitProgram( ERR_CAT, 2, [],
    !defined($fh) || !ref($fh) || !defined( $fh->fileno ) );
  $this->{fh}              = $fh;
  $this->{last_line}       = util::Constants::EMPTY_STR;
  $this->{parsed_entities} = util::Constants::FALSE;
}

sub setFile {
  my asn::Parser $this = shift;
  my ($file) = @_;
  $this->{error_mgr}->exitProgram( ERR_CAT, 3, [],
    !defined($file) || $file eq util::Constants::EMPTY_STR );
  $this->{file} = getPath($file);
  ###
  ### Open the file
  ###
  my $file_type = undef;
  my $fh        = new FileHandle;
  if ( $this->{file} =~ /(\.gz|\.Z)$/ ) {
    $file_type = xml::Types::GZIP_FILE_TYPE;
  }
  else {
    $file_type = xml::Types::PLAIN_FILE_TYPE;
  }
  if ( $file_type eq xml::Types::GZIP_FILE_TYPE ) {
    $this->{error_mgr}->exitProgram(
      ERR_CAT, 4,
      [ $file, 'gzip' ],
      !$fh->open( 'gunzip -c ' . $this->{file} . '|' )
    );
  }
  else {
    $this->{error_mgr}->exitProgram(
      ERR_CAT, 4,
      [ $file, 'plain' ],
      !$fh->open( $this->{file}, '<' )
    );
  }
  $this->initializeParse($fh);
}

sub readEntities {
  my asn::Parser $this = shift;
  my $entities = [];
  return @{$entities} if ( !$this->_getNextRecordFromStream );
  foreach my $entity_lines ( @{ $this->_divideIntoEntities } ) {
    $this->{parsed_entities} =
      ( $this->_parseEntity( $entities, $entity_lines ) )
      ? util::Constants::TRUE
      : $this->{parsed_entities};
  }
  return @{$entities};
}

sub parsedEntities {
  my asn::Parser $this = shift;
  return $this->{parsed_entities};
}

sub parseEntity {
  my asn::Parser $this = shift;
  my ($entity_str)     = @_;
  my $entities         = [];
  my $entity_lines = [ split( /\n/, $entity_str ) ];
  return undef if ( !$this->_parseEntity( $entities, $entity_lines ) );
  return $entities->[0];
}

sub file {
  my asn::Parser $this = shift;
  return $this->{file};
}

sub fh {
  my asn::Parser $this = shift;
  return $this->{fh};
}

################################################################################

1;

__END__

=head1 NAME

AsnParser.pm

=head1 SYNOPSIS

This concrete class is the standard Perl ASN1 parser that generates a
path expression based structure for each entity in an ASN1 file.  Each
entity is represented hierarchically and recusively using the entity
class L<asn::Entity>.  This class uses the lexical analyzer
L<asn::ParseState> to generate tokens from the source stream.

=head1 METHODS

The following methods are exported from the class.

=head2 B<new asn::Parser(entity_tag, $error_mgr)>

This is the constructor of the class and requires the entity_tag that
defines the top-level tag for an ASN1 entity.  The constructor set the
stream buffer size to 1 Mbytes.

=head1 SETTER METHODS

The following setter methods are exported from the class.

=head2 B<setBufferSize(buffer_size)>

This method set the buffer size to buffer_size if it is defined and
positive.

=head2 B<setBraceLevelCheck(check_braces)>

This method sets whether brace-level matching is checked on reading
buffers.  By default, brace-levels are NOT checked.  If check_braces
is TRUE (1), the braces will be checked, otherwise they will not be
checked.

=head2 B<initializeParse(fh)>

This method sets the current file stream B<fh> and checks that it is
open.  Also, it initializes parser including setting parsed entities
to FALSE (0).

=head2 B<setFile(file)>

This method initializes the parser to the B<file>.  That is, the
object a file stream for the file and initializes the parser using the
method L<"initializeParse(fh)">.

=head1 GETTER METHODS

The following getter methods are exported from the class.

=head2 B<@entities = readEntities>

This method reads the next block of ASN1 entities in the file stream
and returns them as a list.  The parser reads block of buffer_size
data at a time until it has read at least one complete entity.  If no
entities have been read, then an empty list is returned.  This method
assumes either of the following methods have been called prior to this
method: L<"initializeParse(fh)"> or L<"setFile(file)">.

=head2 B<parsedEntities>

This method returns TRUE (1) if at least one entity has been parsed
before the call to this method, otherwise it returns FALSE (0).  This
method assumes that the method B<readEntities> has been called.

=head2 B<$entity = parseEntity(entity_str)>

This method parses an entity from the B<entity_str> and returns it.
This method does B<NOT> use either of the following methods:
L<"initializeParse(fh)"> or L<"setFile(file)">.

=head2 B<fh>

This method returns the current file handle (if it has been set).

=head2 B<file>

This method returns the current file (if it has been set).

=cut
