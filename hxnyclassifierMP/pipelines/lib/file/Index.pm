package file::Index;
################################################################################
#
#				Required Modules
#
################################################################################

use strict;

use DB_File;
use FileHandle;
use File::Basename;
use Pod::Usage;

use util::Cmd;
use util::Constants;
use util::PathSpecifics;

use file::ErrMsgs;

use xml::Types;

use fields qw (
  accession_expr
  cmds
  entity_expr
  entity_search_expr
  error_mgr
  index
  line_separator
  previous_line_separator
  smap
  source_fh
  source_file
  uncompressed_file
);

################################################################################
#
#				   Constants
#
################################################################################
###
### Index File Name Key
###
sub INDEX_FILENAME { return '__FileName__'; }
###
### Writing Modes
### 1.  create
###       - create the file if it does not exist but do not truncate it if
###         it does exist
### 2.  read_write
###       - open for read/write but do not create if it does not exist or
###         do not truncate it if it does exist
### 3.  truncate
###       - create the file if it does not exist or truncate it if it does
###
sub CREATE_MODE     { return '__create__'; }
sub READ_WRITE_MODE { return '__read_write__' }
sub TRUNCATE_MODE   { return '__truncate__'; }
###
### Error Category
###
sub ERR_CAT { return file::ErrMsgs::INDEX_CAT; }

################################################################################
#
#				Private Methods
#
################################################################################

sub _getReadWriteMode($$) {
  my file::Index $this = shift;
  my ($mode) = @_;
  return ( O_RDWR | O_CREAT )           if ( $mode eq CREATE_MODE );
  return (O_RDWR)                       if ( $mode eq READ_WRITE_MODE );
  return ( O_RDWR | O_TRUNC | O_CREAT ) if ( $mode eq TRUNCATE_MODE );
  return undef;
}

sub _setupToWriteIndex($$) {
  my file::Index $this = shift;
  my ($mode) = @_;
  $this->{error_mgr}
    ->exitProgram( ERR_CAT, 1, ['write'], !defined( $this->{index} ) );
  my %smap;
  my $hashinfo = new DB_File::HASHINFO;
  $hashinfo->{bsize} = 8192;
  my $tie_status =
    tie( %smap, 'DB_File', $this->{index}, $this->_getReadWriteMode($mode),
    0666, $hashinfo );
  $this->{error_mgr}
    ->exitProgram( ERR_CAT, 2, [ 'write', $?, $! ], !$tie_status );
  undef $tie_status;
  $this->{smap} = \%smap;
}

sub _openSourceFileToIndex($) {
  my file::Index $this = shift;
  my $file_kind = undef;
  if ( $this->{source_file} =~ /(\.gz|\.Z)$/ ) {
    $file_kind = xml::Types::GZIP_FILE_TYPE;
  }
  else {
    $file_kind = xml::Types::PLAIN_FILE_TYPE;
  }
  if ( $/ ne util::Constants::NEWLINE ) {
    $this->{previous_line_separator} = $/;
    $/ = util::Constants::NEWLINE;
  }
  if ( $file_kind eq xml::Types::GZIP_FILE_TYPE ) {
    $this->{error_mgr}->exitProgram(
      ERR_CAT, 3,
      [ $this->{source_file} ],
      !$this->{source_fh}->open( 'gunzip -c ' . $this->{source_file} . '|' )
    );
  }
  else {
    $this->{error_mgr}->exitProgram(
      ERR_CAT, 4,
      [ $this->{source_file} ],
      !$this->{source_fh}->open( $this->{source_file}, '<' )
    );
  }
}

sub _openSourceFileToRead($) {
  my file::Index $this = shift;
  return if ( defined( $this->{source_fh}->fileno ) );
  my $smap = $this->{smap};
  my $file = $smap->{&INDEX_FILENAME};
  $smap = undef;
  $this->{source_file} =
    join( util::Constants::SLASH, dirname( $this->{index} ), $file );
  my $zipped_file_pattern = xml::Types::ZIPPED_FILE_PATTERN;
  my $source_file         = $this->{source_file};

  if ( $this->{source_file} =~ /$zipped_file_pattern/ ) {
    $source_file =~ s/$zipped_file_pattern//;
    if ( !defined( $this->{uncompressed_file} )
      || $this->{uncompressed_file} ne $source_file )
    {
      $this->{uncompressed_file} = $source_file;
      my $cmd =
          'gunzip -c '
        . $this->{source_file} . ' > '
        . $this->{uncompressed_file};
      $this->{error_mgr}->exitProgram(
        ERR_CAT, 7,
        [ $this->{source_file}, $cmd ],
        $this->{cmds}->executeCommand(
          { cmd => $cmd },
          $cmd, "Uncompressing source file..."
        )
      );
    }
  }
  if ( $/ ne $this->{line_separator} ) {
    $this->{previous_line_separator} = $/;
    $/ = $this->{line_separator};
  }
  $this->{error_mgr}->exitProgram( ERR_CAT, 4, [$source_file],
    !$this->{source_fh}->open( $source_file, '<' ) );
}

################################################################################
#
#				 Public Methods
#
################################################################################

sub new {
  my file::Index $this = shift;
  my ( $entity_expr, $accession_expr, $error_mgr ) = @_;
  $this = fields::new($this) unless ref($this);

  $this->{accession_expr}          = $accession_expr;
  $this->{cmds}                    = new util::Cmd($error_mgr);
  $this->{entity_expr}             = $entity_expr;
  $this->{entity_search_expr}      = '^' . $entity_expr . '.*';
  $this->{error_mgr}               = $error_mgr;
  $this->{line_separator}          = util::Constants::NEWLINE . $entity_expr;
  $this->{previous_line_separator} = util::Constants::NEWLINE;
  $this->{smap}                    = undef;
  $this->{source_fh}               = new FileHandle;
  $this->{source_file}             = undef;
  $this->{uncompressed_file}       = undef;

  return $this;
}

sub setIndex($$) {
  my file::Index $this = shift;
  my ($index) = @_;
  $this->{error_mgr}
    ->exitProgram( ERR_CAT, 5, [], util::Constants::EMPTY_LINE($index) );
  $index = getPath($index);
  $this->{error_mgr}->exitProgram(
    ERR_CAT, 9,
    [ $index, $this->{index} ],
    defined( $this->{index} ) && $this->{index} ne $index
  );
  return if ( defined( $this->{index} ) );
  $this->{index} = getPath($index);
  $this->{error_mgr}
    ->exitProgram( ERR_CAT, 1, ['read'], !defined( $this->{index} ) );
  my %smap;
  my $tie_status =
    tie( %smap, 'DB_File', $this->{index}, O_RDONLY, 0644, $DB_HASH );
  $this->{error_mgr}
    ->exitProgram( ERR_CAT, 2, [ 'read', $?, $! ], !$tie_status );
  undef $tie_status;
  $this->{smap} = \%smap;
}

sub createIndex($$) {
  my file::Index $this = shift;
  my ($file) = @_;
  $this->{source_file} = getPath($file);
  $this->{index} = join( util::Constants::DOT, $this->{source_file}, 'db' );
  $this->_setupToWriteIndex(TRUNCATE_MODE);
  my $smap = $this->{smap};
  $smap->{&INDEX_FILENAME} = basename($file);

  my $accession_expr = $this->{accession_expr};
  my $entity_expr    = $this->{entity_search_expr};
  my $loc            = undef;
  $this->_openSourceFileToIndex;
  while ( !$this->{source_fh}->eof ) {
    my $line = $this->{source_fh}->getline;
    if ( $line =~ /($entity_expr)/ ) {
      $loc = $this->{source_fh}->tell - length($&);
    }
    if ( defined($loc)
      && $line =~ /$accession_expr/ )
    {
      my $accession = $1;
      $smap->{$accession} = $loc;
      $this->{error_mgr}->printMsg("$accession $loc");
    }
  }
  $smap = undef;
  $this->finalize;
}

sub accessions($) {
  my file::Index $this = shift;
  my $smap             = $this->{smap};
  my @accessions       = ();
  foreach my $accession ( keys %{$smap} ) {
    next if ( $accession eq INDEX_FILENAME );
    push( @accessions, $accession );
  }
  $smap = undef;
  return @accessions;
}

sub num_order { $a <=> $b }

sub orderedAccessions($) {
  my file::Index $this = shift;
  my $smap             = $this->{smap};
  my %addrMap          = ();
  while ( my ( $accession, $address ) = each %{$smap} ) {
    next if ( $accession eq INDEX_FILENAME );
    if ( !defined( $addrMap{$address} ) ) { $addrMap{$address} = []; }
    push( @{ $addrMap{$address} }, $accession );
  }
  $smap = undef;
  my @ordered_accessions = ();
  foreach my $address ( sort file::Index::num_order keys %addrMap ) {
    push( @ordered_accessions, $addrMap{$address} );
  }
  return @ordered_accessions;
}

sub findIndex($$) {
  my file::Index $this = shift;
  my ($accession)      = @_;
  my $smap             = $this->{smap};
  my $loc              = $smap->{$accession};
  $smap = undef;
  return defined($loc) ? util::Constants::TRUE : util::Constants::FALSE;
}

sub readIndex($$) {
  my file::Index $this = shift;
  my ($accession)      = @_;
  my $smap             = $this->{smap};
  my $loc              = $smap->{$accession};
  $smap = undef;
  $this->{error_mgr}->printMsg("$accession $loc");
  $this->{error_mgr}->exitProgram( ERR_CAT, 6, [$accession], !defined($loc) );
  $this->_openSourceFileToRead;
  $this->{source_fh}->seek( ( $loc - 1 ), 0 );
  my $entity = $this->{source_fh}->getline;
  chomp($entity);
  $entity =~ s/\n+$//;

  return $entity;
}

sub readCurrent($) {
  my file::Index $this = shift;
  $this->_openSourceFileToRead;
  $this->{error_mgr}->printMsg("current entity");
  my $entity = $this->{source_fh}->getline;
  chomp($entity);
  $entity =~ s/\n+$//;

  my $entity_search_expr = $this->{entity_search_expr};
  return $entity if ( $entity =~ /$entity_search_expr/ );
  return $this->{entity_expr} . $entity;
}

sub finalize {
  my file::Index $this = shift;
  ###
  ### Close source file handle, reset record separator,
  ### and remove temporary file (if necessary)
  ###
  if ( defined( $this->{source_fh}->fileno ) ) {
    $this->{source_fh}->close;
    if ( $/ ne $this->{previous_line_separator} ) {
      $/ = $this->{previous_line_separator};
      $this->{previous_line_separator} = util::Constants::NEWLINE;
    }
    my $file = $this->{uncompressed_file};
    if ( defined($file) ) {
      $this->{error_mgr}->exitProgram(
        ERR_CAT, 8,
        [$file],
        $this->{cmds}->executeCommand(
          { tmp_file => $file },
          $this->{cmds}->RM_FILE($file),
          "Removing temporary uncompressed file..."
        )
      );
    }
    $this->{source_file}       = undef;
    $this->{uncompressed_file} = undef;
  }
###
### Close index
###
  my $smap = $this->{smap};
  $this->{index} = undef;
  $this->{smap}  = undef;
  untie %{$smap} if ( defined($smap) );
}

################################################################################

1;

__END__

=head1 NAME

Indexer.pm

=head1 SYNOPSIS

   use file::Index;

=head1 DESCRIPTION

This class defines the mechanism for generating indices for text data
files.

=head1 METHODS

=head2 B<new file::Index(entity_expr, accession_expr, error_mgr)>

This method is the constructor for the class.  It sets up the
information necessary for creating an index for a source file and
using the index to find entity data.  The B<entity_expr> is a string
expression for specifying the start of the line that contains the
beginning of the entity (e.g., for EntrezGene ASN
B<'Entrezgene ::= '>).  The B<accession_expr> is the Perl regular
expression for finding a (accession) identifier (e.g.,
B<'geneid\s(\d+)'>).  Note that the string of characters defining an
identifier must be set within parentheses B<'(...)'>.

=head1 SETTER METHODS

The following methods set and create the index

=head2 B<setIndex(index)>

This method sets the index file and opens it for access.

=head2 B<$num_entities = createIndex(file)>

This method creates an index for the file using the entity and accession
expressions.  It returns the number of entities found.  Also, this
method sets the index.

=head2 B<finalize>

This method finalizes the class.  It closes open file and tie handles
and sets the index and source file to undefined.

=head1 GETTER METHODS

The following methods find an index and return the entity associated
with an index.

=head2 B<@accessions = accessions>

The method returns the list of accessions defined by the index.

=head2 B<@ordered_accessions = orderedAccessions>

The method returns a list of arrays of accessions in location order.
Each element of the list is a referenced array containing the
accessions at a common location.

=head2 B<findIndex(accession)>

The method returns TRUE (1) if the B<accession> exists in the index,
otherwise it returns FALSE (0).  This method fails if the index has not
been set or cannot be opened.

=head2 B<$entity_str = readIndex(accession)>

This method returns the entity string in the file associated with
accession via the index mapping.

=head2 B<$entity_str = readCurrent>

This method returns the entity string in the file add the current read
position.  The source file must already be opened, otherwise it
terminates the program.

=cut
