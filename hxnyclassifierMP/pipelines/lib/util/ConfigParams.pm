package util::ConfigParams;
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
use util::ErrMsgs;
use util::PathSpecifics;
use util::PerlObject;

use fields qw(
  error_mgr
  properties
  serializer
);

sub ERR_CAT { return util::ErrMsgs::CONFIGPARAMS_CAT; }

################################################################################
#
#				    Methods
#
################################################################################

sub new {
  my util::ConfigParams $this = shift;
  my ($error_mgr) = @_;
  $this = fields::new($this) unless ref($this);

  $this->{error_mgr}  = $error_mgr;
  $this->{properties} = {};
  $this->{serializer} =
    new util::PerlObject( undef, undef, $this->{error_mgr} );

  return $this;
}

sub clear {
  my util::ConfigParams $this = shift;
  my $properties = $this->{properties};
  foreach my $property ( keys %{ $this->{properties} } ) {
    delete( $properties->{$property} );
  }
}

sub getProperty {
  my util::ConfigParams $this = shift;
  my ($property) = @_;

  my $serializer = $this->{serializer};
  my $val        = $this->{properties}->{$property};
  my $rval       = ref($val);
  if ( $rval eq $serializer->HASH_TYPE || $rval eq $serializer->ARRAY_TYPE ) {
    my $vstr =
      $serializer->serializeObject( $val,
      $serializer->PERL_OBJECT_WRITE_OPTIONS );
    my $estr = '$val = ' . $vstr;
    eval $estr;
  }
  return $val;
}

sub getPropertyStr {
  my util::ConfigParams $this = shift;
  my ($property) = @_;

  my $serializer = $this->{serializer};
  my $val        = $this->{properties}->{$property};
  my $rval       = ref($val);
  if ( $rval eq $serializer->HASH_TYPE || $rval eq $serializer->ARRAY_TYPE ) {
    $val =
      $serializer->serializeObject( $val,
      $serializer->PERL_OBJECT_WRITE_OPTIONS );
  }
  return $val;
}

sub isEmpty {
  my util::ConfigParams $this = shift;
  my @properties = keys %{ $this->{properties} };
  return ( @properties == 0 );
}

sub propertyNames {
  my util::ConfigParams $this = shift;
  my @properties = keys %{ $this->{properties} };
  return @properties;
}

sub setProperty {
  my util::ConfigParams $this = shift;
  my ( $property, $value ) = @_;
  $this->{properties}->{$property} = $value;
}

sub remove {
  my util::ConfigParams $this = shift;
  my ($property) = @_;

  my $properties = $this->{properties};
  delete( $properties->{$property} );
}

sub size {
  my util::ConfigParams $this = shift;
  my @properties = keys %{ $this->{properties} };
  return $#properties + 1;
}

sub containsProperty {
  my util::ConfigParams $this = shift;
  my ($property) = @_;
  return exists( $this->{properties}->{$property} );
}

sub setAll {
  my util::ConfigParams $this = shift;
  my ($hash_ref) = @_;
  foreach my $property ( keys %{$hash_ref} ) {
    $this->{properties}->{$property} = $hash_ref->{$property};
  }
}

sub getAllHash {
  my util::ConfigParams $this = shift;
  my $hash_ref = {};
  foreach my $property ( $this->propertyNames ) {
    $hash_ref->{$property} = $this->getProperty($property);
  }
  return $hash_ref;
}

sub getAllStr {
  my util::ConfigParams $this = shift;
  my (@exclusions) = @_;

  my %exclusions = ();
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
      . " = ";
    my @comps = split( /\n/, $this->getPropertyStr($property) );
    if ( scalar @comps == 1 ) { $str .= $comps[0] . "\n"; }
    else {
      $str .= join(
        "\n" . &util::Constants::SPACE x ( $property_name_length + 4 ),
        @comps
      ) . "\n";
    }
  }
  return $str;
}

sub copy {
  my util::ConfigParams $this = shift;
  my $copy_properties = new util::ConfigParams( $this->{error_mgr} );
  foreach my $property ( keys %{ $this->{properties} } ) {
    my $value = $this->getProperty($property);
    $copy_properties->setProperty( $property, $value );
  }
  return $copy_properties;
}

sub storeFile {
  my util::ConfigParams $this = shift;
  my ($fn) = @_;
  $fn = getPath($fn);
  $this->{error_mgr}
    ->exitProgram( ERR_CAT, 3, [$fn], -e $fn && ( !-f $fn || !-w $fn ) );
  unlink($fn) if ( -e $fn );
  my $serializer = new util::PerlObject( $fn, undef, $this->{error_mgr} );
  $serializer->writeStream( $this->{properties},
    $serializer->PERL_OBJECT_WRITE_OPTIONS );
  $serializer->closeIo;
}

sub loadFile {
  my util::ConfigParams $this = shift;
  my ($fn) = @_;
  $fn = getPath($fn);
  $this->{error_mgr}
    ->exitProgram( ERR_CAT, 1, [$fn], !-e $fn || !-f $fn || !-r $fn );
  my $serializer = new util::PerlObject( $fn, O_RDONLY, $this->{error_mgr} );
  my $properties = $serializer->readAsObject;
  $serializer->closeIo;
  $this->{error_mgr}->exitProgram( ERR_CAT, 2, [$fn],
    !defined($properties) || ref($properties) ne $serializer->HASH_TYPE );
  $this->{properties} = $properties;
}

sub configModule {
  my util::ConfigParams $this = shift;
  my ($cm) = @_;

  my $serializer = $this->{serializer};
  my @eval_array =
    ( 'use ' . $cm, '$properties = \%' . $cm . '::configParams' );
  my $eval_str = join( util::Constants::SEMI_COLON, @eval_array );
  my $properties = undef;
  eval $eval_str;
  my $status = $?;
  my $rval   = ref($properties);
  $this->{error_mgr}->exitProgram(
    ERR_CAT, 4,
    [ $cm, $status, $rval ],
    ( defined($status) && $status ) || $rval ne $serializer->HASH_TYPE
  );
  my $pstr =
    $serializer->serializeObject( $properties,
    $serializer->PERL_OBJECT_WRITE_OPTIONS );
  my $estr = '$this->{properties} = ' . $pstr;
  eval $estr;
}

################################################################################

1;

__END__

=head1 NAME

Properties.pm

=head1 SYNOPSIS

   use util::ConfigParams;

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
util::ConfigParams objects.

=head1 METHODS

=head2 $obj = new util::ConfigParams(error_mgr)

This is the constructor for this module.  This method returns a new
util::ConfigParams object with no properties defined.

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
