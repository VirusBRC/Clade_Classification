package file::Struct::Bcp;
################################################################################
#
#				Required Modules
#
################################################################################

use strict;

use Pod::Usage;

use util::PerlObject;

use file::ErrMsgs;

use base 'file::Struct';

use fields qw(
  chunker
  key_order
  file_order
);

################################################################################
#
#			     Static Class Constants
#
################################################################################
###
### Super Class
###
sub CHUNK_SUPER_CLASS { return 'file::Chunk::Bcp'; }
###
### Key Separator
###
sub KEY_SEPARATOR { return '::'; }
###
### Error Category
###
sub ERR_CAT { return file::ErrMsgs::STRUCTBCP_CAT; }

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
  my file::Struct::Bcp $this =
    $that->SUPER::new( $file, $list_types, $error_mgr );

  return $this;
}

sub setFileOrder {
  my file::Struct::Bcp $this = shift;
  #######################
  ### Abstract Method ###
  #######################
  $this->{error_mgr}
    ->printDebug("Abstract Method file::Struct::Bcp::setFileOrder");
}

sub setChunker {
  my file::Struct::Bcp $this = shift;
  #######################
  ### Abstract Method ###
  #######################
  $this->{error_mgr}
    ->printDebug("Abstract Method file::Struct::Bcp::setChunker");
}

sub computeLists {
  my file::Struct::Bcp $this = shift;
  #######################
  ### Abstract Method ###
  #######################
  $this->{error_mgr}
    ->printDebug("Abstract Method file::Struct::Bcp::computeLists");
}

sub getKey {
  my file::Struct::Bcp $this = shift;
  my ($entity)               = @_;
  my $ord                    = $this->getKeyOrder;
  return undef if ( util::Constants::EMPTY_LINE($ord) );
  my @row = ();
  foreach my $col ( @{$ord} ) { push( @row, $entity->{"$col"} ); }
  return join( KEY_SEPARATOR, @row );
}

sub readFile {
  my file::Struct::Bcp $this = shift;
  ###
  ### Set the file_order and chunker attributes
  ###
  $this->setFileOrder;
  $this->setChunker;
  my $chunk_class_type  = ref( $this->{chunker} );
  my $chunk_super_class = CHUNK_SUPER_CLASS;
  $this->{error_mgr}->exitProgram(
    ERR_CAT, 1,
    [ $chunk_super_class, $chunk_class_type ],
    $chunk_class_type !~ /^$chunk_super_class/
  );
  ###
  ### Read the file
  ###
  $this->{chunker}->setSourceFile( $this->filename );
  $this->{chunker}->readBcpFile;
  $this->{object} = $this->{chunker}->getEntities;
  ###
  ### Compute standard lists
  ###
  $this->computeLists;
}

################################################################################
#
#				 Getter Methods
#
################################################################################

sub writeFile {
  my file::Struct::Bcp $this = shift;
  my ($output_directory) = @_;
  my $objfile = new util::PerlObject( $this->objFilename($output_directory),
    undef, $this->{error_mgr} );
  my @entity_list = ( $this->{lists}, $this->{object} );
  foreach my $entity (@entity_list) {
    $objfile->writeStream( $entity,
      util::PerlObject::PERL_OBJECT_WRITE_OPTIONS );
  }
  $objfile->closeIo;
}

sub getObject {
  my file::Struct::Bcp $this = shift;
  my ( $parent, $path ) = @_;
  ###
  ### NO-OP:  Not meaningful for bcp files
  ###
  return undef;
}

sub getAttr {
  my file::Struct::Bcp $this = shift;
  my ( $parent, $tag, $type ) = @_;
  ###
  ### NO-OP:  Not meaningful for bcp files
  ###
  return undef;
}

sub getFileOrder {
  my file::Struct::Bcp $this = shift;
  return [ @{ $this->{file_order} } ];
}

sub getKeyOrder {
  my file::Struct::Bcp $this = shift;
  return undef if ( util::Constants::EMPTY_LINE( $this->{key_order} ) );
  return [ @{ $this->{key_order} } ];
}

################################################################################

1;

__END__

=head1 NAME

Bcp.pm

=head1 DESCRIPTION

This abstract class is a subclass of L<file::Struct> and implements
this super class's abstract methods for special-character separated
Files: B<readFile>, B<writeFile>, B<getObject>, and B<getAttr>.  This
class is abstract since it defines the abstract methods:
B<setFileOrder>, B<setChunker>, and B<computeLists>.  These methods
defined the file column order of the source bcp formated file, the
chunker object for chunking the bcp formated file, and mechanism for
computing lists, respectively.  This object must be a subclass
L<file::Chunk::Bcp>, and all three abstract methods are used in
B<readFile>.

=head1 METHODS

The following methods are defined for this class.

=head2 B<new file::Struct::Bcp(file, list_types, error_mgr)>

This method is the constructor for the special-character separated
file reader class.  The result of reading the file is an array of
referenced hashes for each line with the keys defined by
L<"setFileOrder">.  and a set of lists described in L<file::Struct>.
This object is a B<HASH> Perl object.  The B<list_types> is a
referenced array, mapping the component lists to the the entity types.
The error_mgr is an instance of the L<util::ErrMgr> class and is
required for registering errors.

=head1 SETTER METHODS

The following setter methods are defined for this class.

=head2 B<setFileOrder>

This abstract method sets the file_order array attribute and is used
in L<"readFile"> before L<"setChunker"> is executed so that the
file_order attribute is available.

=head2 B<setChunker>

This abstract method creates the chunker object that is a subclass of
B<util::Chunker::Bcp>.

=head2 B<computeLists>

This abstract method computes the component lists for the object.

=head2 B<readFile>

This method defines how a file is read and the file object is created
and the component lists are generated.  It calls the following methods
in order: L<"setFileOrder">, B<"setChunker">, and L<"computeLists">.

=head1 GETTER METHODS

The following getter methods are defined for this class.

=head2 B<writeFile(output_directory)>

This method writes Perl data-structure versions of the component lists
and the object.

=head2 B<$sub_object = getObject(parent, path)>

This method is a NO-OP since it is not meaningful for bcp files.

=head2 B<$tag_value = getAttr(entity, tag[, type])>

This method is a NO-OP since it is not meaningful for bcp files.

=cut
