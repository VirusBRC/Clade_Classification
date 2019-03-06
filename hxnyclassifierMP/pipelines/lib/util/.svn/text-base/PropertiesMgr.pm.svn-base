package util::PropertiesMgr;
################################################################################
#
#				Required Modules
#
################################################################################

use strict;

use Pod::Usage;

use util::Constants;
use util::Msg;
use util::PathSpecifics;
use util::Properties;

use fields qw(
  defaults
  msg
  properties
  tools
  tools_properties
);

################################################################################
#
#				   Constants
#
################################################################################

sub PROPERTY_SPACE_TOOL { return 'Property_Space'; }

################################################################################
#
#				 Static Methods
#
################################################################################

sub getToolProperty {
  my ($tool_property) = @_;
  $tool_property =~ /^(.+)\.(.+)$/;
  return ( $1, $2 );
}

################################################################################
#
#			       Private Properties
#
################################################################################

sub getToolProperties {
  my util::PropertiesMgr $this = shift;
  my ($tool) = @_;
  my $properties;
  if ( defined($tool) ) {
    $properties = $this->{tools_properties}->{$tool};
    $this->{msg}->dieOnError( "Tool not defined\n" . "  tool = $tool",
      !defined($properties) );
  }
  else {
    $properties = $this->{properties};
  }
  return $properties;
}

sub testProperty {
  my util::PropertiesMgr $this = shift;
  my ( $property, $tool ) = @_;
  my $properties = $this->getToolProperties($tool);
  $this->{msg}->dieOnError(
    "Property for tool not defined\n"
      . "  tool     = $tool\n"
      . "  property = $property",
    !$properties->containsProperty($property)
  );
}

sub readProperties {
  my util::PropertiesMgr $this = shift;
  my ($file)                   = @_;
  my $properties               = new util::Properties;
  eval { $properties->loadFile($file); };
  my $status = $@;
  $this->{msg}->dieOnError(
    "Cannot obtain properties:\n" . "  file   = $file\n" . "  errMsg = $status",
    defined($status) && $status
  );
  return $properties;
}

################################################################################
#
#				    Methods
#
################################################################################

sub new {
  my util::PropertiesMgr $this = shift;
  my ( $defaults_properties_file, $tools_properties_file, $msg ) = @_;
  $this = fields::new($this) unless ref($this);
  ###
  ### Check msg object
  ###
  $this->{msg} = $msg;
  if ( !defined( $this->{msg} ) || !ref( $this->{msg} ) ) {
    $this->{msg} = new util::Msg;
  }
  ###
  ### Create attributes
  ###
  $this->{defaults}         = $this->readProperties($defaults_properties_file);
  $this->{properties}       = $this->{defaults}->copy;
  $this->{tools}            = $this->readProperties($tools_properties_file);
  $this->{tools_properties} = {};
  ###
  ### Now establish the set of tools
  ###
  foreach my $tool_property ( $this->{tools}->propertyNames ) {
    my ( $tool_name, $property ) = getToolProperty($tool_property);
    next if ( defined( $this->{tools_properties}->{$tool_name} ) );
    $this->{tools_properties}->{$tool_name} = new util::Properties;
  }
  return $this;
}

sub resetProperties {
  my util::PropertiesMgr $this = shift;
  $this->{properties}->clear;
  $this->{properties} = $this->{defaults}->copy;
  foreach my $tool ( keys %{ $this->{tools_properties} } ) {
    $this->{tools_properties}->{$tool}->clear;
  }
}

sub createProperties {
  my util::PropertiesMgr $this = shift;
  my ($tool) = @_;
  $this->{msg}
    ->dieOnError( "createProperties:  Undefined Tool", !defined($tool) );
  my $properties = $this->getToolProperties($tool);
  $properties->clear;
  foreach my $tool_property ( $this->{tools}->propertyNames ) {
    my ( $tool_name, $property ) = getToolProperty($tool_property);
    next if ( $tool ne $tool_name );
    $this->{msg}->dieOnError(
      "Cannot find property value for tool\n"
        . "  tool     = $tool\n"
        . "  property = $property",
      !$this->{properties}->containsProperty($property)
    );
    $properties->setProperty( $property,
      $this->{properties}->getProperty($property) );
  }
}

sub getTools {
  my util::PropertiesMgr $this = shift;
  return sort keys %{ $this->{tools_properties} };
}

sub propertyNames {
  my util::PropertiesMgr $this = shift;
  my ($tool)                   = @_;
  my $properties               = $this->getToolProperties($tool);
  return $properties->propertyNames;
}

sub getProperty {
  my util::PropertiesMgr $this = shift;
  my ( $property, $tool ) = @_;
  $this->testProperty( $property, $tool );
  my $properties = $this->getToolProperties($tool);
  return $properties->getProperty($property);
}

sub getDefaultProperty {
  my util::PropertiesMgr $this = shift;
  my ($property) = @_;
  $this->{msg}->dieOnError(
    "Default property does not exist\n" . "  property = $property",
    !$this->{defaults}->containsProperty($property) );
  return $this->{defaults}->getProperty($property);
}

sub setProperty {
  my util::PropertiesMgr $this = shift;
  my ( $property, $value, $tool ) = @_;
  $this->testProperty( $property, $tool );
  my $properties = $this->getToolProperties($tool);
  $properties->setProperty( $property, $value );
}

sub setDefaultProperty {
  my util::PropertiesMgr $this = shift;
  my ( $property, $tool ) = @_;
  $this->testProperty( $property, $tool );
  my $properties = $this->getToolProperties($tool);
  $properties->setProperty( $property, $this->getDefaultProperty($property) );
}

sub transferProperty {
  my util::PropertiesMgr $this = shift;
  my ( $property, $to_tool, $from_tool ) = @_;
  $this->{msg}->dieOnError( "transferProperty:  to_tool is undefined",
    !defined($to_tool) );
  my $from_properties = $this->getToolProperties($from_tool);
  my $to_properties   = $this->getToolProperties($to_tool);
  if ( $from_properties->containsProperty($property)
    && $to_properties->containsProperty($property) )
  {
    $this->setProperty( $property, $this->getProperty( $property, $from_tool ),
      $to_tool );
  }
}

sub transferAllProperties {
  my util::PropertiesMgr $this = shift;
  my ( $to_tool, $from_tool ) = @_;
  my $to_properties = $this->getToolProperties($to_tool);
  foreach my $property ( $this->propertyNames($from_tool) ) {
    $this->transferProperty( $property, $to_tool, $from_tool );
  }
}

sub loadProperties {
  my util::PropertiesMgr $this = shift;
  my ($file)                   = @_;
  my $properties               = $this->getToolProperties();
  my $file_properties          = $this->readProperties($file);
  foreach my $property ( $file_properties->propertyNames ) {
    next if ( !$properties->containsProperty($property) );
    $properties->setProperty( $property,
      $file_properties->getProperty($property) );
  }
}

sub storeProperties {
  my util::PropertiesMgr $this = shift;
  my ( $dir, $tool ) = @_;
  my $properties = $this->getToolProperties($tool);
  $this->{msg}->dieOnError(
    "No properties are defined for the Tool\n"
      . "  tool = $tool\n"
      . "  dir  = $dir",
    $properties->isEmpty
  );
  $tool = PROPERTY_SPACE_TOOL if ( !defined($tool) );
  my $file = join( util::Constants::SLASH,
    $dir, join( util::Constants::DOT, $tool, 'properties' ) );

  eval { $properties->storeFile($file); };
  my $status = $@;
  $this->{msg}->dieOnError(
    "Cannot write properties:\n" . "  file   = $file\n" . "  errMsg = $@",
    defined($status) && $status );
  return $file;
}

sub getListing {
  my util::PropertiesMgr $this = shift;
  my ($tool)                   = @_;
  my $properties               = $this->getToolProperties($tool);
  $this->{msg}->dieOnError(
    "No properties are defined for the Tool\n" . "  tool = $tool\n",
    $properties->isEmpty );
  $tool = PROPERTY_SPACE_TOOL if ( !defined($tool) );
  return "$tool Tool Properties:\n" . $properties->getAllStr;
}

################################################################################

1;

__END__

=head1 NAME

PropertiesMgr.pm

=head1 SYNOPSIS

   use util::PropertiesMgr;

=head1 DESCRIPTION

This module defines a class to manage the properties (util::Properties) for a
set of related tools.  It depends on two properties files:
default_properties_file and tools_properties_file.  The former properties file
contains a global list of all properties for the toolset with their default
values (which may be undef).  The latter properties file contains the list of
properties for each tool.  That is, each property name in the tools properties file is of the form,
B<tool.property_name>, where as the property name in the defaults properties
file is B<property_name>.  The value of the properties in the tools properties
file is ignored.  Objects of this class maintain the global set of properties 
(initialized to their default values) called the property space.

The global property space maintains two values for each property - the original default value which is
never changed, and a current value.  When a tool property space is created from the
global property space, its properties inherit the current values of the property space properties,
not the default values.

To make use of both default and current values of the global property space, methods exist to

=over 4

=item *

Copy default property values in the global property space to current values in the global property
space (a reset of the current value to the default) - setDefaultProperty

=item *

Transfer a default property value from the global property space to the property space of a tool - setDefaultProperty

=item *

Transfer a current property value from the global property space to the property space of a tool - transferProperty

=back

=head1 METHODS

The following methods are defined for this class.  If a tool is optional in a 
method, then this means that the property space is used.

=head2 B<new util::PropertiesMgr(defaults_properties_file, tools_properties_file[, msg])>

This method is the constructor for the class.  It takes the two files
and creates the properties for these two properties file.  Any error
in generating the properties will cause the program to terminate
abnormally.  It then initializes the property space with the default
values.  Finally, it creates the set of tools properties
(un-evaluated--empty properties).  This class takes an optional
messaging object B<msg>.  If one is not provided, it creates a default
one to use.

=head2 $obj->resetProperties

This method re-initializes the object to its state just after it was 
instantiated by the new method.  

=head2 $obj->createProperties(tool)

This method creates the tools properties assigning them their values from the 
current state of the property space.  If any
tool property does not have a value, then program will terminate abnormally.
This method must be executed on a tool in order to use the getProperty and
setProperty methods.  Re-executing this method causes the tool's properties to
be re-initialized with the current state of the property space.

=head2 $obj->getTools

This method returns a sorted list of the tools in the toolset.

=head2 $obj->propertyNames([tool])

This method returns the list of properties for a tool in the toolset.  If this
method is executed prior to executing createProperties, then the set of property
names will be empty.  If the tool is not defined (undef) or not provided, then the
names of all properties for the property space are returned.

=head2 $obj->getProperty(property[, tool])

This method returns the current value of the property for a given tool.  The
program will terminate abnormally if the tool is not part of the toolset.  
If the tool is undefined
or not provided, then it returns the value for the property from the property
space.  It is also an error to request a property not defined in the property space.

=head2 $obj->getDefaultProperty(property)

This method returns the default value of a property.  If the property does not
exist, then the program terminates abnormally.

=head2 $obj->setProperty(property, value[, tool])

This method sets the value of a property for a tool.  The program will terminate
abnormally if the tool is not part of the toolset or the property is not defined
for the tool.  If the tool is undefined or not provided, then this method
sets the property in the property space.  It is also an error to set the value of a
property not defined in the property space.

=head2 $obj->setDefaultProperty(property[, tool])

This method sets the value of a property for a tool to the default value.
The program will terminate abnormally if the tool is not part of the toolset
or the property is not defined for the tool.  If the tool is undefined or not
provided, then this method sets the property in the property space.  It is also
an error to set the value of a property not defined in the property space.

=head2 $obj->transferProperty(property, to_tool[, from_tool])

This method assigns the value of the property in from_tool to the property 
in to_tool.  If the property is not in both tools, then no assignment takes place.
The to_tool must be defined.  If from_tool is not defined or not provided, then
the from-property is in the property space.

=head2 $obj->transferAllProperties(to_tool[, from_tool])

This method assigns the value of each property in from_tool to the value of the
corresponding property in to_tool.  If a property in from_tool is not in to_tool,
then no assignment takes place.  The from_tool can be undefined or not provided.  
In this case, it is the property space.

=head2 $obj->loadProperties(file)

This method will cause the properties in the property space to be updated by the
properties in the properties file.  Any property in the properties file that is not 
defined in the property space will be ignored.

=head2 $obj->storeProperties(dir[, tool])

This method will write the current set of values for a tool to a properties
file:

   <dir>/<tool>.properties

It is an error (terminate abnormally) for the properties of the tool not
to be evaluated (i.e., createProperties must be executed previously for 
the tool).  If the tool is undefined or not provided, then the property space
is stored and the B<tool> name is 'Property_Space'.  This method returns the
name of the properties file that it has written.

=head2 $obj->getListing([tool])

This method generates the current listing of properties with values for the
given tool.  If the tool is undefined or not provided, then the listing is 
for the property space.  If the tool has not been created, then the program
will terminate abnormally.

=cut
