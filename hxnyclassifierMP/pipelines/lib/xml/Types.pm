package xml::Types;
################################################################################
#
#				Required Modules
#
################################################################################

use strict;

use Pod::Usage;

use util::Constants;

################################################################################
#
#				Constant Methods
#
################################################################################
###
### Undefined XML attribute or text-node values
### can be one of the following strings or an
### empty string or undefined
###
sub UNDEFINED_VALUE { return '(undef|NULL|null)'; }
###
### Xml Tokens
###
sub OPEN_XML_TAG      { return '<'; }
sub CLOSE_XML_TAG     { return '</'; }
sub END_XML_TAG       { return '>'; }
sub SHORT_END_XML_TAG { return '/>'; }
###
### Standize Block Size for reading XML-Files
###
sub STANDARD_BLOCK_SIZE { return 5000; }
###
### Standard File Suffix Pattern
###
sub XML_FILE_SUFFIX_PATTERN { return '\.(xml|nxml)(\.gz|\.Z)?'; }

sub ZIPPED_FILE_PATTERN { return '(\.gz|\.Z)$'; }
###
### File Types
###
sub GZIP_FILE_TYPE  { return 'gzip'; }
sub PLAIN_FILE_TYPE { return 'plain'; }
sub ZIP_FILE_TYPE   { return 'zip'; }
###
### Special File Infixes and Suffixes
###
sub FORMATED_FILE_INFIX { return 'formated'; }
sub MODIFIED_FILE_INFIX { return 'modified'; }
sub REDUCED_FILE_INFIX  { return 'reduced'; }

sub INDEX_FILE_SUFFIX { return 'idx'; }
sub XML_FILE_SUFFIX   { return 'xml'; }
sub FLAT_FILE_SUFFIX  { return 'txt'; }
###
### Temporary XML File
###
sub TEMP_FILE { return '_TMP_XML_TMP_' . &XML_FILE_SUFFIX; }
###
### Special Xml Tags
###
sub XML_TAG       { return 'xml_tag'; }
sub PROPERTY_TAG  { return 'property'; }
sub SUPER_XML_TAG { return 'super_xml_tag'; }
###
### Special Xml Attributes
###
sub NAME_ATTR  { return 'name'; }
sub VALUE_ATTR { return 'value'; }
###
### Standard Indentation
###
sub XML_INDENT { return util::Constants::SPACE . util::Constants::SPACE; }

################################################################################
#
#				 Static Methods
#
################################################################################

sub xmlFileRegularExpression {
  my ( $xml_prefix_pattern, $xml_suffix_pattern, $prefix_exact ) = @_;
  $prefix_exact =
    ( defined($prefix_exact) && $prefix_exact )
    ? util::Constants::TRUE
    : util::Constants::FALSE;
  my $xml_file_pattern = undef;
  if ( $xml_prefix_pattern eq util::Constants::EMPTY_STR ) {
    $xml_file_pattern = util::Constants::ANY_STR . $xml_suffix_pattern;
  }
  elsif ($prefix_exact) {
    $xml_file_pattern = $xml_prefix_pattern . $xml_suffix_pattern;
  }
  else {
    $xml_file_pattern =
        util::Constants::ANY_STR
      . $xml_prefix_pattern
      . util::Constants::ANY_STR
      . $xml_suffix_pattern;
  }
  return $xml_file_pattern;
}

sub escapeReplacement {
  my ($str_ref) = @_;
  $$str_ref =~ s/&/&amp;/g;
  $$str_ref =~ s/'/&apos;/g;
  $$str_ref =~ s/"/&quot;/g;
  $$str_ref =~ s/</&lt;/g;
  $$str_ref =~ s/>/&gt;/g;
}

sub getOpenTag {
  my ( $tag, $attributes, $tabs, $short_end ) = @_;
  $short_end =
    ( defined($short_end) && $short_end )
    ? util::Constants::TRUE
    : util::Constants::FALSE;
  my $open_tag = $tabs . OPEN_XML_TAG . $tag;
  if ( defined($attributes) && ref($attributes) eq 'HASH' ) {
    my @attr_array = ();
    while ( my ( $key, $value ) = each %{$attributes} ) {
      escapeReplacement( \$value );
      push( @attr_array,
            $key
          . util::Constants::EQUALS
          . util::Constants::QUOTE
          . $value
          . util::Constants::QUOTE );
    }
    if ( @attr_array > 0 ) {
      $open_tag .=
        util::Constants::SPACE . join( util::Constants::SPACE, @attr_array );
    }
  }
  if   ($short_end) { $open_tag .= SHORT_END_XML_TAG; }
  else              { $open_tag .= END_XML_TAG; }
  $open_tag .= util::Constants::NEWLINE;
  return $open_tag;
}

sub getCloseTag {
  my ( $tag, $tabs ) = @_;
  return $tabs . CLOSE_XML_TAG . $tag . END_XML_TAG . util::Constants::NEWLINE;

}

sub addXmlProperty {
  my ( $name, $value, $index ) = @_;
  ###
  ### First do the escape replacement on the value
  ### and add index to name if index is defined.
  ###
  escapeReplacement( \$value );
  if ( defined($index) ) { $name .= $index; }

  my $name_attribute = join( util::Constants::EMPTY_STR,
    NAME_ATTR, util::Constants::EQUALS, util::Constants::QUOTE, $name,
    util::Constants::QUOTE );
  my $value_attribute = join( util::Constants::EMPTY_STR,
    VALUE_ATTR, util::Constants::EQUALS, util::Constants::QUOTE, $value,
    util::Constants::QUOTE );
  return join( util::Constants::SPACE,
    OPEN_XML_TAG . PROPERTY_TAG,
    $name_attribute, $value_attribute . SHORT_END_XML_TAG
  );
}

sub addXmlTag {
  my ( $name, $value ) = @_;
  ###
  ### First do the escape replacement on the value
  ### and add index to name if index is defined.
  ###
  escapeReplacement( \$value );
  return ( OPEN_XML_TAG 
      . $name
      . END_XML_TAG
      . $value
      . CLOSE_XML_TAG
      . $name
      . END_XML_TAG );
}

################################################################################
#
#	   Constant Methods (dependent on getOpenTag and getCloseTag)
#
################################################################################
###
### Standard Xml Headers
###
sub OPEN_XML {
  return getOpenTag(
    XML_TAG,
    {
      version => "1.0",
      user    => "xml::Types",
    },
    util::Constants::EMPTY_STR
  );
}

sub CLOSE_XML {
  return getCloseTag( XML_TAG, util::Constants::EMPTY_STR );
}

sub OPEN_SUPER_XML {
  return getOpenTag(
    SUPER_XML_TAG,
    {
      version => "1.001",
      user    => "xml::Types",
    },
    util::Constants::EMPTY_STR
  );
}

sub CLOSE_SUPER_XML {
  return getCloseTag( SUPER_XML_TAG, util::Constants::EMPTY_STR );
}

################################################################################

1;

__END__

=head1 NAME

Types.pm

=head1 SYNOPSIS

   use xml::Types;

=head1 DESCRIPTION

This module export the static constant methods and static functions for
all the Xml Types used in Xml documents.

=head1 CLASS METHODS (CONSTANTS)

The following constants define the XML Tags:

   xml::Types::XML_TAG        -- xml_tag
   xml::Types::PROPERTY_TAG   -- property
   xml::Types::SUPER_XML_TAG  -- super_xml_tag

The following constants define the XML Attributes:

   xml::Types::NAME_ATTR   -- name
   xml::Types::VALUE_ATTR  -- value

The undefined value regular expression string:

   xml::Types::UNDEFINED_VALUE -- '(undef|NULL|null)'

The Xml Tokens for open and closing a tag:

   xml::Types::OPEN_XML_TAG      -- <
   xml::Types::CLOSE_XML_TAG     -- </
   xml::Types::END_XML_TAG       -- >
   xml::Types::SHORT_END_XML_TAG -- />

The following constant defines the standard xml-file suffix pattern and
the zipped file pattern:

   xml::Types::XML_FILE_SUFFIX_PATTERN -- '\.(xml|nxml)(\.gz|\.Z)?'
   xml::Types::ZIPPED_FILE_PATTERN     -- '(\.gz|\.Z)$'

The xml file types encountered:

   xml::Types::GZIP_FILE_TYPE  -- gzip
   xml::Types::PLAIN_FILE_TYPE -- plain

Special file infixes that are generated:

   xml::Types::FORMATED_FILE_INFIX -- formated
   xml::Types::INDEX_FILE_SUFFIX   -- idx
   xml::Types::MODIFIED_FILE_INFIX -- modified
   xml::Types::XML_FILE_SUFFIX     -- xml

The temp file name:

   xml::Types::TEMP_FILE -- _TMP_XML_TMP_.xml

The Standard Xml Headers:

   xml::Types::OPEN_XML
     -- <xml_tag version="1.001" user="xml::Types">
   xml::Types::OPEN_SUPER_XML
     -- <super_xml_tag version="1.001" user="xml::Types">

   xml::Types::CLOSE_XML       -- </xml_tag>
   xml::Types::CLOSE_SUPER_XML -- </super_xml_tag>

=head1 STATIC METHODS

The following static methods are provided for generating xml.

=head2 B<xml::Types::addXmlProperty(name, $value[, $index]))>

This method creates the short form of a B<property> tag containing the
B<name> and B<value> attributes.  This method applies escape replacement on
the value and also appends the index to the name if the index is
defined.

=head2 B<xml::Types::addXmlTag(name, $value)>

This method creates a simple xm-tag with a text-node as follows:

   <name>value</name>

=head2 B<xml::Types::xmlFileRegularExpression(xml_prefix_pattern, xml_suffix_pattern[, prefix_exact])>

This method generates a Perl regular expression for identifying
xml-files.  The xml_prefix_pattern and the xml_suffix_pattern
parameters are Perl regular expressions defining the prefix and suffix
of the xml-files to be found.  These parameters can be empty or
undefined (undef).  Note that this class exports a standard xml-suffix
regular expression pattern (XML_FILE_SUFFIX_PATTERN) that can be used
as a suffix pattern.  The optional parameter, prefix_exact (Boolean),
determines whether the prefix pattern is matched exactly at the
beginning of the filename.  If the prefix_exact is TRUE, then the
xml_prefix_pattern is matched exactly at the beginning of the
filename, otherwise otherwise (FALSE) it is not as described below.
If the prefix_exact is undefined or not provided, then it is assumed
to be FALSE.  The construction of the regular expression is determined
as follows:

   xml_file_pattern is empty_string -- *.<xml_suffix_pattern>
   prefix_exact is TRUE             -- <xml_prefix_pattern><xml_suffix_pattern>
   prefix_exact is FALSE            -- *.<xml_prefix_pattern>*.<xml_suffix_pattern>

=head2 B<xml::Types::escapeReplacement(str_ref)>

This method takes a reference to a string variable and performs the
standard xml escape replacement for it.  This needs to be done for
text-nodes and attribute-values that are to be written to xml-files.
The escaped characters include: '&', ''', '"', '<', and '>'.

=head2 B<xml::Types::getOpenTag(tag, attributes, tabs)>

This method generates a standard xml header and provides the formating
(tabs) in front of it and a new-line at the end of it.  If the
attributes parameter is defined and is a reference to a non-trivial
hash, then the attributes are included in the header.  This method
automatically does the escape replacement on the values of the
attributes (see B<escapeReplacement>).

=head2 B<xml::Types::getCloseTag(tag, tabs)>

This method generates a standard xml closing header for the tag
providing the formating (tabs) in front and a new-line at the end of
it.

=cut
