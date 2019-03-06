package xml::Formater;
################################################################################
#
#				Required Modules
#
################################################################################

use strict;

use File::Basename;
use FileHandle;
use Pod::Usage;
use XML::Parser;

use util::Constants;
use util::Msg;
use util::PathSpecifics;

use xml::Types;

use fields qw(
  compressed
  msg
  outer_tag
  strip_whitespace
  tabs
  text_node
  xml_output
  xml_output_file
);

################################################################################
#
#				Private Methods
#
################################################################################
###
### Print the header of an element
###
sub _printStart {
  my xml::Formater $this = shift;
  my ( $name, $attr_ref ) = @_;
  if ( $name eq $this->{outer_tag} ) {
    $this->{tabs} = util::Constants::EMPTY_STR;
  }
  else {
    $this->{tabs} .= xml::Types::XML_INDENT;
  }
  $this->{xml_output}
    ->print( xml::Types::getOpenTag( $name, $attr_ref, $this->{tabs} ) );
}
###
### Print the end of an element
###
sub _printEnd {
  my xml::Formater $this = shift;
  my ($name) = @_;
  if ( defined( $this->{text_node} ) && $this->{text_node} =~ /\S/ ) {
    ###
    ### Only if it is the end the text node.
    ###
    if ( $this->{strip_whitespace} ) { $this->{text_node} =~ s/\s+$//; }
    my $text_str =
        $this->{tabs}
      . xml::Types::XML_INDENT
      . $this->{text_node}
      . util::Constants::NEWLINE;
    xml::Types::escapeReplacement( \$text_str );
    $this->{xml_output}->print($text_str);
  }
  $this->{xml_output}->print( xml::Types::getCloseTag( $name, $this->{tabs} ) );
  $this->{tabs} = substr( $this->{tabs}, 0, length( $this->{tabs} ) - 2 );
}
###
### The formatXml Call-Backs for an Object
###
sub _formatXml_handle_start {
  my xml::Formater $this = shift;
  return sub {
    my ( $expat, $name, %attr ) = @_;
    if ( $name ne xml::Types::SUPER_XML_TAG ) {
      $this->_printStart( $name, \%attr );
    }
    }
}

sub _formatXml_handle_end {
  my xml::Formater $this = shift;
  return sub {
    my ( $expat, $name ) = @_;
    if ( $name ne xml::Types::SUPER_XML_TAG ) {
      $this->_printEnd($name);
    }
    $this->{text_node} = undef;
    }
}

sub _formatXml_handle_char {
  my xml::Formater $this = shift;
  return sub {
    my ( $expat, $string ) = @_;
    ###
    ### strip leading tabs and whitespace but NOT spaces
    ###
    $string =~ s/^\t+//;
    $string =~ s/[\t\n\r\f]+$//;
    if ( $string =~ /\S+/ ) {
      if ( !defined( $this->{text_node} ) ) {
        ###
        ### Only if it is the beginning of the text node.
        ###
        if ( $this->{strip_whitespace} ) { $string =~ s/^\s+//; }
        $this->{text_node} = $string;
      }
      else {
        $this->{text_node} .= $string;
      }
    }
    }
}

################################################################################
#
#				    Methods
#
################################################################################

sub new {
  my xml::Formater $this = shift;
  my ($msg) = @_;
  $this = fields::new($this) unless ref($this);
  if ( !defined($msg) || !ref($msg) ) { $msg = new util::Msg; }
  $this->{compressed}       = util::Constants::FALSE;
  $this->{msg}              = $msg;
  $this->{outer_tag}        = util::Constants::EMPTY_STR;
  $this->{strip_whitespace} = util::Constants::TRUE;
  $this->{tabs}             = undef;
  $this->{text_node}        = undef;
  $this->{xml_output_file}  = undef;
  $this->{xml_output}       = new FileHandle;
  return $this;
}

sub setOuterTag {
  my xml::Formater $this = shift;
  my ($outer_tag) = @_;
  return
    if ( !defined($outer_tag) || $outer_tag eq util::Constants::EMPTY_STR );
  $this->{outer_tag} = $outer_tag;
}

sub setCompressed {
  my xml::Formater $this = shift;
  $this->{compressed} = util::Constants::TRUE;
}

sub setUnCompressed {
  my xml::Formater $this = shift;
  $this->{compressed} = util::Constants::FALSE;
}

sub setStripWhitespace {
  my xml::Formater $this = shift;
  $this->{strip_whitespace} = util::Constants::TRUE;
}

sub unsetStripWhitespace {
  my xml::Formater $this = shift;
  $this->{strip_whitespace} = util::Constants::FALSE;
}

sub formatXml {
  my xml::Formater $this = shift;
  my ( $output_dir, $xml_file ) = @_;
  $output_dir = &getPath($output_dir);
  $this->{msg}->dieOnError(
    "Cannot Access output_dir = $output_dir",
    !-e $output_dir || !-d $output_dir
  );
  ###
  ### Create modified xml_file
  ###
  $xml_file = getPath($xml_file);
  my $prefix             = basename($xml_file);
  my $xml_suffix         = xml::Types::FORMATED_FILE_INFIX;
  my $xml_suffix_pattern = xml::Types::XML_FILE_SUFFIX_PATTERN;
  $prefix =~ s/$xml_suffix_pattern$//;
  if ( defined($1) ) {
    $xml_suffix = join( util::Constants::DOT, $xml_suffix, $1 );
  }
  else {
    $xml_suffix =
      join( util::Constants::DOT, $xml_suffix, xml::Types::XML_FILE_SUFFIX );
  }
  $this->{xml_output_file} = join( util::Constants::SLASH,
    $output_dir, join( util::Constants::DOT, $prefix, $xml_suffix ) );
  if ( $this->{compressed} ) { $this->{xml_output_file} .= '.gz'; }
  ###
  ### Set variables
  ###
  $this->{tabs}      = util::Constants::EMPTY_STR;
  $this->{text_node} = undef;
  ###
  ### Create the xml parser
  ###
  my $xml_parser = new XML::Parser(
    Handlers => {
      Start => $this->_formatXml_handle_start,
      End   => $this->_formatXml_handle_end,
      Char  => $this->_formatXml_handle_char,
    },
    ProtocolEncoding => 'ISO-8859-1'
  );
  ###
  ### Process xml_file
  ###
  my $zipped_file_pattern = xml::Types::ZIPPED_FILE_PATTERN;
  if ( $xml_file =~ /$zipped_file_pattern/ ) {
    $this->{msg}->dieOnError(
      "Cannot open xml file = $xml_file",
      !open( XML_INPUT, "gunzip -c $xml_file |" )
    );
  }
  else {
    $this->{msg}->dieOnError( "Cannot open xml file = $xml_file",
      !open( XML_INPUT, "<$xml_file" ) );
  }
  if ( $this->{compressed} ) {
    $this->{msg}->dieOnError(
      "Could not open xml_file = "
        . $this->{xml_output_file} . "\n"
        . "  errMsg = $!",
      !$this->{xml_output}->open( "| gzip -c > " . $this->{xml_output_file} )
    );
  }
  else {
    $this->{msg}->dieOnError(
      "Could not open xml_file = "
        . $this->{xml_output_file} . "\n"
        . "  errMsg = $!",
      !$this->{xml_output}->open( $this->{xml_output_file}, '>' )
    );
  }
  my $data        = util::Constants::EMPTY_STR;
  my $xml_parsing = $xml_parser->parse_start;
  if ( $this->{outer_tag} eq xml::Types::XML_TAG ) {
    $xml_parsing->parse_more(xml::Types::OPEN_SUPER_XML);
  }
  while ( read( XML_INPUT, $data, xml::Types::STANDARD_BLOCK_SIZE ) ) {
    $xml_parsing->parse_more($data);
  }
  if ( $this->{outer_tag} eq xml::Types::XML_TAG ) {
    $xml_parsing->parse_more(xml::Types::CLOSE_SUPER_XML);
  }
  $xml_parsing->parse_done;
  $this->{xml_output}->close;
  close(XML_INPUT);
}

sub getXmlFile {
  my xml::Formater $this = shift;
  return $this->{xml_output_file};
}

################################################################################

1;

__END__

=head1 NAME

Formater.pm

=head1 SYNOPSIS

   use xml::Formater;

   my $xmlFormater = new xml::Formater();
   $xmlFormater->setStripWhitespace();
   $xmlFormater->formatXml($myOutputDir, $myXmlFile);
   my $myNewXmlFile = $xmlFormater->getXmlFile;

=head1 DESCRIPTION

This module formats (pretty prints) an xml document.

=head1 METHODS

=head2 B<new xml::Formater>

The new method is the constructor for this Object class.  It creates
an object for formating xml documents.  By default, compression is
FALSE, skipping white-space is TRUE, and the outer xml-tag is
B<'game'>.

=head2 B<setCompressed>

This method sets the compression switch to compressed output file.

=head2 B<setUnCompressed>

This method sets the compression switch to uncompressed for the output
file.  This is the default for the compression switch.

=head2 B<setOuterTag(outer_tag)>

This method sets the outer xml-tag.  This determines formating and
parsing behavior.  By default, the outer_tag is set to B<'game'> and
parsing encapsulates the xml-file with B<'super_game'> tag in case
there are several B<'game'> tags in the file.  Otherwise, the
assumption is that there is only one outer_tag.

=head2 B<setStripWhitespace>

This method instructs the formater to strip the whitespace from the
beginning of the text node and at its end.  This this the default for
the formater.

=head2 B<unsetStripWhitespace>

This method instructs the formater not to strip the whitespace from
the beginning and the end of the text node.

=head2 B<formatXml(output_dir, xml_file)>

This method takes in an B<output_dir> and a <xml_file>.  It formats
the document writing it to the following xml document:

   <output_dir>/<prefix>.formated(\.xml|\.gbw)(\.gz)?

where the B<prefix> is defined by the expression

   <xml_file> ::= <dir_name>/<prefix>(\.xml|\.gbw)(\.gz|\.Z)?

The B<xml_file> can either plain or gzipped.

=head2 B<getXmlFile>

This method returns the name of the formated B<xml_file> that has been
created by the B<formatXml>.  If B<formatXml> has not be executed,
then the list is empty.

=cut
