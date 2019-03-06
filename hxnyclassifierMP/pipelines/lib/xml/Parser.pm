package xml::Parser;
################################################################################
#
#				Required Modules
#
################################################################################

use strict;

use File::Basename;
use Pod::Usage;
use Pod::Usage;
use XML::Parser;

use util::Constants;
use util::FileTime;
use util::Msg;
use util::PathSpecifics;
use util::PerlObject;

use xml::ErrMsgs;
use xml::Types;

use fields qw(
  current_object
  error_mgr
  file
  force_array
  force_hash
  outer_element
  perl_object
  properties
  stack
  strip_whitespace
  retain_nodes
);

################################################################################
#
#				Initializations
#
################################################################################

sub ERR_CAT { return xml::ErrMsgs::PARSER_CAT; }

################################################################################
#
#				Constant Methods
#
################################################################################
###
### Special Perl Node Types
###
sub ATTRIBUTE_NODE { return '.Attr'; }
sub TEXT_NODE      { return '.Text'; }
###
### Force Types for creating special hash of a repeating sub-tag
### under tag either by element or attribute
###
sub FORCE_ATTRIBUTE { return 'attribute'; }
sub FORCE_ELEMENT   { return 'element'; }
###
### Components of a Force Hash
###
sub FORCE_KEY    { return 'key'; }
sub FORCE_SUBTAG { return 'subtag'; }
sub FORCE_TAG    { return 'tag'; }
sub FORCE_TYPE   { return 'type'; }
sub FORCE_VALUE  { return 'value'; }
###
### In forcing a hash, this allows several values for the
### same sub-tag with the same key name
###
sub MULTIPLE_VALUE_SEPARATOR { return '__XmlToPerl__'; }

################################################################################
#
#				Private Methods
#
################################################################################

sub _hasAttributeNode {
  my xml::Parser $this = shift;
  my ($object) = @_;
  return (
    defined( $object->{&ATTRIBUTE_NODE} )
    ? util::Constants::TRUE
    : util::Constants::FALSE
  );
}

sub _attributeNode {
  my xml::Parser $this = shift;
  my ($object) = @_;
  return $object->{&ATTRIBUTE_NODE};
}

sub _hasTextNode {
  my xml::Parser $this = shift;
  my ($object) = @_;
  return (
    defined( $object->{&TEXT_NODE} )
    ? util::Constants::TRUE
    : util::Constants::FALSE
  );
}

sub _textNode {
  my xml::Parser $this = shift;
  my ($object) = @_;
  return $object->{&TEXT_NODE};
}
###
### The private force hash methods
###
sub _forceHash {
  my xml::Parser $this = shift;
  my ( $force_type, $xml_element ) = @_;
  my $force_struct = $this->{force_hash}->{$force_type}->{$xml_element};
  return (
    $force_struct->{&FORCE_SUBTAG},
    $force_struct->{&FORCE_KEY},
    $force_struct->{&FORCE_VALUE}
  );
}

sub _forceHashAttribute {
  my xml::Parser $this = shift;
  my ( $object, $name ) = @_;
  ###
  ### Must be an attribute force hash
  ###
  return if ( !$this->forceHash( FORCE_ATTRIBUTE, $name ) );

  my ( $force_tag, $force_key, $force_value ) =
    $this->_forceHash( FORCE_ATTRIBUTE, $name );
  ###
  ### There must be an array of force tags
  ### otherwise remove it and return.
  ###
  my $force_tags = $object->{$force_tag};
  if ( ref($force_tags) ne util::PerlObject::ARRAY_TYPE ) {
    delete( $object->{$force_tag} );
    return;
  }
  my $forced_hash = {};
  foreach my $elem ( @{$force_tags} ) {
    ###
    ### element must have attributes with the
    ### appropriate key
    ###
    next if ( !$this->_hasAttributeNode($elem) );
    my $attributes = $this->_attributeNode($elem);
    my $key        = $attributes->{$force_key};
    my $value      = $attributes->{$force_value};
    next if ( util::Constants::EMPTY_LINE($key) );
    ###
    ### There are two cases:
    ### 1.  Nested structures of the force_tag are to be
    ###     lifted in a consistent manner into the Perl
    ###     structure
    ### 2.  Simple leaf structures.  In this case the key
    ###     is mapped to the value in the forced_hash.  If
    ###     there are several instances of the key, only the
    ###     last value will be retained (multiple values are
    ###     no longer catenated).
    ###
    ### It is an error have a must of the two cases for a
    ### key
    ###
    my $elem_force_tag = $elem->{$force_tag};
    if ( ref($elem_force_tag) eq util::PerlObject::HASH_TYPE ) {
      $forced_hash->{$key} = $elem_force_tag;
    }
    else {
      $this->{error_mgr}->exitProgram(
        ERR_CAT, 6,
        [ $name, $key, $force_tag, $force_key, $force_value ],
        ref( $forced_hash->{$key} )
      );
      $forced_hash->{$key} = $value;
    }
  }
  ###
  ### Add the forced_hash only if there is data,
  ### otherwise remove the force_tag for the object
  ###
  my @force_keys = keys %{$forced_hash};
  if ( @force_keys > 0 ) {
    $object->{$force_tag} = $forced_hash;
    $this->{properties}->{$force_tag} = FORCE_ATTRIBUTE;
  }
  else {
    delete( $object->{$force_tag} );
  }
}

sub _forceHashElement {
  my xml::Parser $this = shift;
  my ( $object, $name ) = @_;
  ###
  ### Must be an element force hash
  ###
  return if ( !$this->forceHash( FORCE_ELEMENT, $name ) );

  my ( $force_tag, $force_key, $force_value ) =
    $this->_forceHash( FORCE_ELEMENT, $name );
  ###
  ### There must be an array of force tags
  ### otherwise remove it and return.
  ###
  my $force_tags = $object->{$force_tag};
  if ( ref($force_tags) ne util::PerlObject::ARRAY_TYPE ) {
    delete( $object->{$force_tag} );
    return;
  }
  my $forced_hash = {};
  foreach my $elem ( @{$force_tags} ) {
    next if ( !defined( $elem->{$force_key} ) );
    $this->{error_mgr}->exitProgram(
      ERR_CAT, 7,
      [ $name, $force_tag, $force_key, $force_value ],
      ref( $elem->{$force_key} )
    );
    $forced_hash->{ $elem->{$force_key} } = $elem->{$force_value};
  }
  my @force_keys = keys %{$forced_hash};
  if ( @force_keys > 0 ) {
    $object->{$force_tag} = $forced_hash;
    $this->{properties}->{$force_tag} = FORCE_ELEMENT;
  }
  else {
    delete( $object->{$force_tag} );
  }
}
###
### The Xml to Perl methods xml::Parser call-backs
###
sub _handle_start {
  my xml::Parser $this = shift;
  return sub {
    my ( $expat, $name, %attr ) = @_;
    my $current_object = $this->{current_object};
    my $name_object    = {};
    ###
    ### Set the attribute-node:
    ### If the xml-element has an attribute-node (@attribute_keys
    ### is greater than 0), then the xml-element has as one of its
    ### keys ATTRIBUTE_NODE and its value is a reference to the
    ### attribute map.
    ###
    my @attribute_keys = keys %attr;
    if ( @attribute_keys > 0 ) {
      $name_object->{&ATTRIBUTE_NODE} = {%attr};
    }
    ###
    ### Determine how to add the name_object for the tag:
    ###
    ### 1.  The name is forced as an array:  Add the name
    ###     object as an array element to the name reference
    ###     (define the name reference as an array if it is
    ###     not yet defined)
    ### 2.  The name is not forced as an array but the name
    ###     reference already exists:  If the name reference
    ###     is an array, then add name object as an array element.
    ###     Otherwise, create an array reference for the name and
    ###     make the existing name reference the first element
    ###     and the current name object the second element of this
    ###     array.
    ### 3.  The name reference does not yet exist and is not
    ###     forced as an array:  Add the name object (hash)
    ###     directly as the name reference.
    ###
    if ( $this->forceArray($name)
      && !defined( $current_object->{$name} ) )
    {
      $current_object->{$name} = [];
    }
    my $name_ref      = $current_object->{$name};
    my $name_ref_type = ref($name_ref);
    if ($name_ref_type) {
      $this->{error_mgr}->exitProgram( ERR_CAT, 8, [ $name, $name_ref_type ],
             $name_ref_type ne util::PerlObject::ARRAY_TYPE
          && $name_ref_type ne util::PerlObject::HASH_TYPE );
      if ( $name_ref_type eq util::PerlObject::ARRAY_TYPE ) {
        push( @{$name_ref}, $name_object );
      }
      else {
        delete( $current_object->{$name} );
        $current_object->{$name} = [ $name_ref, $name_object ];
      }
    }
    else {    ### nothing defined ###
      $current_object->{$name} = $name_object;
    }
    ###
    ### Now ready to process sub-tags under name:
    ### 1.  push current_object onto stack
    ### 2.  Make the name object the current_object
    ###
    push( @{ $this->{stack} }, $current_object );
    $this->{current_object} = $name_object;
    }
}

sub _handle_end {
  my xml::Parser $this = shift;
  return sub {
    my ( $expat, $name ) = @_;
    my $current_object = $this->{current_object};
    my $current_ref    = ref($current_object);
    my $retain_nodes   = $this->{retain_nodes};
    ###
    ### It is an error for the current_object
    ### not to be a hash!
    ###
    $this->{error_mgr}->exitProgram(
      ERR_CAT, 9,
      [ $name, $current_ref ],
      $current_ref ne util::PerlObject::HASH_TYPE
    );
    ###
    ### Get rid of trailing white-space in the text-node
    ###
    if ( $this->{strip_whitespace}
      && $this->_hasTextNode($current_object) )
    {
      $current_object->{&TEXT_NODE} =~ s/\s+$//;
    }

    my @current_keys = keys %{$current_object};
    ###
    ### Special Case 1a:
    ### If the name current_object has no content and it
    ### is specified to be retained, then make a text
    ### node that is an empty string and process it as
    ### normal
    if ( @current_keys == 0 && defined( $retain_nodes->{$name} ) ) {
      $current_object->{&TEXT_NODE} = util::Constants::EMPTY_STR;
    }
    ###
    ### Special Case 1b:
    ###
    ### If an xml-element name has NO attribute-node (ATTRIBUTE_NODE is
    ### not defined), the xml-element has a text-node (TEXT_NODE is
    ### defined), and there are no other elements (current_keys == 1),
    ### then Special Case 1 processing is performed and an immediate
    ### return is then executed.
    ###
    @current_keys = keys %{$current_object};
    if (!$this->_hasAttributeNode($current_object)
      && $this->_hasTextNode($current_object)
      && @current_keys == 1 )
    {
      ###
      ### Make the top of the stack the current_object and return
      ### immediately after special case processing below.
      ###
      $this->{current_object} = pop( @{ $this->{stack} } );
      my $value = $this->_textNode($current_object);
      if ( $this->forceArray($name) ) {
        ###
        ### Special Case 1a:
        ### Moreover, if the name is force as an array, then the name is
        ### mapped directly in its parent to an array of simple (text-node)
        ### elements.  If the name is undefined or not an array, this is
        ### an error.  Note that the text node struct will currently be
        ### in the array as the last element and must be removed before
        ### the value is added into the array.
        ###
        my $name_ref = $this->{current_object}->{$name};
        if ( !defined($name_ref) ) {
          $this->{error_mgr}->exitProgram( ERR_CAT, 10, [ $name, $value ],
            util::Constants::TRUE );
        }
        elsif ( ref($name_ref) eq util::PerlObject::ARRAY_TYPE ) {
          pop( @{$name_ref} );
          push( @{$name_ref}, $value );
        }
        else {
          $this->{error_mgr}->exitProgram( ERR_CAT, 11, [ $name, $value ],
            util::Constants::TRUE );
        }
      }
      else {
        ###
        ### Special Case 1b:
        ### Moreover, if the name is not force as an array, then the
        ### xml-element name is mapped directly to its text-node in
        ### its parent.  That is, the hash key is the xml-element name
        ### and the value is the text-node.
        ###
        $this->{current_object}->{$name} = $value;
      }
      return;
    }
    ###
    ### Special Case 2:
    ### If Force Hash is in effect for the name current_object,
    ### then process it into a hash.
    ###
    $this->_forceHashAttribute( $current_object, $name );
    $this->_forceHashElement( $current_object, $name );
    ###
    ### Special Case 3:
    ### If the name current_object has no content, then
    ### delete it from its parent if there are no others
    ### of this name already in the parent.  Make the
    ### top of the stack the current_object and return.
    ###
    @current_keys = keys %{$current_object};
    if ( @current_keys == 0 ) {
      $this->{current_object} = pop( @{ $this->{stack} } );
      my $name_ref = $this->{current_object}->{$name};
      if ( ref($name_ref) eq util::PerlObject::ARRAY_TYPE ) {
        pop( @{$name_ref} );
        if ( @{$name_ref} == 0 ) {
          delete( $this->{current_object}->{$name} );
        }
      }
      else {
        delete( $this->{current_object}->{$name} );
      }
      return;
    }
    ###
    ### Finally, make the top of the
    ### stack the current_object
    ###
    $this->{current_object} = pop( @{ $this->{stack} } );
    }
}

sub _handle_char {
  my xml::Parser $this = shift;
  return sub {
    my ( $expat, $string ) = @_;
    ###
    ### if the xml-element has a text-node, then TEXT_NODE will be
    ### defined as one of the hash keys for the current_object.  That
    ### one of its keys is TEXT_NODE and its values is the value of
    ### the text-node.
    ###
    my $current_object = $this->{current_object};
    if ( $this->{strip_whitespace} ) {
      ###
      ### Strip leading tabs and whitespace BUT NOT SPACES!
      ###
      ### Note that in processing the text-node the character
      ### string is broken at new-line and as a result the
      ### stripping operation below removes extraneous formating
      ### characters that are not part of the document at the
      ### potential beginning and the end of a line.
      ###
      $string =~ s/^\t+//;
      $string =~ s/[\t\n\r\f]+$//;
    }
    if ( $this->_hasTextNode($current_object) ) {
      $current_object->{&TEXT_NODE} .= $string;
    }
    elsif ( $string =~ /\S/ ) {
      ###
      ### Get rid of initial white-space in the text-node
      ###
      if ( $this->{strip_whitespace} ) { $string =~ s/^\s+//; }
      $current_object->{&TEXT_NODE} = $string;
    }
    }
}

sub _toPerl {
  my xml::Parser $this = shift;
  ###
  ### Initialize the parse:
  ### 1.  Initialize the perl_object
  ### 2.  Set the current_object to the perl_object
  ### 3.  Set the parsing stack to empty
  ### 4.  Initialize the list of properties encounterd
  ###     by force_hash
  ###
  $this->{perl_object}    = {};
  $this->{current_object} = $this->{perl_object};
  $this->{stack}          = [];
  $this->{properties}     = {};
  ###
  ### Create the xml parser
  ###
  my $xml_parser = new XML::Parser(
    Handlers => {
      Start => $this->_handle_start,
      End   => $this->_handle_end,
      Char  => $this->_handle_char,
    },
    ProtocolEncoding => 'ISO-8859-1'
  );
  ###
  ### Open the xml_file
  ###
  my $file = $this->sourceFile;
  if ( $file =~ /(\.gz|\.Z)$/ ) {
    $this->{error_mgr}->exitProgram( ERR_CAT, 12, [$file],
      !open( XML_INPUT, 'gunzip -c ' . $file . ' |' ) );
  }
  else {
    $this->{error_mgr}
      ->exitProgram( ERR_CAT, 12, [$file], !open( XML_INPUT, '<' . $file ) );
  }
  ###
  ### Parse the xml-document
  ###
  my $data        = util::Constants::EMPTY_STR;
  my $xml_parsing = $xml_parser->parse_start;
  ###
  ### If the outer_element is default tag,
  ### then explicitly add header
  ###
  if ( $this->defaultOuterElement ) {
    $xml_parsing->parse_more(xml::Types::OPEN_SUPER_XML);
  }
  ###
  ### Parse the file contents
  ###
  while ( read( XML_INPUT, $data, xml::Types::STANDARD_BLOCK_SIZE ) ) {
    $xml_parsing->parse_more($data);
  }
  ###
  ### If the outer_element is default tag,
  ### then must explicitly add close header
  ###
  if ( $this->defaultOuterElement ) {
    $xml_parsing->parse_more(xml::Types::CLOSE_SUPER_XML);
  }
  ###
  ### Finish parsing
  ###
  $xml_parsing->parse_done;
  close(XML_INPUT);
}

sub _getSubObjs {
  my xml::Parser $this = shift;
  my ( $objects, $parent, $comp, $path ) = @_;
  ###
  ### End condition
  ###
  return if ( !ref($parent) );
  if ( scalar @{$path} == 0 ) {
    if ( ref($parent) eq 'HASH' ) {
      my $object = $parent->{$comp};
      push( @{$objects}, $object );
    }
    elsif ( ref($parent) eq 'ARRAY' ) {
      foreach my $sub_obj ( @{$parent} ) {
        next if ( !ref($sub_obj) );
        my $object = $sub_obj->{$comp};
        push( @{$objects}, $object );
      }
    }
    return;
  }
  ###
  ### Recursive Step
  ###
  my $sub_path = [ @{$path} ];
  my $sub_comp = shift( @{$sub_path} );
  if ( ref($parent) eq 'HASH' ) {
    my $object = $parent->{$comp};
    $this->_getSubObjs( $objects, $object, $sub_comp, $sub_path );
  }
  elsif ( ref($parent) eq 'ARRAY' ) {
    foreach my $sub_obj ( @{$parent} ) {
      next if ( !ref($sub_obj) );
      my $object = $sub_obj->{$comp};
      $this->_getSubObjs( $objects, $object, $sub_comp, $sub_path );
    }
  }
}

################################################################################
#
#				    Methods
#
################################################################################

sub new {
  my xml::Parser $this = shift;
  my ( $main_tag, $force_tags, $error_mgr ) = @_;
  $this = fields::new($this) unless ref($this);

  $this->{current_object}   = undef;
  $this->{file}             = undef;
  $this->{force_array}      = undef;
  $this->{force_hash}       = undef;
  $this->{error_mgr}        = $error_mgr;
  $this->{outer_element}    = undef;
  $this->{perl_object}      = undef;
  $this->{properties}       = undef;
  $this->{retain_nodes}     = {};
  $this->{stack}            = undef;
  $this->{strip_whitespace} = undef;
  ###
  ### Set the outer element
  ###
  $this->setOuterElement($main_tag);
  ###
  ### Set stripping of white space
  ###
  $this->setStripWhitespace;
  ###
  ### Initialize Forcing and initialize forced arrays, if necessary
  ###
  $this->initializeForce;
  if ( !util::Constants::EMPTY_LINE($force_tags)
    && ref($force_tags) eq util::PerlObject::ARRAY_TYPE )
  {
    foreach my $tag ( @{$force_tags} ) {
      $this->setForceArray( $tag, util::Constants::TRUE );
    }
  }
  ###
  ### Object ready to be returned
  ###
  return $this;
}

sub initializeForce {
  my xml::Parser $this = shift;
  $this->{force_array} = {};
  $this->{force_hash}  = {
    &FORCE_ATTRIBUTE => {},
    &FORCE_ELEMENT   => {},
  };
}

sub setRetainNode {
  my xml::Parser $this = shift;
  my ( $xml_element, $retain_status ) = @_;
  return if ( util::Constants::EMPTY_LINE($xml_element) );
  my $retain_nodes = $this->{retain_nodes};
  $retain_status =
    ( defined($retain_status) && $retain_status )
    ? util::Constants::TRUE
    : util::Constants::FALSE;
  if ($retain_status) {
    $retain_nodes->{$xml_element} = util::Constants::EMPTY_STR;
  }
  elsif ( defined( $retain_nodes->{$xml_element} ) ) {
    delete( $retain_nodes->{$xml_element} );
  }
}

sub setForceArray {
  my xml::Parser $this = shift;
  my ( $xml_element, $force_status ) = @_;
  return if ( util::Constants::EMPTY_LINE($xml_element) );
  $this->{force_array}->{$xml_element} =
    ( defined($force_status) && $force_status )
    ? util::Constants::TRUE
    : util::Constants::FALSE;
}

sub forceArray {
  my xml::Parser $this = shift;
  my ($xml_element) = @_;
  return (
    defined( $this->{force_array}->{$xml_element} )
    ? $this->{force_array}->{$xml_element}
    : util::Constants::FALSE
  );
}

sub setForceHashes {
  my xml::Parser $this = shift;
  my ($force_hashes) = @_;
  return
    if ( util::Constants::EMPTY_LINE
    || ref($force_hashes) ne util::PerlObject::HASH_TYPE );
  foreach my $force_hash ( @{$force_hashes} ) {
    $this->setForceHash(
      $force_hash->{&FORCE_TYPE},   $force_hash->{&FORCE_TAG},
      $force_hash->{&FORCE_SUBTAG}, $force_hash->{&FORCE_KEY},
      $force_hash->{&FORCE_VALUE}
    );
  }
}

sub setForceHash {
  my xml::Parser $this = shift;
  my ( $force_type, $xml_element, $xml_subelement, $key_element,
    $value_element ) = @_;
  $this->{error_mgr}->exitProgram( ERR_CAT, 13, [$force_type],
    util::Constants::EMPTY_LINE($force_type) || ( $force_type ne FORCE_ELEMENT
      && $force_type ne FORCE_ATTRIBUTE ) );
  return if ( util::Constants::EMPTY_LINE($xml_element) );
  if ( !defined($xml_subelement) ) {
    delete( $this->{force_hash}->{$force_type}->{$xml_element} );
  }
  else {
    my $force_struct = {
      &FORCE_SUBTAG => $xml_subelement,
      &FORCE_KEY    => $key_element,
      &FORCE_VALUE  => $value_element,
    };
    $this->{force_hash}->{$force_type}->{$xml_element} = $force_struct;
    $this->setForceArray( $xml_subelement, util::Constants::TRUE );
  }
}

sub forceHash {
  my xml::Parser $this = shift;
  my ( $force_type, $xml_element ) = @_;
  return (
    (
           defined( $this->{force_hash}->{$force_type} )
        && defined( $this->{force_hash}->{$force_type}->{$xml_element} )
    ) ? util::Constants::TRUE : util::Constants::FALSE
  );
}

sub setStripWhitespace {
  my xml::Parser $this = shift;
  $this->{strip_whitespace} = util::Constants::TRUE;
}

sub unsetStripWhitespace {
  my xml::Parser $this = shift;
  $this->{strip_whitespace} = util::Constants::FALSE;
}

sub setOuterElement {
  my xml::Parser $this = shift;
  my ($outer_element) = @_;
  $this->{outer_element} =
    util::Constants::EMPTY_LINE($outer_element)
    ? xml::Types::SUPER_XML_TAG
    : $outer_element;
}

sub outerElement {
  my xml::Parser $this = shift;
  return $this->{outer_element};
}

sub sourceFile {
  my xml::Parser $this = shift;
  return $this->{file};
}

sub defaultOuterElement {
  my xml::Parser $this = shift;
  return (
    ( $this->outerElement eq xml::Types::SUPER_XML_TAG )
    ? util::Constants::TRUE
    : util::Constants::FALSE
  );
}

sub parse {
  my xml::Parser $this = shift;
  my ($source_file) = @_;
  $this->{file} = getPath($source_file);
  eval { $this->_toPerl; };
  my $status = $@;
  $this->{error_mgr}->exitProgram(
    ERR_CAT, 14,
    [ $this->sourceFile, $status ],
    defined($status) && $status
  );
}

sub getPropertiesTags {
  my xml::Parser $this = shift;
  return sort keys %{ $this->{properties} };
}

sub writeObject {
  my xml::Parser $this = shift;
  my ($directory) = @_;
  return undef if ( !defined( $this->sourceFile ) );
  my $parse_file = undef;
  if ( !util::Constants::EMPTY_LINE($directory) ) {
    $parse_file = join( util::Constants::SLASH,
      $directory,
      join( util::Constants::DOT, basename( $this->sourceFile ), 'parse', 'pl'
      )
    );
    $parse_file = getPath($parse_file);
  }
  my $objfile = new util::PerlObject( $parse_file, undef, $this->{error_mgr} );
  $objfile->writeStream( $this->getObject,
    util::PerlObject::PERL_OBJECT_WRITE_OPTIONS );
  $objfile->closeIo;
  return $parse_file;
}

sub getObject {
  my xml::Parser $this = shift;
  return undef if ( !defined( $this->sourceFile ) );
  return $this->{perl_object}->{ $this->outerElement };
}

sub getSubObject {
  my xml::Parser $this = shift;
  my ( $parent, $path ) = @_;
  my $object = $parent;
  foreach my $comp ( @{$path} ) {
    return undef if ( !ref($object) );
    $this->{error_mgr}->exitProgram(
      ERR_CAT, 15,
      [
        join( util::Constants::COMMA_SEPARATOR, @{$path} ), $comp,
        ref($object)
      ],
      ref($object) ne 'HASH'
    );
    return undef if ( !defined( $object->{$comp} ) );
    $object = $object->{$comp};
    return undef if ( !defined($object) );
  }
  return $object;
}

sub getSubObjects {
  my xml::Parser $this = shift;
  my ( $parent, $path ) = @_;

  my $objects = [];
  return $objects if ( scalar @{$path} == 0 );
  my $sub_path = [ @{$path} ];
  my $sub_comp = shift( @{$sub_path} );
  $this->_getSubObjs( $objects, $parent, $sub_comp, $sub_path );
  ###
  ### Now get the objects
  ###
  my $fobjects = [];
  foreach my $obj ( @{$objects} ) {
    if ( ref($obj) eq 'ARRAY' ) {
      push( @{$fobjects}, @{$obj} );
    }
    else {
      push( @{$fobjects}, $obj );
    }
  }
  return $fobjects;
}

################################################################################
#
#				 XML Perl Methods
#
################################################################################

sub getAttribute {
  my xml::Parser $this = shift;
  my ( $obj, $tag, $attribute ) = @_;
  my $missing_attribute =
    (    util::Constants::EMPTY_LINE($obj)
      || ref($obj) ne util::PerlObject::HASH_TYPE
      || !defined( $obj->{&ATTRIBUTE_NODE} ) );
  return undef if ($missing_attribute);
  return $obj->{&ATTRIBUTE_NODE}->{$attribute};
}

sub getTextNode {
  my xml::Parser $this = shift;
  my ( $obj, $tag ) = @_;
  my $missing_text_node =
    (    util::Constants::EMPTY_LINE($obj)
      || ref($obj) ne util::PerlObject::HASH_TYPE
      || !defined( $obj->{&TEXT_NODE} ) );
  return undef if ($missing_text_node);
  return $obj->{&TEXT_NODE};
}

sub getProperty {
  my xml::Parser $this = shift;
  my ( $obj, $tag, $property, $default_value ) = @_;
  my $error_predicate =
    (    util::Constants::EMPTY_LINE($obj)
      || ref($obj) ne util::PerlObject::HASH_TYPE
      || !defined( $obj->{&xml::Types::PROPERTY_TAG} ) );
  $this->{error_mgr}
    ->registerError( ERR_CAT, 3, [ $tag, $property ], $error_predicate );
  return undef if ($error_predicate);
  my $value = $obj->{&xml::Types::PROPERTY_TAG}->{$property};
  return $default_value
    if ( !defined($value) || $value eq util::Constants::EMPTY_STR );
  return $value;
}

sub getPropertiesByPattern {
  my xml::Parser $this = shift;
  my ( $obj, $tag, $property_pattern ) = @_;
  my %property_values = ();
  my $error_predicate =
    ( util::Constants::EMPTY_LINE($obj)
      || ref($obj) ne util::PerlObject::HASH_TYPE );
  $this->{error_mgr}->registerError( ERR_CAT, 3, [ $tag, $property_pattern ],
    $error_predicate );
  return keys %property_values
    if ( $error_predicate
    || !defined( $obj->{&xml::Types::PROPERTY_TAG} ) );
  while ( my ( $property, $value ) =
    each %{ $obj->{&xml::Types::PROPERTY_TAG} } )
  {
    next if ( $property !~ /$property_pattern/ );
    $property_values{$value} = util::Constants::EMPTY_STR;
  }
  return keys %property_values;
}

sub getUnixDate {
  my xml::Parser $this = shift;
  my ( $obj, $tag, $property ) = @_;
  my $value =
    $this->getProperty( $obj, $tag, $property, util::Constants::EMPTY_STR );
  return $value if ( $value eq util::Constants::EMPTY_STR );
  my $date = undef;
  eval { $date = &get_unix_str( &get_gbw_time($value) ); };
  my $status = $@;
  $this->{error_mgr}->registerError(
    ERR_CAT, 4,
    [ $tag, $property, $value, $status ],
    defined($status) && $status
  );
  return $date;
}

sub getOracleDate {
  my xml::Parser $this = shift;
  my ( $obj, $tag, $property ) = @_;
  my $value =
    $this->getProperty( $obj, $tag, $property, util::Constants::EMPTY_STR );
  return $value if ( $value eq util::Constants::EMPTY_STR );
  my $date = undef;
  eval { $date = &get_oracle_str( &get_gbw_time($value) ); };
  my $status = $@;
  $this->{error_mgr}->registerError(
    ERR_CAT, 4,
    [ $tag, $property, $value, $status ],
    defined($status) && $status
  );
  return $date;
}

sub getBoolean {
  my xml::Parser $this = shift;
  my ( $obj, $tag, $property ) = @_;
  my $value =
    $this->getProperty( $obj, $tag, $property, util::Constants::EMPTY_STR );
  $this->{error_mgr}->registerError(
    ERR_CAT, 5,
    [ $tag, $property ],
    util::Constants::EMPTY_LINE($value)
  );
  return undef if ( util::Constants::EMPTY_LINE($value) );
  return util::Constants::FALSE if ( $value eq "0" || lc($value) eq 'false' );
  return util::Constants::TRUE  if ( $value eq "1" || lc($value) eq 'true' );
  return $value;
}

################################################################################

1;

__END__

=head1 NAME

Parser.pm

=head1 SYNOPSIS

   use xml::Parser;

   sub COMMENTARYSET_TAG      {return 'CommentarySet';}
   sub COMMENTARY_TAG         {return 'Commentary';}
   sub DOMAIN_TAG             {return 'Domain';}
   sub GENE_ALIASES_E_TAG     {return 'Gene_aliases_E';}
   sub GENE_TAG               {return 'Gene';}
   sub HOMOLOGENEENTRYSET_TAG {return 'HomoloGeneEntrySet';}
   sub HOMOLOGENEENTRY_TAG    {return 'HomoloGeneEntry';}
   sub STATS_TAG              {return 'Stats';}

   sub FORCE_ARRAY {
     return
       [
        COMMENTARYSET_TAG,
        COMMENTARY_TAG,
        DOMAIN_TAG,
        GENE_ALIASES_E_TAG,
        GENE_TAG,
        HOMOLOGENEENTRY_TAG,
        STATS_TAG
       ];
   }

   my $parser =
     new xml::ParserXml
       (HOMOLOGENEENTRYSET_TAG,
        FORCE_ARRAY,
        $error_mgr);
   $parser->parse($source_file);
   $perl_object = $parser->getObject;

   ### write perl object to file
   $parser->writeObject($directory);

   ### write perl object to standard output
   $xmlToPerl->writeObject;

=head1 DESCRIPTION

This module allows an xml-file to be converted into a Perl object and
also to be written to a file or standard output

This class allows several xml tags to co-exist in the same file.  To
accomodate this, the outer-element can be set by default to
'super_xml_tag' .  The caller must instantiate the class with the
expected value or set it explicitly (see
L<"setOuterElement(xml_element)">).

=head1 CLASS METHODS (CONSTANTS)

The following constants define special (XML) node components in a
Perl object generated by this class.

   xml::PerlTypes::ATTRIBUTE_NODE -- xml attribute-node (.Attr)
   xml::PerlTypes::TEXT_NODE      -- xml text-node      (.Text)

The following constants define how xml attributes and elements can be
forced into special hashes by this class.  The
force types define how to create the special hash of a repeating
sub-tag under tag either by element or attribute.

   xml::PerlTypes::FORCE_ATTRIBUTE -- attribute
   -- Specified attributes of a sub-tag create a hash where one attribute
   -- is designated as the key and another designated as a value with the
   -- hash having the name of the sub-tag

   xml::PerlTypes::FORCE_ELEMENT -- element
   -- Specified tags under a sub-tag create a hash where one tag is
   -- designated as the key and another designated as a value with
   -- the hash having the name of the sub-tag

   -- The components of a standard force hash specification are defined
   -- as the following constants:
      xml::PerlTypes::FORCE_KEY    -- key
      xml::PerlTypes::FORCE_SUBTAG -- subtag
      xml::PerlTypes::FORCE_TAG    -- tag
      xml::PerlTypes::FORCE_TYPE   -- type
      xml::PerlTypes::FORCE_VALUE  -- value

The following constant defines the multi-value separator used in
forcing a hash with attributes where the sub-tag repeats with the same
key value.

   xml::PerlTypes::MULTIPLE_VALUE_SEPARATOR -- __XmlToPerl__

=head1 METHODS

The following method are defined for this class.

=head2 B<new xml::Parser(main_tag, force_tags, error_mgr)>

The new method is the constructor for this Object class.  It creates
an object for converting xml-files into perl objects.  This contructor
takes, the main_tag, and Perl referenced array force_tags of tags, and
the error messaging class (L<util::ErrMgr>).  The following defaults
are always set by the constructor

  outer element        - <main_tag> if defined, otherise 'super_xml_tag'
  stripping whitespace - TRUE (1),
  force arrays         - <force_tags> list if defined, otherwise empty
  force hashes         - empty

=head2 B<parse(source_file)>

This method takes the source file and converts it into the corresponding
Perl object.  If no outer xml outer element is specified, then the this
method forces the outer xml element to be B<super_xml_tag>

=head2 B<parse_file = writeObject(directory)>

This method writes the parsed perl object to a file or standard output
for the most recent source_file.  If the directory is defined, then
file has the format

   directory/basename(source_file).parse.pl

and is returned by this method, otherwise undef if returned.
If there has been no file parsed, this method is a no-op.

=head1 SETTER METHODS

The following methods set the attributes of the parse.

=head2 B<initializeForce>

This method removes all the currently set forcing of arrays and
hashes.

=head2 B<setRetainNode(xml_element, retain_status)>

This method instructs the parser to retain the xml_element when
it is trivial, that is,

   <xml_element></xml_element> or <xml_element />

with an empty string ("") text node value.  If retain_status is 
defined and TRUE(1), then the xml_element will be set to be 
retained when trivial, otherwise, it will not be set to be retained.

=head2 B<setForceArray(xml_element, force_status)>

This method allows one to update the force_array hash by adding xml
elements and changing their effectiveness.  If the force_status is
undef, then the default behavior of this class will prescribe what
happens with the element (See next paragraph below).  If the
xml_element is itself undefined (undef) or the empty string, then it
is ignored.  If the value of the force_status is TRUE, then this
xml_element will be coallesced into an array within its xml structure,
otherwise (FALSE) the default behavior will occur as for the undef
case.  Coallescing the xml_element into an array is important only for
if the xml_element is to be processed as an array of occurrences of
the xml_element at a given level and the xml_element potentially can
only occurs only once at a given level.

The default behavior on an xml_element is defined as follows. If the
xml_element occurs only once at a given level, then it is created as a
HASH and if it occurs more thant once then it is converted into an
ARRAY.  Therefore, the forcing action guarantee that an xml_element
will always be forced into an array.  That is, if the xml structure
is:

   <some_xml_element>
     <xml_element>
       ...
     </xml_element>
     <xml_element>
       ...
     </xml_element>
     <xml_element>
       ...
     </xml_element>
     ...
   </some_xml_element>

Then the Perl object will be:

   ...
   some_xml_element => {xml_element => [xml_element_1,
                                        xml_element_2,
                                        xml_element_3,
                                        ...
                                       ]
                        ...
   ...
=head2 B<setForceHash(force_type, xml_element, xml_subelement, key_element, value_element)>

This method allows one to update the force_hash hash by adding and
deleting xml elements to force them into hashes by the force_type.
The force_type can be either 'element' or 'attribute' (described
below) and can be set using the following static function functions:

   FORCE_ELEMENT
   FORCE_ATTRIBUTE

If the xml_subelement is defined, then the xml_element is added to the
force_hash hash of the apppropriate force_type and the xml_subelement
is also added to force array using B<"setForceArray">.

If xml_subelement is undef, then the xml_element is removed from the
force_hash hash of the appropriate force_type.  The xml_subelement is
not removed from the force_array hash.  If this is required then, this
must be done explicitly.

=over

=item B<force_type = element>

The force_hash hash specifies xml_elements that contain several
xml_sublements having the following structure:

   <xml_element>
     <xml_subelement>
       <key_element>
         KEY_ELEMENT_TEXT
       </key_element>
       <value_element>
         VALUE_ELEMENT_TEXT
       </value_element>
     </xml_subelement>
     <xml_subelement>
       .
       .
       .
     <xml_subelement>
       ...
   </xml_element>

force_hash requires that the Perl version of this structure will be a
hash under xml_element

   ...
   xml_element => {xml_subelement => {KEY_ELEMENT_TEXT => "VALUE_ELEMENT_TEXT",
                                      ...
                                     },
                   ...
                  }
   ...

=item B<force_type = attribute>

The force_hash hash specifies xml_elements that contain
xml_subelements having attributes of the following structure:

   <xml_element>
     <xml_subelement key_element="KEY_VALUE" value_element="VALUE_VALUE"></xml_subelement>
     <xml_subelement key_element="KEY_VALUE" value_element="VALUE_VALUE"></xml_subelement>
       ...
   </xml_element>

force_hash requires that the Perl version of this structure will be a
hash under xml_element

   ...
   xml_element => {xml_subelement => {KEY_VALUE => "VALUE_VALUE",
                                      ...
                                     },
                   ...
                  }
   ...

If the (key_element, value_element)-pairs at the same level have a
repeated key_element, then the value for the key_element is the
catenation of all the value_elements for it using the following
separator:

   xml::Parser::MULTIPLE_VALUE_SEPARATOR

=back

=head2 B<setForceHashes(force_hashes)>

This method sets the optional force hash data using the referenced
array B<force_hashes>.  By default there are no forced hashes.  Each
element of force_hashes is a referenced hash with at least the
following components:

   type
   tag
   subtag
   type
   value

For example, for Game xml the following force hashes are needed:

   type      tag                    subtag   type value
   --------- ---------------------- -------- ---- -----
   element   result_set             output   type value
   element   result_span            output   type value

   attribute computational_analysis property name value
   attribute feature_set            property name value
   attribute feature_span           property name value
   attribute property               property name value
   attribute result_set             property name value
   attribute result_span            property name value

=head2 B<setStripWhitespace>

This method instructs the parse method to strip leading whitespace
from text-values of xml elements.

=head2 B<unsetStripWhitespace>

This method instructs the parse method to not strip leading
whitespace from text-values of xml elements.

=head2 B<setOuterElement(xml_element)>

This method sets the outer xml_element (defined and non-empty) that is
expected in the xml file.  The default value of the outer xml_element
is B<super_xml_tag> and the parser will explicitly adds this tag as the
outer xml-element tag around the xml-document.  If the xml_element
parameter is undefined (undef), then this method set the outer
xml_element to B<super_xml_tag>.  If the xml_element parameter is defined
and empty, then it is ignored.

=head1 GETTER METHODS

The following methods get attributes and the results of the parse.

=head2 B<forceArray(xml_element)>

This method returns TRUE if the xml_element forces an array, otherwise
it returns FALSE.

=head2 B<forceHash(force_type, xml_element)>

This method returns TRUE if the xml_element forces a has for the given
force_type, otherwise it returns FALSE.

=head2 B<$outer_element = outerElement>

This method returns the outer xml_element for the object.

=head2 B<defaultOuterElement>

This method returns TRUE if the outer element is set to
B<super_xml_tag>, otherwise it returns FALSE.

=head2 B<@xml_tags = getPropertiesTags>

This method returns the list of xml-element tags that were forced into
hashes (either by element or attribute) by the latest execution of the
B<parse> method, otherwise it returns undef.

=head2 B<perl_object = getObject>

This method returns the Perl object generated by the latest execution
of the method L<"parse(source_file)">, otherwise it returns undef.  The
Perl object returned is the one corresponding to the outer
xml-element.  If no Perl object exists for this xml element, then
undef will be returned.

=head2 B<$sub_object = getSubObject(parent, path)>

This method returns a point in the parent data-structure based on the
path expression (a referenced list of component names).  If none
exists, then undef is returned.  It is an fatal error if the path
contains a component name to an array.

=head2 B<$source_file = sourceFile>

This method returns the most recent source file parsed.

=head1 XML PERL GETTER METHODS

The following methods are provided for for processing the Perl
object created by the L<"parser(source_file)"> class.

=head2 B<$attr_value = getAttribute(obj, tag, attribute)>

This method returns the value of the B<attribute> for the entity
B<obj>.  The B<tag> is provided for error recording (error_mgr).
The obj must be defined and contain an attribute-node, otherwise an
error is registered and undef is returned.

=head2 B<$text = getTextNode(obj, tag)>

This method returns the value of the B<text-node> for the B<obj>.  The
B<tag> is provided for error recording (error_mgr).  The obj must
be defined and contain a text-node, otherwise an error is registered
and undef is returned.

=head2 B<$property_value = getProperty(obj, tag, property, default_value)>

This method returns the value of the B<property> for the B<obj>.  The
B<tag> is provided for error recording (error_mgr).  The obj must
be defined and contain a property list, otherwise an error is
registered and undef is returned.  If the property does not exist in
the property list or is an empty string, then the value of the
property returned is the B<default_value>.

=head2 B<@property_values = getPropertiesByPattern(obj, tag, property_pattern)>

This method returns the unique list of property values for the set of
properties that match the B<property_pattern> for the B<obj>.  The
B<tag> is provided for error recording (error_mgr).  The obj must
be defined.  If properties do not exist (including properties obj not
existing), then an empty list is returned.

=head2 B<$unix_date = getUnixDate(obj, tag, property)>

This method assumes that the value of the B<property> for the B<obj>
is a date specified in GBW time format ('MM/DD/YYYY HH:MM:SS'--see
L<util::FileTime>).  The B<tag> is provided for error recording
(error_mgr).  This method returns the corresponding UNIX timestamp for
this date if it is defined, otherwise it returns an empty string.  It
is an error if the date format does not conform to the GBW time format
(undefined UNIX timestamp is return in this case).

=head2 B<$oracle_date = getOracleDate(obj, tag, property)>

This method assumes that the value of the B<property> for the B<obj>
is a date specified in GBW time format ('MM/DD/YYYY HH:MM:SS'--see
L<util::FileTime>).  The B<tag> is provided for error recording
(error_mgr).  This method returns the corresponding Oracle time format
('DD-MMM-YYYY:HH:MM:SS'--see L<util::FileTime>) for this date if it
is defined, otherwise it returns an empty string.  It is an error if
the date format does not conform to the GBW time format (undefined
Oracle date format is return in this case).

=head2 B<getBoolean(obj, tag, property)>

This method assumes that the value of the B<property> for the B<obj>
is a Boolean value (case-insensitive string 'false' or '0' or 'true'
or '1').  It is an error for value to be undefined.  The B<tag>
is provided for error recording (error_mgr).  The method return TRUE
(1) for 'true' or '1', and FALSE (0) for 'false' or '0'.  If the value
of the property is neither 'true' or 'false', then the value 'as-is'
is returned.
=cut
