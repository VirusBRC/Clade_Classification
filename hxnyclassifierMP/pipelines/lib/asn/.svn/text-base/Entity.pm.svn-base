package asn::Entity;
################################################################################
#
#				Required Modules
#
################################################################################

use strict;

use File::Basename;
use FileHandle;

use util::Constants;
use util::PathSpecifics;
use util::PerlObject;

use asn::ErrMsgs;
use fields qw (
  attrs
  children
  error_mgr
  paths_generated
  serializer
  tag
  value
);

################################################################################
#
#				   Constants
#
################################################################################
###
### Show formating
###
sub INDENT { return ' '; }
###
### Error Category
###
sub ERR_CAT { return asn::ErrMsgs::ENTITY_CAT; }

################################################################################
#
#			     Private Methods
#
################################################################################

sub _removeQuotes {
  my asn::Entity $this = shift;
  my ($str) = @_;
  return $str if ( $str eq util::Constants::EMPTY_STR );
  $str =~ s/^"(.*)"$/$1/;
  return $str;
}

sub _show {
  my asn::Entity $this = shift;
  my ($indent) = @_;
  my $str =
      $indent
    . "tag   = "
    . $this->getTag . "\n"
    . $indent
    . "value = "
    . $this->getValue . "\n";
  my @keys = keys %{ $this->{attrs} };
  if ( @keys > 0 ) {
    my $attrs =
      $this->{serializer}->serializeObject( $this->{attrs},
      util::PerlObject::PERL_OBJECT_WRITE_OPTIONS );
    $attrs =~ s/\n/\n$indent        /g;
    $attrs =~ s/ +$//;
    $str .= $indent . "attrs = $attrs\n";
  }
  my $child_indent = $indent . INDENT;
  foreach my $child ( @{ $this->getChildren } ) {
    my $child_str = $child->_show($child_indent);
    $child_str =~ s/ +$//;
    $child_str =~ s/\n +\n/\n/g;
    $str .= $indent . "child =\n" . $child_str;
  }
  return $str;
}

sub _generatePaths {
  my asn::Entity $this = shift;
  my ($prefix) = @_;
  return if ( $this->{paths_generated} );
  $this->setTag( join( util::Constants::SLASH, $prefix, $this->getTag ) );
  $this->setValue( $this->_removeQuotes( $this->getValue ) );
  $this->{paths_generated} = util::Constants::TRUE;
  my @current_children = @{ $this->{children} };
  @{ $this->{children} } = ();

  foreach my $child (@current_children) {
    my $child_tag   = $child->getTag;
    my $child_value = $this->_removeQuotes( $child->getValue );
    if ( @{ $child->getChildren } > 0
      || !defined($child_tag)
      || $child_tag eq util::Constants::EMPTY_STR )
    {
      push( @{ $this->{children} }, $child );
      $child->_generatePaths( $this->getTag );
    }
    elsif ( defined($child_value) ) {
      my $current_value = $this->getAttr($child_tag);
      if ( defined($current_value) ) {
        if ( ref($current_value) ) {
          push( @{$current_value}, $child_value );
        }
        else {
          $this->setAttr( $child_tag, [ $current_value, $child_value ] );
        }
      }
      else {
        $this->setAttr( $child_tag, $child_value );
      }
    }
  }
}

sub _getTagValue {
  my asn::Entity $this = shift;
  my ($tag_path) = @_;
  return $this->getValue if ( $tag_path eq $this->getTag );
  foreach my $child ( @{ $this->getChildren } ) {
    my $value = $child->_getTagValue($tag_path);
    return $value if ( defined($value) );
  }
  return undef;
}

sub _getTagValues {
  my asn::Entity $this = shift;
  my ( $tag_path, $values ) = @_;
  if ( $tag_path eq $this->getTag ) {
    push( @{$values}, $this->getValue );
  }
  else {
    foreach my $child ( @{ $this->getChildren } ) {
      my $child_tag = $child->getTag;
      if ( $tag_path =~ /^$child_tag/ ) {
        $child->_getTagValues( $tag_path, $values );
      }
    }
  }
}

sub _getAllBranches {
  my asn::Entity $this = shift;
  my ( $tag_path, $branches ) = @_;
  if ( $tag_path eq $this->getTag ) {
    push( @{$branches}, $this );
  }
  else {
    foreach my $child ( @{ $this->getChildren } ) {
      my $child_tag = $child->getTag;
      if ( $tag_path =~ /^$child_tag/ ) {
        $child->_getAllBranches( $tag_path, $branches );
      }
    }
  }
}

sub _getFullPath {
  my asn::Entity $this = shift;
  my ($rel_path)       = @_;
  my $tag_path         = $this->getTag;
  return $tag_path if ( !defined($rel_path) );
  return join( util::Constants::SLASH, $tag_path, $rel_path );
}

################################################################################
#
#				 Public Methods
#
################################################################################

sub new {
  my asn::Entity $this = shift;
  my ($error_mgr) = @_;
  $this = fields::new($this) unless ref($this);
  $this->{attrs}           = {};
  $this->{children}        = [];
  $this->{error_mgr}       = $error_mgr;
  $this->{paths_generated} = util::Constants::FALSE;
  $this->{serializer}      = new util::PerlObject( undef, undef, $error_mgr );
  $this->{tag}             = util::Constants::EMPTY_STR;
  $this->{value}           = util::Constants::EMPTY_STR;

  return $this;
}

sub setTag {
  my asn::Entity $this = shift;
  my ($tag) = @_;
  $this->{tag} = $tag;
}

sub setValue {
  my asn::Entity $this = shift;
  my ($value) = @_;
  $this->{value} = $value;
}

sub setAttr {
  my asn::Entity $this = shift;
  my ( $key, $value ) = @_;
  $this->{attrs}->{$key} = $value;
}

sub removeAttr {
  my asn::Entity $this = shift;
  my ($key) = @_;
  return if ( !defined( $this->{attrs}->{$key} ) );
  delete( $this->{attrs}->{$key} );
}

sub setChild {
  my asn::Entity $this = shift;
  my ($child) = @_;
  return if ( !defined($child)
    || ref($child) ne ref($this) );
  push( @{ $this->{children} }, $child );
}

sub removeChild {
  my asn::Entity $this = shift;
  my ( $tag_path, $value ) = @_;
  return if ( @{ $this->{children} } == 0 );
  my @current_children = @{ $this->{children} };
  @{ $this->{children} } = ();
  foreach my $child (@current_children) {
    my $child_tag   = $child->getTag;
    my $child_value = $child->getValue;
    next if ( $tag_path eq $child_tag && $value eq $child_value );
    push( @{ $this->{children} }, $child );
  }
}

sub getTag {
  my asn::Entity $this = shift;
  return $this->{tag};
}

sub getBaseTag {
  my asn::Entity $this = shift;
  return basename( $this->{tag} );
}

sub getValue {
  my asn::Entity $this = shift;
  return $this->{value};
}

sub getAttr {
  my asn::Entity $this = shift;
  my ($key) = @_;
  foreach my $attr_key ( keys %{ $this->{attrs} } ) {
    return $this->{attrs}->{$attr_key} if ( $key eq $attr_key );
  }
  return undef;
}

sub getAttrs {
  my asn::Entity $this = shift;
  return $this->{attrs};
}

sub getChildren {
  my asn::Entity $this = shift;
  return $this->{children};
}

sub getLastChild {
  my asn::Entity $this = shift;
  if ( @{ $this->{children} } == 0 ) {
    $this->setChild( new asn::Entity( $this->{error_mgr} ) );
  }
  return $this->{children}->[ $#{ $this->{children} } ];
}

sub generatePaths {
  my asn::Entity $this = shift;
  return if ( $this->{paths_generated} );
  my @current_children = @{ $this->{children} };
  @{ $this->{children} } = ();
  foreach my $child (@current_children) {
    my $child_tag   = $child->getTag;
    my $child_value = $this->_removeQuotes( $child->getValue );
    if ( @{ $child->getChildren } > 0
      || !defined($child_tag)
      || $child_tag eq util::Constants::EMPTY_STR )
    {
      push( @{ $this->{children} }, $child );
      $child->_generatePaths( $this->getTag );
    }
    elsif ( defined($child_value) ) {
      my $current_value = $this->getAttr($child_tag);
      if ( defined($current_value) ) {
        if ( ref($current_value) ) {
          push( @{$current_value}, $child_value );
        }
        else {
          $this->setAttr( $child_tag, [ $current_value, $child_value ] );
        }
      }
      else {
        $this->setAttr( $child_tag, $child_value );
      }
    }
  }
}

sub showStr {
  my asn::Entity $this = shift;
  my $str =
    "tag   = " . $this->getTag . "\n" . "value = " . $this->getValue . "\n";
  my @keys = keys %{ $this->{attrs} };
  if ( @keys > 0 ) {
    my $attrs =
      $this->{serializer}->serializeObject( $this->{attrs},
      util::PerlObject::PERL_OBJECT_WRITE_OPTIONS );
    $attrs =~ s/\n/\n        /g;
    $str .= "attrs = $attrs\n";
  }
  my $indent = INDENT;
  foreach my $child ( @{ $this->getChildren } ) {
    my $child_str = $child->_show($indent);
    $str .= "child =\n$child_str";
  }
  return $str;
}

sub show {
  my asn::Entity $this = shift;
  my ($filename) = @_;
  $filename = getPath($filename);
  unlink($filename);
  my $fh = new FileHandle;
  $this->{error_mgr}
    ->exitProgram( ERR_CAT, 1, [$filename], !$fh->open( $filename, '>' ) );
  $fh->print( $this->showStr );
  $fh->close;
}

sub getTagValue {
  my asn::Entity $this = shift;
  my ($tag_path) = @_;
  return $this->getValue
    if ( $tag_path eq util::Constants::EMPTY_STR
    || ( defined( $this->getTag ) && $tag_path eq $this->getTag ) );
  foreach my $child ( @{ $this->getChildren } ) {
    my $value = $child->_getTagValue($tag_path);
    return $value if ( defined($value) );
  }
  return undef;
}

sub getTagValues {
  my asn::Entity $this = shift;
  my ($tag_path)       = @_;
  my $values           = [];
  if ( $tag_path eq util::Constants::EMPTY_STR
    || $tag_path eq $this->getTag )
  {
    push( @{$values}, $this->getValue );
  }
  else {
    foreach my $child ( @{ $this->getChildren } ) {
      $child->_getTagValues( $tag_path, $values );
    }
  }
  return $values;
}

sub getBranch {
  my asn::Entity $this = shift;
  my ($tag_path)       = @_;
  my $branch           = undef;
  if ( $tag_path eq util::Constants::EMPTY_STR
    || $tag_path eq $this->getTag )
  {
    $branch = $this;
  }
  else {
    foreach my $child ( @{ $this->getChildren } ) {
      my $child_tag = $child->getTag;
      if ( $tag_path =~ /^$child_tag/ ) {
        $branch = $child->getBranch($tag_path);
      }
      last if ( defined($branch) );
    }
  }
  return $branch;
}

sub getAllBranches {
  my asn::Entity $this = shift;
  my ($tag_path)       = @_;
  my $branches         = [];
  if ( $tag_path eq util::Constants::EMPTY_STR
    || $tag_path eq $this->getTag )
  {
    push( @{$branches}, $this );
  }
  else {
    foreach my $child ( @{ $this->getChildren } ) {
      $child->_getAllBranches( $tag_path, $branches );
    }
  }
  return $branches;
}

sub getAttrForTag {
  my asn::Entity $this = shift;
  my ($tag_path)       = @_;
  my $key              = basename($tag_path);
  $tag_path =~ s/\/$key$//;
  my $branch = $this->getBranch($tag_path);
  return undef if ( !defined($branch) );
  return $branch->getAttr($key);
}

sub getAttrForAllTags {
  my asn::Entity $this = shift;
  my ($tag_path)       = @_;
  my $key              = basename($tag_path);
  $tag_path =~ s/\/$key$//;
  my $values = [];
  foreach my $branch ( @{ $this->getAllBranches($tag_path) } ) {
    my $value = $branch->getAttr($key);
    next if ( !defined($value) || $value eq util::Constants::EMPTY_STR );
    push( @{$values}, $value );
  }
  return $values;
}

sub getChildTagValue {
  my asn::Entity $this = shift;
  my ($rel_path) = @_;
  return $this->getTagValue( $this->_getFullPath($rel_path) );
}

sub getChildTagValues {
  my asn::Entity $this = shift;
  my ($rel_path) = @_;
  return $this->getTagValues( $this->_getFullPath($rel_path) );
}

sub getChildBranch {
  my asn::Entity $this = shift;
  my ($rel_path) = @_;
  return $this->getBranch( $this->_getFullPath($rel_path) );
}

sub getAllChildBranches {
  my asn::Entity $this = shift;
  my ($rel_path) = @_;
  return $this->getAllBranches( $this->_getFullPath($rel_path) );
}

sub getChildAttrForTag {
  my asn::Entity $this = shift;
  my ($rel_path) = @_;
  return $this->getAttrForTag( $this->_getFullPath($rel_path) );
}

sub getChildAttrForAllTags {
  my asn::Entity $this = shift;
  my ($rel_path) = @_;
  return $this->getAttrForAllTags( $this->_getFullPath($rel_path) );
}

sub convertToList {
  my asn::Entity $this = shift;
  my ($values) = @_;
  return $values if ( !ref($values) );
  return @{$values};
}

################################################################################

1;

__END__

=head1 NAME

AsnEntity.pm

=head1 SYNOPSIS

This class defines the data-structure for storing ASN1 entities.  It
is defined to support a hierarchically/recursive data-structure.

=head1 METHODS

The following methods are exported from the class.

=head2 B<new asn::Entity(error_mgr)>

This method is the constructor of the class and creates an entity.  An
entity consists of the following:

  attrs    -- attributes of the entity
  children -- list of children entities represented by
              instances of this class
  tag      -- tag name for the entity
  value    -- value of the tag name for the entity

Initially, there are no attributes or children and the tag and value
are both empty strings.

=head2 B<generatePaths>

This method generates the full path expression names for tags and it
children recursively.  Once the paths are created, then cannot be
regenerated.

=head2 B<my $str = showStr>

This method generates a human readable string version of the entity
appropriately indented.

=head2 B<show(filename)>

This method generates a human readable string version of the entity
into a file, filename.  This method uses L<"my $str = showStr">.

=head2 B<convertToList(values)>

This method converts a reference entity into a list and returns the
list, otherwise it returns values 'as-is'.

=head1 PATH METHODS

The following path methods are exported from the class. These methods
assume that tag names have path expressions generated for them
(L<"generatePaths">).  Otherwise, these method may provide spurious
results.

=head2 B<getTagValue(tag_path)>

This method returns a single tag value for the first sub-entity with
given absolute tag_path.

=head2 B<getTagValues(tag_path)>

This method returns a (reference) list of tag values matching all
sub-entities with the absolute tag_path.

=head2 B<getBranch(tag_path)>

This method returns the first branch subentity with the absolute
tag_path.

=head2 B<getAllBranches(tag_path)>

This method returns the list (reference) of all subentity branches
with the absolute tag_path.

=head2 B<getAttrForTag(attr_tag_path)>

This method returns the value of the attribute (attr_name) for the
first sub-entity having the tag_path where attr_tag_path has the
format:

   tag_path/attr_name

where the tag_path is an absolute path.

=head2 B<getAttrForAllTags(attr_tag_path)>

This method returns the list (reference) of all attribute values of
attr_name for all sub-entities having the tag_path where attr_tag_path
has the format:

   tag_path/attr_name

where the tag_path is an absolute path.

=head2 B<getChildTagValue(rel_path)>

This method returns a single tag value for the first sub-entity with
the given relative path, rel_path, relative to the given object.

=head2 B<getChildTagValues(rel_path)>

This method returns a (reference) list of tag values matching all
sub-entities with the given relative path, rel_path, relative to the
given object.

=head2 B<getChildBranch(rel_path)>

This method returns the first branch subentity with the given relative
path, rel_path, relative to the given object.

=head2 B<getAllChildBranches(rel_path)>

This method returns the list (reference) of all subentity branches
with the given relative path, rel_path, relative to the given object.

=head2 B<getChildAttrForTag(attr_rel_path)>

This method returns the value of the attribute (attr_name) for the
first sub-entity having the rel_path where attr_rel_path has the
format:

   rel_path/attr_name

where the rel_path is a relative path.

=head2 B<getChildAttrForAllTags(attr_rel_path)>

This method returns the list (reference) of all attribute values of
attr_name for all sub-entities having the rel_path where attr_tag_path
has the format:

   rel_path/attr_name

where the rel_path is a relative path.

=head1 SETTER METHODS

The following setters methods are exported from the class.

=head2 B<setTag(tag)>

This method set the tag name for the entity

=head2 B<setValue(value)>

This method set the value for the tag of the entity.

=head2 B<setAttr(key, value)>

This method set attribute by the (key, value) pair.  If the attribute
already exists, it is over written.

=head2 B<removeAttr(key)>

This method removes the attribute if it exists.

=head2 B<removeChild(tag_path, $value)>

This method removes the child in the entity with the tag name tag_path
and tag value, value.

=head2 B<setChild(child)>

This method adds a child to the entity and childs that it is an
instance of this class.  If it not an instance of this class, it is
not added.

=head1 GETTER METHODS

The following getter methods are exported from the class.

=head2 B<getTag>

This method return the tag name for the entity.  If the
L<"generatePaths"> has been called on this entity, then the tag name
will be the full path expression of the tag.

=head2 B<getBaseTag>

This method return the basename of the tag for the entity.  This will
differ than the tag name if path expressions have been generated for
the the entity (L<"generatePaths">).

=head2 B<getValue>

This method return the value of the tag name for the entity.

=head2 B<getAttr(key)>

This method return the value of the attribute assuming it is defined
in the entity, otherwise it returns undef.

=head2 B<getAttrs>

This method returns the hash reference of the attributes for the
entity.

=head2 B<getChildren>

This method returns the array (reference) to the list of children
entities for the entity.  If there are none, then the array is empty.

=head2 B<getLastChildren>

This method returns the last child entity for this entity.  If the
child list is empty, it creates this child, adds it to the list and
returns it.

=cut
