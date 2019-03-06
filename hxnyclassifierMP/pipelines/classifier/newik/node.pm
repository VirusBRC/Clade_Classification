package newik::node;

use strict;
use warnings;

sub new {
  my $class = shift;

  my $self = {@_};
  bless( $self, $class );
  $self->_init;

  return $self;
}

sub _init { }

#Map parent child
sub parent {
  my $self = shift;
  my ($parent) = @_;

  $self->{parent} = $parent if ( defined($parent) );
  return $self->{parent};
}

#name of node
sub name {
  my $self = shift;
  my ($name) = @_;

  $self->{name} = $name if ( defined($name) );
  return $self->{name};
}

sub type {
  my $self = shift;
  my ($type) = @_;

  $self->{type} = $type if ( defined($type) );
  return $self->{type};
}

sub addNode { }

sub getLNode { }
sub getCNode { }

sub cluster {
  my $self = shift;
  my ($cluster) = @_;

  $self->{cluster} = $cluster if ( defined($cluster) );
  return $self->{cluster};
}

sub accession {
  my $self = shift;
  my ($name) = @_;

  $self->{name} = $name if ( defined($name) );
  return $self->{name};
}

sub class {
  my $self = shift;
  my ($class) = @_;

  $self->{class} = $class if ( defined($class) );
  retrn $self->{class};
}

return 1;
