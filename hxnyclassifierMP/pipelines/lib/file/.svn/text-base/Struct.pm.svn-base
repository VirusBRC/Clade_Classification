package file::Struct;
################################################################################
#
#				Required Modules
#
################################################################################

use strict;

use File::Basename;
use Pod::Usage;

use util::Constants;
use util::PathSpecifics;

use file::ErrMsgs;

use fields qw(
  entity_ids
  error_mgr
  file
  lists
  list_types
  object
);

################################################################################
#
#			     Static Class Constants
#
################################################################################
###
### Error Category
###
sub ERR_CAT { return file::ErrMsgs::STRUCT_CAT; }

################################################################################
#
#				Private Methods
#
################################################################################

sub _createLists {
  my file::Struct $this = shift;
  my ($list_types) = @_;
  $this->{error_mgr}->exitProgram( ERR_CAT, 2, [],
    !defined($list_types) || ref($list_types) ne 'HASH' );
  my @list_comps = keys %{$list_types};
  $this->{error_mgr}->exitProgram( ERR_CAT, 3, [], @list_comps == 0 );
  %{ $this->{list_types} } = %{$list_types};
  my $lists = $this->{lists};
  while ( my ( $list_comp, $list_type ) = each %{ $this->{list_types} } ) {
    $this->{error_mgr}->exitProgram( ERR_CAT, 4, [$list_comp],
      !defined($list_type) || $list_type eq util::Constants::EMPTY_STR );
    if ( !defined( $lists->{$list_type} ) ) { $lists->{$list_type} = {}; }
    $lists->{$list_type}->{$list_comp} = {};
  }
}

sub _getList {
  my file::Struct $this = shift;
  my ($list_comp)       = @_;
  my $list_types        = $this->{list_types};
  $this->{error_mgr}->exitProgram( ERR_CAT, 5, [$list_comp],
    !defined( $list_types->{$list_comp} ) );
  return $this->{lists}->{ $list_types->{$list_comp} }->{$list_comp};
}

################################################################################
#
#				 Constructor
#
################################################################################
###
### Constructor Method
###
sub new {
  my file::Struct $this = shift;
  my ( $file, $list_types, $error_mgr ) = @_;
  $this = fields::new($this) unless ref($this);
  ###
  ### Create the class
  ###
  $this->{entity_ids} = {};
  $this->{error_mgr}  = $error_mgr;
  $this->{file}       = getPath($file);
  $this->{list_types} = {};
  $this->{lists}      = {};
  $this->{object}     = undef;

  $this->_createLists($list_types);
  ###
  ### Read filePrint Header
  ###
  $this->{error_mgr}->printDateHeader( "Parsing File\n"
      . "  dir  = "
      . dirname( $this->{file} ) . "\n"
      . "  file = "
      . basename( $this->{file} ) );
  $this->{error_mgr}->exitProgram(
    ERR_CAT, 1,
    [ $this->{file} ],
    !-e $this->{file} || !-f $this->{file} || !-r $this->{file}
  );
  $this->readFile;
  ###
  ### Write Information in Debugging Mode
  ###
  $this->writeFile(util::Constants::DOT) if ( $this->{error_mgr}->isDebugging );

  return $this;
}

################################################################################
#
#				 Setter Methods
#
################################################################################

sub readFile {
  my file::Struct $this = shift;
  #######################
  ### Abstract Method ###
  #######################
  $this->{error_mgr}->printDebug("Abstract Method FileStruct::readFile");
}

sub addToList {
  my file::Struct $this = shift;
  my ( $list_comp, $entity, $entity_id ) = @_;
  my $list = $this->_getList($list_comp);
  $list->{$entity_id} = $entity;
}

sub setEntityId {
  my file::Struct $this = shift;
  my ( $list_comp, $entity_id ) = @_;
  my $list = $this->_getList($list_comp);
  $this->{error_mgr}->exitProgram(
    ERR_CAT, 6,
    [ $list_comp, $entity_id ],
    !exists( $list->{$entity_id} )
  );
  my $entity_ids = $this->{entity_ids};
  if ( !defined( $entity_ids->{$list_comp} ) ) {
    $entity_ids->{$list_comp} = {};
  }
  $entity_ids->{$list_comp}->{$entity_id} = util::Constants::EMPTY_STR;
}

sub setEntityIds {
  my file::Struct $this = shift;
  my ( $list_comp, @entity_ids ) = @_;
  foreach my $entity_id (@entity_ids) {
    $this->setEntityId( $list_comp, $entity_id );
  }
}

################################################################################
#
#				 Getter Methods
#
################################################################################

sub writeFile {
  my file::Struct $this = shift;
  my ($output_directory) = @_;
  #######################
  ### Abstract Method ###
  #######################
  $this->{error_mgr}->printDebug("Abstract Method FileStruct::writeFile");
}

sub filename {
  my file::Struct $this = shift;
  return $this->{file};
}

sub object {
  my file::Struct $this = shift;
  return $this->{object};
}

sub getObject {
  my file::Struct $this = shift;
  my ( $parent, $path ) = @_;
  #######################
  ### Abstract Method ###
  #######################
  $this->{error_mgr}->printDebug("Abstract Method FileStruct::getObject");
}

sub getAttr {
  my file::Struct $this = shift;
  my ( $parent, $attr, $path ) = @_;
  #######################
  ### Abstract Method ###
  #######################
  $this->{error_mgr}->printDebug("Abstract Method FileStruct::getAttr");
}

sub getList {
  my file::Struct $this = shift;
  my ($list_comp) = @_;
  return keys %{ $this->_getList($list_comp) };
}

sub listType {
  my file::Struct $this = shift;
  my ($list_comp) = @_;
  return $this->{list_types}->{$list_comp};
}

sub getEntityIds {
  my file::Struct $this = shift;
  my ($list_comp)       = @_;
  my $entity_ids        = $this->{entity_ids};
  my @entity_ids        = ();
  if ( defined( $entity_ids->{$list_comp} ) ) {
    @entity_ids = keys %{ $entity_ids->{$list_comp} };
  }
  return @entity_ids;

}

sub getObjectByEntityId {
  my file::Struct $this = shift;
  my ( $list_comp, $entity_id ) = @_;
  ###############################
  ### Re-implementable Method ###
  ###############################
  my $list = $this->_getList($list_comp);
  return $list->{$entity_id};
}

sub objFilename {
  my file::Struct $this  = shift;
  my ($output_directory) = @_;
  my $filename           = join( util::Constants::SLASH,
    $output_directory,
    join( util::Constants::DOT, basename( $this->{file} ), 'object' ) );
  unlink($filename);
  return $filename;
}

################################################################################

1;

__END__

=head1 NAME

FileStruct.pm

=head1 DESCRIPTION

The abstract class define the mechanism for reading files and
generating the appropriate B<file> object and the associated list of
entity ids for each B<list_types>.  This class is abstract since it
does not implement the methods: B<readFile>, B<writeFile>,
B<getObject>, and B<getAttr>.  These methods must be implemented by a
subclass.  The B<readFile> method takes the file attribute and
generates the appropriate file object and associated list of entity
ids for each list_type in the constructor.  This class also defines
the re-implementable method getObjectByEntityId that returns the
entity object for a given entity id.

=head1 METHODS

The following method are exported for this class

=head2 B<new file::Struct(file, list_types, error_mgr)>

This method is the constructor for this class.  The file is read using
the specific read method for the subclass which implements this
superclass.  The result of reading the file is an object describing
the file and a set of entity id for each list_type as defined by
B<list_types>.  B<list_types> is a referenced hash defines the mapping
entity component list to entity id list type.  The error_mgr is an
instance of the L<util::ErrMgr> class and is required for registering
errors.

=head1 SETTER METHODS

The following setter methods are defined for this class.

=head2 B<readFile>

This abstract method defines how a file is read and the file object is
created and the component lists are generated.

=head2 B<addToList(list_comp, entity, entity_id)>

This method adds the entity_id to the component list list_comp and
sets it value to the entity in the list.  If the list_comp does not
exist, then a terminal error occurs.

=head2 B<setEntityId(list_comp, entity_id)>

This method add the entity_id to entity_ids list_comp.  The entity_id
must be in the component list list_comp, otherwise a terminal error
occurs.

=head2 B<setEntityIds(list_comp, @entity_ids)>

This method add the @entity_ids list to the entity_ids list_comp.  All
the ids must be in the component list list_comp, otherwise a terminal
error occurs.

=head1 GETTER METHODS

The following getter methods are defined for this class.

=head2 B<writeFile(output_directory)>

This abstract method writes a representation of the
file object and its associated lists to the following file:

   <output_directory/basename(<file>).object

=head2 B<$filename = filename>

This method returns the filename.

=head2 B<$object = object>

This method returns the Perl object generated from the file.

=head2 B<$sub_object = getObject(parent, path)>

This abstract method returns a sub-object in the parent object based
on the path expression (a referenced array of component names).  If
none exists, then undef is returned.

=head2 B<$attr_value = getAttr(parent, attr[, path])>

This abstract method returns the attribute value for the attribute
from the sub-object in the parent object based on the path expression
(a referenced array of component names) if the path is defined,
otherwise the method returns the attribute value for the attribute in
the parent.  If no attribute value can be found, then undef is
returned.

=head2 B<@entity_ids = getList(list_comp)>

This method returns a unique list of the entity ids for the given
component list list_comp.

=head2 B<$list_type = listType(list_comp)>

This method returns the list type for the component list list_comp.

=head2 B<@entity_ids = getEntityIds(list_comp)>

This method returns a unique list of the entity ids for the given
entity_ids list list_comp.

=head2 B<$entity = getObjectByEntityId(list_comp, $entity_id)>

This re-implementable method returns entity in the object for the
given entity_id.  If the entity_id is not defined in the list_comp,
then undef is returned.  The default behavior is to return the value
of object value of the entity_id store in the B<addToList> method.

=head2 B<$object_filename = objFilename(output_directory)>

This method returns the object filename in the directory ,
B<output_directory>, where the method L<"writeFile(output_directory)">
writes the object file content.

=cut
