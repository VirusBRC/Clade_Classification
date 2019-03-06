=pod
Author - Niket Mhatre
Class for readding XML content of config file.
=cut
package XML::Xml_Reader;

use strict;
use warnings;
use Carp;
use XML::SAX::ParserFactory;
use XML::Handler;

=pod
Hashref holds map of entier XML config.  
lease refer config_gen.pl script for more information of XML map.
=cut
my %xmlMap = ();
my $handler;

=pod
Create an object of Xml_Reader with following parameter. 
uri -> 'XML file uri' 
 (optional) isvalidate -> 1 or 0 Default 1
 (optional) dtd -> location of dtd. Default config.dtd 
=cut
sub new{
	my $class= shift;
	my $self = { @_ };
	bless ($self,$class);
	$self->_init;
	return $self;
}



sub _init{
	
	my $self = shift;
	$self->{isvalidate} = 1 if !(defined $self->{isvalidate});
	
	$handler = XML::Handler->new();	
	$self->parser( XML::SAX::ParserFactory->parser(
						Handler => $handler 
						));
	
}

=pod
Parse XML document. 

=cut
sub Parse_Xml{
	my $self = shift;
	my $parser = $self->{parser};
	my $xmlURL = $self->{uri}; 	
	
	unless(defined $xmlURL  && -e $xmlURL ){

		warn "No XML document found for parssing";
		return; 
	}

	unless(defined $parser){

		warn "No parser found";
		return;	
	}

	$parser->parse_uri($xmlURL);
	
}

=pod
Get parser associated with this Xml_reader. 
=cut
sub parser { $_[0]->{parser} = $_[1] if defined $_[1]; $_[0]->{parser} }

=pod 
Check validation is on or not.
=cut
sub isvalidate { $_[0]->{isvalidate} = $_[1] if defined $_[1]; $_[0]->{isvalidate}}


=pod
Get URI associated with this Xml_Reader. 
=cut
sub uri{ $_[0]->{uri} }


=pod
Get Tree Map content of the XML file. 
=cut
sub getData{ return $handler->GetXML_MAP(); }


1;
