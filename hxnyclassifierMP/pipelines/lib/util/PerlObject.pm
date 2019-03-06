package util::PerlObject;
################################################################################
#
#				Required Modules
#
################################################################################

use strict;

use Fcntl;
use FileHandle;
use Pod::Usage;

use util::Constants;
use util::Msg;

use fields qw(
  file
  mode
  msg
  io
  io_open
);

################################################################################
#
#				Initializations
#
################################################################################

BEGIN {

  use vars qw($VERSION);

  my $rev = '$Revision: 2.26 $';
  ###
  ### '$'
  ### The comment above fixes a syntax highlighting bug in XEmacs.
  ###
  if ( $rev =~ /((\d|\.)+)/ ) {
    $util::PerlObject::VERSION = $1;
  }
}

################################################################################
#
#				   Constants
#
################################################################################
###
### Perl ref Structure Types
###
sub ARRAY_TYPE { return 'ARRAY'; }
sub CODE_TYPE  { return 'CODE'; }
sub HASH_TYPE  { return 'HASH'; }
###
### A comment line indicating the end of a Perl Object
###
sub PERL_OBJECT_LIMIT { return '# End of Object'; }
###
### Perl Syntax Tokens for Perl Object Generation
###
sub CLOSE_ARRAY { return ']'; }
sub CLOSE_HASH  { return '}'; }
sub COMMENT     { return ' # '; }
sub INDENTION   { return '  '; }
sub IS_ASSIGNED { return ' => '; }
sub OPEN_ARRAY  { return '['; }
sub OPEN_HASH   { return '{'; }
###
### Options for generating serialized Perl Objects
###
sub KEEP  { return 0x1 }
sub FLUSH { return 0x2; }
sub QUOTE { return 0x4; }
sub CLASS { return 0x8; }
###
### Standard options for writing Perl objects
###
sub PERL_OBJECT_WRITE_OPTIONS { return ( KEEP | QUOTE ); }

################################################################################
#
#			     Private Static Methods
#
################################################################################

sub _READ_HANDLE_  { return util::Constants::TRUE; }
sub _WRITE_HANDLE_ { return util::Constants::FALSE; }

sub _makePerl {
  my ( $object, $option, $indention ) = @_;
  my ( $str, $key );
  my $ref               = ref($object);
  my $array_type        = ARRAY_TYPE;
  my $hash_type         = HASH_TYPE;
  my $current_indention = $indention;
  if ( !( $option & FLUSH ) ) { $indention .= INDENTION; }
  if ( $ref && $ref eq HASH_TYPE ) {    ###$object =~ /$hash_type/ ) {
    $str = OPEN_HASH;
    if ( $option & CLASS ) { $str .= COMMENT . $ref; }
    $str .= util::Constants::NEWLINE;
    foreach $key ( sort keys %{$object} ) {
      $str .=
          $indention 
        . "'$key'"
        . IS_ASSIGNED
        . _makePerl( $object->{$key}, $option, $indention )
        . util::Constants::COMMA
        . util::Constants::NEWLINE;
    }
    $str .= $current_indention . CLOSE_HASH;
  }
  elsif ( $ref && $ref eq ARRAY_TYPE ) {    ###$object =~ /$array_type/ ) {
    $str = OPEN_ARRAY;
    if ( $option & CLASS ) { $str .= COMMENT . $ref; }
    $str .= util::Constants::NEWLINE;
    foreach $key ( @{$object} ) {
      $str .=
          $indention
        . _makePerl( $key, $option, $indention )
        . util::Constants::COMMA
        . util::Constants::NEWLINE;
    }
    $str .= $current_indention . CLOSE_ARRAY;
  }
  elsif ($ref) {
    $str = $ref;
  }
  elsif ( defined($object) ) {
    ###
    ### If NOT QUOTE, then only thing NOT to quote are
    ### numeric values (but may fail on '09' (month-like) numbers).
    ###
    ### If QUOTE, then everything is quoted regardless.
    ###
    if ( !( $option & QUOTE )
      && $object =~ /^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/ )
    {
      $str = $object;
    }
    else {
      ###
      ### If not KEEP spaces, strip initial and terminal spaces,
      ### otherwise keep these spaces
      ###
      if ( !( $option & KEEP ) ) {
        $object =~ s/^\s+//;
        $object =~ s/\s+$//;
      }
      ###
      ### protect $ and @ and " and \
      ###
      $object =~ s/\\/\\\\/g;
      $object =~ s/\$/\\\$/g;
      $object =~ s/@/\\@/g;
      $object =~ s/"/\\"/g;

      $str = '"' . $object . '"';
    }
  }
  else {
    $str = 'undef';
  }
  return $str;
}

################################################################################
#
#				Private Methods
#
################################################################################

sub _serializePerl {
  my util::PerlObject $this = shift;
  my ( $object, $option ) = @_;
  ###
  ### If no option is specified, then at a minimum use CLASS
  ###
  if ( !defined($option) ) { $option = CLASS; }
  return _makePerl( $object, $option, util::Constants::EMPTY_STR );
}

sub _deserializePerl {
  my util::PerlObject $this = shift;
  my ( $str, $msg ) = @_;
  my $object = eval "return $str";
  my $status = $@;
  $this->{msg}->dieOnError(
    "Deserialization Error:\n" . "  msg    = $msg\n" . "  errMsg = $status",
    defined($status) && $status );
  return $object;
}

sub _ioHandle {
  my util::PerlObject $this = shift;
  my ($read) = @_;
  return $this->{io} if ( $this->{io_open} );
  my $io = new FileHandle;
  ###
  ### Default read  = STDIN
  ### Default write = STDOUT
  ###
  if ($read) {
    $io->open('-');
  }
  else {
    $io->open('>-');
    $io->autoflush(util::Constants::TRUE);
  }
  return $io;
}

################################################################################
#
#				    Methods
#
################################################################################

sub new {
  my util::PerlObject $this = shift;
  my ( $file, $mode, $msg ) = @_;
  $this = fields::new($this) unless ref($this);
  if ( !defined($msg) || !ref($msg) ) { $msg = new util::Msg; }
  $this->{file}    = $file;
  $this->{mode}    = $mode;
  $this->{msg}     = $msg;
  $this->{io_open} = util::Constants::FALSE;
  $this->{io}      = new FileHandle;

  if ( !defined( $this->{mode} ) ) { $this->{mode} = O_RDWR | O_CREAT; }

  if ( defined( $this->{file} )
    && $this->{file} ne util::Constants::EMPTY_STR )
  {
    my $operation;
    if ( $this->{mode} == O_RDONLY ) {
      $operation = '<';
    }
    elsif ( -e $file ) {
      $operation = '+<';
    }
    else {
      $operation = '>';
    }
    $this->{msg}->dieOnError(
      "Unable to open file\n"
        . "  file = "
        . $this->{file} . "\n"
        . "  errMsg = $!",
      !$this->{io}->open( $file, $operation )
    );
    $this->{io_open} = util::Constants::TRUE;
    if ( $operation eq '+<' || $operation eq '>' ) {
      $this->{io}->autoflush(util::Constants::TRUE);
    }
  }
  return $this;
}

sub endOfIo {
  my util::PerlObject $this = shift;
  return $this->{io}->eof if ( $this->{io_open} );
  return util::Constants::TRUE;
}

sub closeIo {
  my util::PerlObject $this = shift;
  return if ( !$this->{io_open} );
  $this->{io}->close;
  $this->{io_open} = util::Constants::FALSE;
}

sub readStream {
  my util::PerlObject $this = shift;
  my $perl_object_limit     = PERL_OBJECT_LIMIT;
  my $str                   = util::Constants::EMPTY_STR;
  my $io                    = $this->_ioHandle(_READ_HANDLE_);
  while ( !$io->eof ) {
    my $line = $io->getline;
    if ( $line =~ /^$perl_object_limit/ ) {
      return $this->_deserializePerl( $str,
        "Found Perl Object Limit '$perl_object_limit'" );
    }
    $str .= $line;
  }
  return $this->_deserializePerl( $str, 'End of input stream' );
}

sub readAsObject {
  my util::PerlObject $this = shift;
  my $perl_object_limit     = PERL_OBJECT_LIMIT;
  my $io                    = $this->_ioHandle(_READ_HANDLE_);
  if ( !$io->eof ) {
    my @lines = $io->getlines;
    if ( $lines[$#lines] =~ /^$perl_object_limit/ ) { pop(@lines); }
    return $this->_deserializePerl( join( util::Constants::EMPTY_STR, @lines ),
      "Found Perl Object" );
  }
  return undef;
}

sub readBlock {
  my util::PerlObject $this = shift;
  my ( $start, $len ) = @_;
  return undef if ( !$this->{io_open} );
  my $io = $this->_ioHandle(_READ_HANDLE_);
  my $seek_status = $io->seek( $start, 0 );
  $this->{msg}->dieOnError( "Error on seek to $start", !$seek_status );
  my $str;
  my $read_status = $io->read( $str, $len );
  $this->{msg}->dieOnError( "Error on read", !defined($read_status) );
  return $this->_deserializePerl( $str,
    "Read block (start, length) = ($start, $len)" );
}

sub writeStream {
  my util::PerlObject $this = shift;
  my ( $object, $option ) = @_;
  my $io    = $this->_ioHandle(_WRITE_HANDLE_);
  my $start = $io->tell;
  $io->print( $this->_serializePerl( $object, $option ) );
  $io->print( "\n" . PERL_OBJECT_LIMIT . "\n" );
  return ( $start, $io->tell - $start );
}

sub position {
  my util::PerlObject $this = shift;
  my $io = $this->_ioHandle(_WRITE_HANDLE_);
  return $io->tell;
}

sub deserializeObject {
  my util::PerlObject $this = shift;
  my ( $str, $msg ) = @_;
  return $this->_deserializePerl( $str, "Perl Object ($msg)" );
}

sub serializeObject {
  my util::PerlObject $this = shift;
  my ( $object, $option ) = @_;
  return $this->_serializePerl( $object, $option );
}

sub DESTROY {
  my util::PerlObject $this = shift;
  if ( $this->{io_open} ) { $this->{io}->close; }
}

################################################################################

1;

__END__

=head1 NAME

util::PerlObject

=head1 SYNOPSIS

   use util::PerlObject;

   -- Read perl object from a an existing file
   $objfile = new util::PerlObject($file);
   $object = $objfile->readStream;
   $object = $objfile->readBlock($start, $length);

   OR

   -- Read a single perl object from a an existing file
   $objfile = new util::PerlObject($file, O_RDONLY);
   $object = $objfile->readAsObject;
   $objfile->closeIo;

   OR

   -- Write perl object to file (exist--append, not exist--create)
   $objfile = new util::PerlObject($file);
   ($start, $len) = $objfile->writeStream($object);

   OR

   -- Read perl object from and Write perl object to an existing file
   $objfile = new util::PerlObject($file);
   $object = $objfile->readStream;
   $object = $objfile->readBlock($start, $length);
   ($start, $len) = $objfile->writeStream($object);

   OR

   -- Read from standard input
   $objfile = new util::PerlObject;
   $object = $objfile->readStream;

   OR

   -- Write perl object to standard output
   $objfile = new util::PerlObject;
   ($start, $len) = $objfile->writeStream($object);

=head1 DESCRIPTION

This class creates objects that can serialize (writeStream) and
deserialize (readStream) Perl objects (variables).

=head1 CONSTANTS

The static constants exported by the class define the option in the
Write method.  These are bit codes that can be bit or'd (|) together
to obtain the desired serialization behavior.  The option are
described below.

=over 4

=item B<KEEP>

By default, the leading and terminal spaces in strings values are
stripped.  This flag will keep these spaces.

=item B<QUOTE>

By default, numeric values are not quoted.  Sometimes, this can
confuse the perl compiler on a read-back since a leading '0' may force
a number to be octal-based.  This flag forces all values to be quoted.

=item B<FLUSH>

By default, the nested structures are indented by 2 spaces ('  ') per
level.  This flag removes indention for a more space-efficient string.

=item B<CLASS>

This option allows referenced objects to have their class information
embedded in a comment in the Perl string structure (useful for
debugging).

=item B<PERL_OBJECT_WRITE_OPTIONS>

This is the standard write option (KEEP | QUOTE)

=back

=head1 METHODS

The following methods are provided.  These methods allow Perl objects
to be serialized and deserialized using files and file handles
including STDIN and STDOUT as defaults.

=head2 B<new util::PerlObject([file[, mode[, msg]])>

This method is the constructor for this class.  If a file is provided,
an IO stream is created for this file.  If the mode is O_RDONLY, then
then IO stream will be created as read only.  Otherwise the file
exists, then the IO stream will be created as read-write append, else
the IO stream is created as write only.  If the file is not provided,
then the IO stream is left undefined and by default STDIN or STDOUT
will be used for reading and writing, respectively.

=head2 B<writeStream(object[, option)]>

This method serializes (writes) the object in (standard) Perl syntax
to IO stream defined by constructor of the object.  The format looks
like:

	{ ... }
	# End of Object

If the IO stream is not defined, STDOUT is used.  After the object is
printed, '# End of Object' is appended on a separate line.  The
options are described in L<"CONSTANTS">.  The option parameter is
optional.  If omitted, then the CLASS option is th only option in
effect.

=head2 B<readStream>

This method returns a Perl object from the IO stream.  If IO stream is
not defined, this method uses STDIN by default..

=head2 B<readAsObject>

This method returns a Perl object from the remaining data in the IO
stream.  If IO stream is not defined, this method uses STDIN by
default.  This assumes that the remaining data is a single object with
the possibility of a terminating Perl comment.  This method is useful
when the file is a single object.

=head2 B<readBlock(start, length)>

This method returns a Perl object from the IO stream starting at
start, with length bytes.  If the IO stream is not defined, the method
returns undef.  If length is not defined, it will read to the end of
the stream.

=head2 B<position>

The method returns the current byte position of the IO stream defined
by objfile.  If the IO stream is not defined, then this method uses
STDOUT.

=head2 B<closeIo>

The method closes the IO stream it is opened.

=head2 B<endOfIo>

This method returns end of file status of IO stream if it is opened,
otherwise, it return TRUE(1).

=head2 B<deserializeObject(str, msg)>

This method returns the deserialized Perl object represented by the
string B<str> and B<msg> defines the error message.

=head2 B<serializeObject(object[, option])>

This method returns the serialized string for the object given the
option.

=cut
