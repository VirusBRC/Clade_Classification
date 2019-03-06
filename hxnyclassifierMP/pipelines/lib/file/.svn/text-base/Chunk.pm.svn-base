package file::Chunk;
################################################################################
#
#				Required Modules
#
################################################################################

use strict;

use FileHandle;
use Pod::Usage;

use util::Cmd;
use util::Constants;
use util::PathSpecifics;

use file::ErrMsgs;

use xml::Types;

use fields qw (
  chunk_index
  chunk_prefix
  cmds
  directory
  error_mgr
  file_index
  file_kind
  file_type
  files
  lines
  line_separator
  previous_line_separator
  size
  source_fh
  source_file
  serializer
);

################################################################################
#
#				   Constants
#
################################################################################
###
### Size for all file as a single chunk
###
sub ALL_FILE { return '_ALL_'; }
###
### Error Category
###
sub ERR_CAT { return file::ErrMsgs::CHUNK_CAT; }

################################################################################
#
#				 Public Methods
#
################################################################################

sub new {
  my file::Chunk $this = shift;
  my ( $file_type, $size, $directory, $error_mgr ) = @_;
  $this = fields::new($this) unless ref($this);

  $this->{chunk_index}             = 1;
  $this->{chunk_prefix}            = util::Constants::EMPTY_STR;
  $this->{cmds}                    = new util::Cmd($error_mgr);
  $this->{directory}               = getPath($directory);
  $this->{error_mgr}               = $error_mgr;
  $this->{file_index}              = {};
  $this->{file_type}               = $file_type;
  $this->{files}                   = [];
  $this->{line_separator}          = util::Constants::NEWLINE;
  $this->{lines}                   = [];
  $this->{previous_line_separator} = util::Constants::NEWLINE;
  $this->{size}                    = $size;
  $this->{source_fh}               = new FileHandle;
  $this->{source_file}             = undef;
  $this->{serializer}              = undef;

  return $this;
}

sub chunkFile {
  my file::Chunk $this = shift;
  #######################
  ### Abstract Method ###
  #######################
  $this->{error_mgr}->printDebug("Abstract Method file::Chunk::chunkFile");
}

################################################################################
#
#				 Setter Methods
#
################################################################################

sub setSerializer {
  my file::Chunk $this = shift;
  my ($serializer) = @_;
  $this->{serializer} = $serializer;
}

sub setSize {
  my file::Chunk $this = shift;
  my ($size) = @_;
  $this->{error_mgr}->exitProgram( ERR_CAT, 5, [$size],
         util::Constants::EMPTY_LINE($size)
      || ( $size !~ /^\d+$/ && $size ne ALL_FILE )
      || ( $size =~ /^\d+$/ && $size == 0 ) );
  $this->{size} = $size;
}

sub setChunkPrefix {
  my file::Chunk $this = shift;
  my ($chunk_prefix) = @_;
  return if ( !defined($chunk_prefix) );
  $this->{chunk_prefix} = $chunk_prefix;
}

sub setChunkIndex {
  my file::Chunk $this = shift;
  my ($chunk_index) = @_;
  $this->{error_mgr}->exitProgram( ERR_CAT, 6, [$chunk_index],
    !defined($chunk_index) || $chunk_index !~ /^\d+$/ || $chunk_index == 0 );
  $this->{chunk_index} = $chunk_index;
}

sub setLineSeparator {
  my file::Chunk $this = shift;
  my ($line_separator) = @_;
  $this->{error_mgr}->exitProgram( ERR_CAT, 10, [], !defined($line_separator) );
  $this->{line_separator} = $line_separator;
}

sub setSourceFile {
  my file::Chunk $this = shift;
  my ($file) = @_;
  ###############################
  ### Re-implementable Method ###
  ###############################
  $this->{source_file} = getPath($file);
  $this->{file_kind}   = undef;
  if ( $this->{source_file} =~ /(\.gz|\.Z)$/ ) {
    $this->{file_kind} = xml::Types::GZIP_FILE_TYPE;
  }
  elsif ( $this->{source_file} =~ /(\.zip)$/ ) {
    $this->{file_kind} = xml::Types::ZIP_FILE_TYPE;
  }
  else {
    $this->{file_kind} = xml::Types::PLAIN_FILE_TYPE;
  }
  ###
  ### Open the file is the size is not all the file
  ###
  return if ( $this->{size} eq ALL_FILE );
  if ( $/ ne $this->{line_separator} ) {
    $this->{previous_line_separator} = $/;
    $/ = $this->{line_separator};
  }
  if ( $this->{file_kind} eq xml::Types::GZIP_FILE_TYPE ) {
    $this->{error_mgr}->exitProgram(
      ERR_CAT, 3,
      [ $this->{source_file} ],
      !$this->{source_fh}->open( 'gunzip -c ' . $this->{source_file} . '|' )
    );
  }
  elsif ( $this->{file_kind} eq xml::Types::ZIP_FILE_TYPE ) {
    $this->{error_mgr}->exitProgram( ERR_CAT, 3, [ $this->{source_file} ],
      !$this->{source_fh}
        ->open( 'cat ' . $this->{source_file} . ' | gunzip -c |' ) );
  }
  else {
    $this->{error_mgr}->exitProgram(
      ERR_CAT, 4,
      [ $this->{source_file} ],
      !$this->{source_fh}->open( $this->{source_file}, '<' )
    );
  }
}

sub closeSourceFile($) {
  my file::Chunk $this = shift;
  ###############################
  ### Re-implementable Method ###
  ###############################
  return if ( !defined( $this->{source_fh}->fileno ) );
  $this->{source_fh}->close;
  return if ( $/ eq $this->{previous_line_separator} );
  $/ = $this->{previous_line_separator};
  $this->{previous_line_separator} = util::Constants::NEWLINE;
}

sub writeChunk {
  my file::Chunk $this = shift;
  return if ( $this->{size} ne ALL_FILE
    && @{ $this->{lines} } == 0 );
  $this->{error_mgr}->exitProgram(
    ERR_CAT, 7,
    [ $this->{directory} ],
    !-e $this->{directory} || !-d $this->{directory}
  );
  my $chunk_index = $this->{chunk_index};
  if    ( $chunk_index < 10 )   { $chunk_index = '000' . $chunk_index; }
  elsif ( $chunk_index < 100 )  { $chunk_index = '00' . $chunk_index; }
  elsif ( $chunk_index < 1000 ) { $chunk_index = '0' . $chunk_index; }
  $this->{chunk_index}++;
  my $chunk_file = join( util::Constants::SLASH,
    $this->{directory},
    join( util::Constants::DOT,
      $this->{chunk_prefix}, $chunk_index, $this->{file_type}, 'gz'
    )
  );
  push( @{ $this->{files} }, $chunk_file );
  $this->{file_index}->{$chunk_file} = $chunk_index;

  if ( $this->{size} eq ALL_FILE ) {
    my $source_file = $this->{source_file};
    ###
    ### Chunk is the whole file
    ###
    $this->{error_mgr}->exitProgram( ERR_CAT, 11, [$chunk_file],
      util::Constants::EMPTY_LINE($source_file) );
    my $cmd = undef;
    if ( $this->{file_kind} eq xml::Types::GZIP_FILE_TYPE
      || $this->{file_kind} eq xml::Types::ZIP_FILE_TYPE )
    {
      $cmd = join( util::Constants::SPACE, 'cp', $source_file, $chunk_file );
    }
    else {
      $cmd = join( util::Constants::SPACE,
        'gzip -c ', $source_file, '>', $chunk_file );
    }
    $this->{error_mgr}->exitProgram(
      ERR_CAT, 12,
      [ $source_file, $chunk_file ],
      $this->{cmds}->executeCommand(
        {
          source => $source_file,
          target => $chunk_file
        },
        $cmd,
        'Copying file...'
      )
    );
  }
  else {
    ###
    ### Chunk is the part of a file
    ###
    my $fh = new FileHandle;
    $this->{error_mgr}->exitProgram( ERR_CAT, 1, [$chunk_file],
      !$fh->open("| gzip -c > $chunk_file") );
    $fh->autoflush(util::Constants::TRUE);
    my $last_index = $#{ $this->{lines} };
    foreach my $index ( 0 .. ( $last_index - 1 ) ) {
      $fh->print( $this->{lines}->[$index] . $this->{line_separator} );
    }
    $fh->print( $this->{lines}->[$last_index] );
    $fh->close;
  }
  $this->{lines} = [];
}

################################################################################
#
#				 Getter Methods
#
################################################################################

sub chunkFiles {
  my file::Chunk $this = shift;
  return @{ $this->{files} };
}

sub chunkFileIndex {
  my file::Chunk $this = shift;
  my ($chunk_file) = @_;
  return $this->{file_index}->{$chunk_file};
}

sub serializer {
  my file::Chunk $this = shift;
  return $this->{serializer};
}

################################################################################

1;

__END__

=head1 NAME

Chunk.pm

=head1 SYNOPSIS

This abstract class provides the mechanism to chunk an input source
into smaller chunks for processing.

=head1 METHODS

The following methods are exported from the class.

=head2 B<new file::Chunk(chunk_prefix, file_type, size, directory, error_mgr)>

This is the constructor of the class and requires the B<chunk_prefix>
that defines the tag for the data and the B<file_type> that defines
file type.  Also, the directory is the directory where the chunks is
assumed to be writtern.  The size is the default size of the chunks.
Size can be changed by L<"setSize(buffer_size)">.

=head2 B<chunkFile>

This abstract method takes the stream represented by the source_file
(file, database, etc.) and chunks it into size (as defined by the
subclass) chunks making sure integral entity boundaries are not
violated.  Each chunk will be generated into a gzipped filename, where
N is the chunk number (N >= 0), B<directory>, B<chunk_prefix>, and
B<file_type> are the attributes of the object:

  <directory>/[prefix.]<chunk_prefix>.000N.<file_type>.gz,         N < 10
  <directory>/[prefix.]<chunk_prefix>.00N.<file_type>.gz,  10   <= N < 100
  <directory>/[prefix.]<chunk_prefix>.0N.<file_type>.gz,   100  <= N < 1000
  <directory>/[prefix.]<chunk_prefix>.N.<file_type>.gz,    1000 <= N < 10000

This method returns the number of chunks created.  The optional
B<prefix> can be added by a subclass.

=head1 SETTER METHODS

The following setter methods are exported from the class.

=head2 B<setSize(buffer_size)>

This method set the buffer size to buffer_size if it is defined and
positive.

=head2 B<setChunkPrefix(chunk_prefix)>

This method sets the chunk prefix for the chunked files.  Initially,
this prefix is set to the empty string.

=head2 B<setChunkIndex(chunk_index)>

This method sets the chunk file index to start with for the chunked
files.  This number must be positive.  By default, it is set to one
(1).

=head2 B<setLineSeparator(line_separator)>

This method sets the line separator.  By default, the line separator
is new line.

=head2 B<setSourceFile(file)>

This re-implementable method sets the source file and opens the input
stream for this source file.  It manages whether the file is gzipped
or plain.

=head2 B<setSerializer(serializer)>

This optional setter method sets the Perl serializer.

=head2 B<closeSourceFile>

This re-implementable method closes the the source file handle.

=head2 B<writeChunk>

If there are lines in the lines array attribute, then the method
writes the lines to the next chunk file.

=head1 GETTER METHODS

The following getter methods are exported from the class.

=head2 B<chunkFiles>

This method returns the (unreferenced) list of chunk files generated
by L<"chunkFile">.

=head2 B<chunkFileIndex(chunk_file)>

This method returns the index for the chunk_file.  If the chunk_file
is not a chunk, then undef is returned.

=head2 B<serializer>

This optional serializer.

=cut
