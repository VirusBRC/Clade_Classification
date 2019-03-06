package util::Random;
################################################################################
#
#				Required Modules
#
################################################################################

use strict;

use FileHandle;
use Pod::Usage;

use util::Constants;
use util::ErrMsgs;
use util::PathSpecifics;

use fields qw(
  error_mgr
  population
  population_size
  sample_size
);

################################################################################
#
#				   Constants
#
################################################################################
###
### Error Class
###
sub ERR_CAT { return util::ErrMsgs::RANDOM_CAT; }
###
### Mapping Record Tag
###
sub SAMPLE_SIZE { return 2000; }

################################################################################
#
#				Private Methods
#
################################################################################

sub _getPopulation {
  my util::Random $this = shift;
  my ($file) = @_;
  $file = getPath($file);
  $this->{error_mgr}
    ->exitProgram( ERR_CAT, 3, [$file], !-e $file || !-f $file || !-r $file );
  my $fh = new FileHandle;
  $this->{error_mgr}
    ->exitProgram( ERR_CAT, 4, [$file], !$fh->open( $file, '<' ) );
  my $whitespace = util::Constants::WHITESPACE;
  my $population = [];

  while ( !$fh->eof ) {
    my $input_line = $fh->getline;
    chomp($input_line);
    next
      if ( $input_line eq util::Constants::EMPTY_STR
      || $input_line =~ /^$whitespace$/
      || $input_line =~ /^#/ );
    push( @{$population}, $input_line );
  }
  $fh->close;
  return $population;
}

sub _initClass {
  my util::Random $this = shift;
  my ($population) = @_;
  $this->{error_mgr}->exitProgram( ERR_CAT, 1, [],
        !defined($population)
      || ref($population) ne 'ARRAY'
      || @{$population} == 0 );
  $this->{population_size} = scalar @{$population};
  $this->{population}      = [ @{$population} ];
  $this->{sample_size}     = SAMPLE_SIZE;
}

################################################################################
#
#			       Constructor Methods
#
################################################################################

sub new {
  my util::Random $this = shift;
  my ( $population, $error_mgr ) = @_;
  $this = fields::new($this) unless ref($this);
  $this->{error_mgr} = $error_mgr;
  $this->_initClass($population);
  ###
  ### Return the object
  ###
  return $this;
}

sub newByFile {
  my util::Random $this = shift;
  my ( $file, $error_mgr ) = @_;
  $this = fields::new($this) unless ref($this);
  $this->{error_mgr} = $error_mgr;
  $this->_initClass( $this->_getPopulation($file) );
  ###
  ### Return the object
  ###
  return $this;
}

################################################################################
#
#				 Setter Methods
#
################################################################################

sub setSampleSize {
  my util::Random $this = shift;
  my ($sample_size) = @_;

  $this->{error_mgr}->exitProgram( ERR_CAT, 2, [$sample_size],
         !defined($sample_size)
      || $sample_size !~ /^\+?\d+$/
      || int($sample_size) == 0 );

  $this->{sample_size} = int($sample_size);
}

sub setPopulationToSample {
  my util::Random $this = shift;
  $this->{population}      = [ $this->getSample ];
  $this->{population_size} = scalar @{ $this->{population} };
}

################################################################################
#
#				 Getter Methods
#
################################################################################

sub population {
  my util::Random $this = shift;
  return @{ $this->{population} };
}

sub populationByPrefix {
  my util::Random $this = shift;
  my ($prefix)          = @_;
  my @population        = ();
  foreach my $population_id ( @{ $this->{population} } ) {
    next if ( $population_id !~ /^$prefix/ );
    $population_id =~ s/^$prefix//;
    push( @population, $population_id );
  }
  return @population;
}

sub getSample {
  my util::Random $this = shift;
  return @{ $this->{population} }
    if ( $this->{sample_size} >= $this->{population_size} );
  my %sample      = ();
  my $sample_size = 0;
  while ( $sample_size < $this->{sample_size} ) {
    $sample{ $this->{population}
        ->[ int( rand( $this->{population_size} ) - 1 ) ] } =
      util::Constants::EMPTY_STR;
    my @keys = keys %sample;
    $sample_size = scalar @keys;
  }
  return keys %sample;
}

sub storeFile {
  my util::Random $this = shift;
  my ($file) = @_;
  $file = getPath($file);
  my $fh = new FileHandle;
  $this->{error_mgr}
    ->exitProgram( ERR_CAT, 5, [$file], !$fh->open( $file, '>' ) );
  foreach my $pop_id ( @{ $this->{population} } ) {
    $fh->print("$pop_id\n");
  }
  $fh->close;
}

################################################################################

1;

__END__

=head1 NAME

Random.pm

=head1 DESCRIPTION

This class defines the mechanism for determination of a random sample
from a population of a given size.

=head1 METHODS

These methods are used for creating this class.

=head2 B<new util::Random(population, error_mgr)>

This method is the constructor for this class.  The B<population> is a
non empty referenced array of the entity identifiers composing the
population.  The B<error_mgr> is the the error messaging object of
L<util::ErrMgr>.  By default, the sample size is set to B<2000>.

=head2 B<newByFile util::Random(file, error_mgr)>

This method is the constructor for this class.  The B<file> contains
the population ids.  Each population id is on a line and lines that
are empty or whitespace or start with B<#> are ignored.  It is a fatal
error for the file to be inaccessible or contain no population ids.
The B<error_mgr> is the the error messaging object of L<util::ErrMgr>.
By default, the sample size is set to B<2000>.

=head1 SETTER METHODS

The following setter methods are exported for this class.

=head2 B<setSampleSize(sample_size)>

This method sets the sample_size of the object.  B<sample_size> must
be a positive integer.  By default, the sample_size is set to B<2000>.

=head2 B<setPopulationToSample>

This special method sets the population to a random sample as
generated by a call to L<"getSample">.

=head1 GETTER METHODS

The following getter methods are exported by this class.

=head2 B<@sample = getSample>

This method returns random sample of sample_size from the population.
If the sample_size is larger than the size of the population, then the
whole population is returned.

=head2 B<@population = population>

This method returns population as a list.

=head2 B<@population = populationByPrefix(prefix)>

This method returns sub-population with the given prefix as a list.
Each population_id will have the prefix removed.

=head2 B<storeFile(file)>

This method stores the population into the file (one population id per
line) so that it can be read by B<newByFile>.

=cut
