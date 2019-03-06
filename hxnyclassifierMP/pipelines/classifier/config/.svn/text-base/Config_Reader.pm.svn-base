package config::Config_Reader;

use warnings;
use strict;
use Carp;
use XML::Xml_Reader;

my %configMap;
my $xmlReader;

sub new {
    my $class = shift;
    my $self = { @_ };
    bless ( $self,$class);
    $self->_init;
    return $self;
}

sub _init{

    my $self = shift;
    $xmlReader = XML::Xml_Reader->new ( uri => $self->{fileName});
    $xmlReader->Parse_Xml();
    %configMap = $xmlReader->getData();
}

sub fileName{ $_[0]->{fileName} = $_[1] if defined $_[1]; $_[0]->{fileName}; }

sub getValue{

    return  $configMap{$_[1]} if defined $_[1];
}

sub setValue{

    $configMap{$_[1]} = $_[2] if (defined($_[1]) && defined($_[2]));
}

1;
