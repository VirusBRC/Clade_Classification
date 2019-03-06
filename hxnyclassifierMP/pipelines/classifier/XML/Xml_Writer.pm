package XML::Xml_Writer;

use strict;
use warnings; 
use Carp;
use IO::File;
use XML::Writer;

#
# 	XML writer, takes two arguments file path and Hashref for tag structure. 
#	e.g. my xmlWriter = XML::XMLWRITER(
#				"file" => "file path " 
#				"map" => hashref
#			)
#
##

my $writer = undef;
my $output = undef;
my $fileName = undef;

sub new{
	my $class = shift;
	my $self = { @_ };
	bless ( $self,$class );
	$self->_init;
	return $self;
}


sub _init{

	my $self = shift; 
	$fileName = $self->{fileName}; 
}


sub writeXML{

	my $self = shift;	
	my (%map) = %{$_[0]};
	$output = new IO::File(">$fileName");
	$writer = new XML::Writer(OUTPUT => $output, DATA_MODE=>1, DATA_INDENT=>2);
	$writer->xmlDecl( 'UTF-8' );
	$writer->startTag("Config");
	foreach my $key (keys (%map)){
		$writer->startTag("Param",("name"=>$key,"value"=>$map{$key}));
		$writer->endTag();
	}
	
	$writer->endTag();	
	$writer->end();
	$output->close;
}



sub fileName{ $_[0]->{fileName} } # if defined; "config.xml";}


1;
