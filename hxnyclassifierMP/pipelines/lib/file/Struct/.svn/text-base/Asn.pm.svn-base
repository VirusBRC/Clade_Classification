package file::Struct::Asn;
################################################################################
#
#				Required Modules
#
################################################################################

use strict;

use FileHandle;
use Pod::Usage;

use util::Constants;

use file::Index;

use asn::ErrMsgs;
use asn::Parser;

use base 'file::Struct';

use fields qw(
  accession_expr
  asn
  entity_expr
  entity_tag
  indexer
);

################################################################################
#
#			     Static Class Constants
#
################################################################################
###
### Entity Type
###
sub ENTITY_TYPE { return 'asn::Entity'; }
###
### The following component lists are supported
### for accession type
###
sub ACCESSION_TYPE { return 'accession_type'; }
sub ACCESSION      { return 'acc'; }

sub LIST_TYPES {
  return { &ACCESSION => ACCESSION_TYPE, };
}
###
### Error Category
###
sub ERR_CAT { return file::ErrMsgs::STRUCTASN_CAT; }

################################################################################
#
#				 Object Methods
#
################################################################################
###
### Constructor Method
###
sub new {
  my ( $that, $file, $error_mgr ) = @_;
  my file::Struct::Asn $this =
    $that->SUPER::new( $file, LIST_TYPES, $error_mgr );

  return $this;
}

sub setAsnTags {
  my file::Struct::Asn $this = shift;
  #######################
  ### Abstract Method ###
  #######################
  $this->{error_mgr}->printDebug("Abstract Method Asn::setAsnTags");
}

sub readFile {
  my file::Struct::Asn $this = shift;
  ###
  ### Set the specific ASN tags for the ASN-document
  ###
  $this->setAsnTags;
  ###
  ### Create ASN parser
  ###
  $this->{asn} = new asn::Parser( $this->{entity_tag}, $this->{error_mgr} );
  ###
  ### Set the object (but do not process)
  ###
  $this->{object} = [];
  ###
  ### Create the indexer and Compute the list of accessions
  ###
  $this->{indexer} =
    new file::Index( $this->{entity_expr}, $this->{accession_expr},
    $this->{error_mgr} );
  $this->{indexer}
    ->setIndex( join( util::Constants::DOT, $this->filename, 'db' ) );
  foreach my $accession ( $this->{indexer}->accessions ) {
    $this->addToList( ACCESSION, undef, $accession );
  }
}

sub finalize {
  my file::Struct::Asn $this = shift;
  $this->{indexer}->finalize;
}

################################################################################
#
#				 Getter Methods
#
################################################################################

sub getObjectByEntityId {
  my file::Struct::Asn $this = shift;
  my ( $list_comp, $entity_id ) = @_;
  my $list = $this->_getList($list_comp);
  return undef if ( !exists( $list->{$entity_id} ) );
  return $this->{asn}->parseEntity( $this->{indexer}->readIndex($entity_id) );
}

sub writeFile {
  my file::Struct::Asn $this = shift;
  my ($output_directory)     = @_;
  my $fh                     = new FileHandle;
  my $fn                     = $this->objFilename($output_directory);
  $this->{error_mgr}->exitProgram( ERR_CAT, 1, [$fn], !$fh->open( $fn, '>' ) );
  $fh->autoflush(util::Constants::TRUE);
  foreach my $entity ( @{ $this->{object} } ) {
    $fh->print( $entity->showStr );
  }
  $fh->close;
}

sub getObject {
  my file::Struct::Asn $this = shift;
  my ( $parent, $path ) = @_;
  $this->{error_mgr}->exitProgram(
    ERR_CAT, 2,
    [ join( ', ', @{$path} ) ],
    !defined($parent) || ref($parent) ne ENTITY_TYPE
  );
  my $rel_path = join( util::Constants::SLASH, @{$path} );
  return $parent->getChildBranch($rel_path);
}

sub getAttr {
  my file::Struct::Asn $this = shift;
  my ( $parent, $attr, $path ) = @_;
  my $path_msg = ( defined($path) ) ? join( ', ', @{$path} ) : undef;
  $this->{error_mgr}->exitProgram(
    ERR_CAT, 3,
    [ $path_msg, $attr ],
    !defined($parent) || ref($parent) ne ENTITY_TYPE
  );
  my $rel_path = $attr;
  if ( defined($path) ) {
    $rel_path = join( util::Constants::SLASH, @{$path}, $rel_path );
  }
  return $parent->getChildAttrForTag($rel_path);
}

################################################################################

1;

__END__

=head1 NAME

Asn.pm

=head1 DESCRIPTION

This abstract class is a subclass of L<file::Struct> and
implements this super class's abstract methods for ASN-documents:
B<readFile>, B<writeFile>, B<getObject>, and B<getAttr>.  This class
is abstract since it defines the abstract method B<setAsnTags> that is
used in readFile.  The method B<setAsnTags> defines the specific ASN
tags for the given ASN-document format.  This class creates the object
which is referenced array of L<asn::Entity> objects.

=head1 METHODS

The following methods are defined for this class.

=head2 B<new file::Struct::Asn(file, list_types, error_mgr)>

This method is the constructor for the Asn file reader class.  The
result of reading is a (referenced array) list of L<asn::Entity>
objects and a set of lists described in L<file::Struct>.  The
B<list_types> is a referenced array, mapping the component lists to
the the entity types.  The error_mgr is an instance of the
L<util::ErrMgr> class and is required for registering errors.

=head1 SETTER METHODS

The following setter methods are defined for this class.

=head2 B<setAsnTags>

This abstract method sets the ASN tags specific to the the
ASN-document being processed.  These includes the following class
attributes:

   entity_tag     -- Tag defining the top-level tag for an ASN1
                     entity
   entity_expr    -- Expression defining the beginning of entity
                     in the file
   accession_expr -- Expression defining where to find accessions
                     defined in the entity

=head2 B<readFile>

This method defines how a file is read and the file object is created
and the component lists are generated.  It calls the following method
L<"setAsnTags">.

=head2 B<finalize>

This method finalizes the index.

=head1 GETTER METHODS

The following getter methods are defined for this class.

=head2 B<object>

This method implemented in the parent class returns a reference array
list of L<asn::Entity> objects occurring in the file.

=head2 B<writeFile(output_directory)>

This method writes the entity representation of the file object and
the Perl object representationo of its associated lists to the
following file:

   <output_directory/basename(<file>).object

=head2 B<$sub_object = getObject(parent, path)>

This method returns a reference to the sub-object in the
parent object based on the path expression (a referenced array of
component names).  If none exists, then undef is returned.  It is an
fatal error if the path contains a component name to an array.  The
path is a relative expression from the parent.

=head2 B<$attr_value = getAttr(parent, attr[, path])>

This method returns the attribute value for the attribute from the
sub-object in the parent object based on the path expression (a
referenced array of component names) if the path is defined, otherwise
the method returns the attribute value for the attribute in the
parent.  If no attribute value can be found, then undef is returned.
The path is a relative expression from the parent.

=cut
