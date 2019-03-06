package util::Properties;
################################################################################
#
#				Required Modules
#
################################################################################

use strict;

use Carp 'confess';
use FileHandle;
use Pod::Usage;

use util::Constants;
use util::PathSpecifics;

use fields qw(
  properties
);

################################################################################
#
#				    Methods
#
################################################################################

sub new {
  my util::Properties $this = shift;
  $this = fields::new($this) unless ref($this);
  $this->{properties} = {};
  return $this;
}

sub clear {
  my util::Properties $this = shift;
  my $properties = $this->{properties};
  foreach my $property ( keys %{ $this->{properties} } ) {
    delete( $properties->{$property} );
  }
}

sub getProperty {
  my util::Properties $this = shift;
  my ($property) = @_;
  return $this->{properties}->{$property};
}

sub isEmpty {
  my util::Properties $this = shift;
  my @properties = keys %{ $this->{properties} };
  return ( @properties == 0 );
}

sub propertyNames {
  my util::Properties $this = shift;
  my @properties = keys %{ $this->{properties} };
  return @properties;
}

sub setProperty {
  my util::Properties $this = shift;
  my ( $property, $value ) = @_;
  $this->{properties}->{$property} = $value;
}

sub remove {
  my util::Properties $this = shift;
  my ($property)            = @_;
  my $properties            = $this->{properties};
  delete( $properties->{$property} );
}

sub size {
  my util::Properties $this = shift;
  my @properties = keys %{ $this->{properties} };
  return $#properties + 1;
}

sub containsProperty {
  my util::Properties $this = shift;
  my ($property) = @_;
  return exists( $this->{properties}->{$property} );
}

sub setAll {
  my util::Properties $this = shift;
  my ($hash_ref) = @_;
  foreach my $property ( keys %{$hash_ref} ) {
    $this->{properties}->{$property} = $hash_ref->{$property};
  }
}

sub getAllHash {
  my util::Properties $this = shift;
  my $hash_ref = {};
  foreach my $property ( $this->propertyNames ) {
    $hash_ref->{$property} = $this->getProperty($property);
  }
  return $hash_ref;
}

sub getAllStr {
  my util::Properties $this = shift;
  my (@exclusions)          = @_;
  my %exclusions            = ();
  foreach my $exclusion (@exclusions) {
    $exclusions{$exclusion} = util::Constants::EMPTY_STR;
  }
  my %property_names       = ();
  my $property_name_length = 0;
  foreach my $property ( $this->propertyNames ) {
    next if ( defined( $exclusions{$property} ) );
    $property_names{$property} = util::Constants::EMPTY_STR;
    next if ( $property_name_length >= length($property) );
    $property_name_length = length($property);
  }
  $property_name_length += 2;
  my $str = "Properties Listing:\n";
  foreach my $property ( sort keys %property_names ) {
    $str .=
        "  $property"
      . &util::Constants::SPACE x ( $property_name_length - length($property) )
      . " = "
      . $this->getProperty($property) . "\n";
  }
  return $str;
}

sub copy {
  my util::Properties $this = shift;
  my $copy_properties = new util::Properties;
  while ( my ( $property, $value ) = each %{ $this->{properties} } ) {
    $copy_properties->setProperty( $property, $value );
  }
  return $copy_properties;
}

sub store {
  my util::Properties $this = shift;
  my ($fh) = @_;
  foreach my $property ( sort keys %{ $this->{properties} } ) {
    my $value = $this->{properties}->{$property};
    $value =~ s/\n/\\\n/g;
    $fh->print("$property=$value\n");
  }
}

sub storeFile {
  my util::Properties $this = shift;
  my ($fn) = @_;
  $fn = getPath($fn);
  my $fh = new FileHandle;
  confess "Unsuccessful open to write properties file, $fn\n"
    if ( !$fh->open( $fn, '>' ) );
  $this->store($fh);
  $fh->close;
}

sub load {
  my util::Properties $this = shift;
  my ($fh)                  = @_;
  my $start_property        = util::Constants::TRUE;
  my $property;
  my $value;
  my $whitespace = util::Constants::WHITESPACE;
  my $row_num    = 0;
  while ( !$fh->eof ) {
    my $input_line = $fh->getline;
    chomp($input_line);
    $row_num++;
    if ($start_property) {
      next
        if ( $input_line eq util::Constants::EMPTY_STR
        || $input_line =~ /^$whitespace$/
        || $input_line =~ /^#/ );
      $start_property = ( $input_line !~ /\\$/ );
      $input_line =~ s/\\$//;
      if ( $input_line =~ /^(.+?)=(.*)$/ ) {
        $property = $1;
        $value    = $2;
      }
      else {
        confess "input_line ($row_num) = '$input_line' has incorrect format";
      }
    }
    else {
      $start_property = ( $input_line !~ /\\$/ );
      $input_line =~ s/\\$//;
      $value .= "\n" . $input_line;
    }
    if ($start_property) {
      $this->{properties}->{$property} = $value;
    }
  }
}

sub loadFile {
  my util::Properties $this = shift;
  my ($fn) = @_;
  $fn = getPath($fn);
  confess "File ($fn) does not exist or is inaccessible\n"
    if ( !-e $fn || !-f $fn || !-r $fn );
  my $fh = new FileHandle;
  confess "Unsuccessful read of properties file, $fn\n"
    if ( !$fh->open( $fn, '<' ) );
  $this->load($fh);
  $fh->close;
}

################################################################################

1;

__END__

=head1 NAME

Properties.pm

=head1 SYNOPSIS

   use util::Properties;

=head1 DESCRIPTION

This module defines the notion of a B<properties> file as an object with
a set of operational methods.  A B<property> is a (key, value)-pair that
is normally stored in a B<properties> file on a single line as the expression

   key=value

The key and value are assumed to be strings from the point-of-view of
this module.  If the value needs to be is a multi-line value, then the
line continuation character B<'\'> must appear at the end of line to
continue the value.  For example, if the following appears in the
B<properties> file

   list_key=list_item_1\
   list_item_2\
   list_item_3

then the value for the list_key is the multi-line value:

   list_item_1
   list_item_2
   list_itme_3

A B<propteries> file allows B<white-space> and B<comment> lines outside of 
(key, value)-pairs.  These lines are ignored.  B<white-space> are lines 
that are empty or composed of only blanks and horizontal format effectors.
A B<comment> is a line that begins with the character B<'#'>.  A line that
is not either B<white-space> or a B<comment> must be a (key, value)-pair
line or continuation line.  The following methods can be executed on
util::Properties objects.

=head1 METHODS

=head2 $obj = new util::Properties

This is the constructor for this module.  This method returns a new
util::Properties object with no properties defined.

=head2 $obj->clear

This method removes all properties from the object leaving it with
no properties.

=head2 $value = $obj->getProperty($proptery)

This method returns the current value for the property, $property.
If the property is not defined, then the value return is B<undef>.
String-based comparison is used to determine the property.

=head2 $boolean_value = $obj->isEmpty

This method returns the boolean value TRUE if there are no properties
defined for this object, otherwise it returns the boolean FALSE.

=head2 @names = $obj->propertyNames

This method return the current list of distinct property names defined by this
object.

=head2 $obj->setProperty($property, $value)

This method defines a (key, value)-pair where the property name is the
key and its value is the value.  If the property already exists in the
object, then this method will overwrite it.

=head2 $obj->remove($property)

This method removes the property, $property, from this object. String-based
comparison is used to identify the property.

=head2 $size = $obj->size

This method returns the number of distinct properties currently defined
by this object.

=head2 $boolean_value = $obj->containsProperty($property)

This method returns the boolean value TRUE if there a property, $property,
is currently defined the object, otherwise it returns the boolean FALSE.
String-based comparison is used to identify the property.

=head2 $obj->setAll($hash_ref)

This method effectively executes setProperty on each (key, value)-pair
contained in the hash table referenced by $hash_ref.

=head2 $hash_obj = $obj->getAllHash

This method returns a hash reference to a hash of all the properties.

=head2 $str = $obj->getAllStr([@exclusions])

This method returns a listing string of the current properties modulo
the exclusion properties.

=head2 $copy_obj = $obj->copy

This method creates a copy object of itself and returns this copy.  The copy
object hash all the same properties with corresponding values as the original
object.  The two objects (original and copy) are independent of one another.

=head2 $obj->store($fh)

This method takes a file-handle, $fh, and writes the corresponding
properties file for the object's current set of (key, value)-pairs
to the file-handle.  The file-handle can be created from FileHandle.

=head2 $obj->storeFile($fn)

This method takes a filename, $fn, and writes the corresponding
properties file for the object's current set of (key, value)-pairs
to the filename.

=head2 $obj->load($fh)

This method takes a file, $fh, and reads all the all the
(key, value)-pairs from the properties files identified by the
file-handle.  For each (key, value)-pair, this method has the 
same effect as the method setProperty.  The file-handle can be
created from FileHandle.

=head2 $obj->loadFile($fn)

This method takes a file, $fn, and reads all the all the
(key, value)-pairs from the properties files identified by the
file-name.  For each (key, value)-pair, this method has the 
same effect as the method setProperty.

=cut

