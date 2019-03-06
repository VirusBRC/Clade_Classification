package XML::Handler;

use strict;
use warnings;
use XML::SAX::Base;

my %xmlMap;

my $eName = undef;


sub new{

	my $class = shift;
	my $self = { @_ };
	bless( $self,$class);
	$self->_init;
	return $self;
}


sub _init {

	my $self=shift;
	%xmlMap = ();
	
}


sub start_element {
	my ($self,$element) = @_;
	$eName = $element->{Name};

	if($eName eq "Param"){
		my $attrs = $element->{Attributes};
		my $key = $attrs->{"{}name"}->{Value};
		my $value = $attrs->{"{}value"}->{Value};
		$xmlMap{$key} = $value;
	}
		
	
}




sub GetXML_MAP{

	return %xmlMap;
}




1;
