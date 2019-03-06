package parallel::Component::Preprocess::rate4site;
################################################################################
#
#				Required Modules
#
################################################################################

use strict;

use Cwd 'chdir';
use Pod::Usage;

use util::Constants;

use base 'parallel::Component::Preprocess';

################################################################################
#
#			            Static Class Constants
#
################################################################################
###
### rate4site Specific Properties from the Controller Configuration
###
sub PDBDIRECTORY_PROP { return 'pdbDirectory'; }
sub PDBFILEROOT_PROP  { return 'pdbFileRoot'; }
sub PDBFILES_PROP     { return 'pdbFiles'; }
sub PDBSERVER_PROP    { return 'pdbServer'; }
sub PDBUSERNAME_PROP  { return 'pdbUserName'; }

sub R4S_PROPERTIES {
  return [
    PDBDIRECTORY_PROP, PDBFILEROOT_PROP, PDBFILES_PROP,
    PDBSERVER_PROP,   PDBUSERNAME_PROP,
  ];
}

################################################################################
#
#                           Public Methods
#
################################################################################

sub new($$$$$) {
  my ( $that, $controller, $utils, $error_mgr, $tools ) = @_;
  my parallel::Component::Preprocess::rate4site $this =
    $that->SUPER::new( R4S_PROPERTIES, 'rate4site', $controller, $utils,
    $error_mgr, $tools );

  return $this;
}

sub preprocess_data {
  my parallel::Component::Preprocess::rate4site $this = shift;

  my $cmds         = $this->{tools}->cmds;
  my $properties   = $this->getLocalDataProperties;

  my $pdbDirectory = $properties->{pdbDirectory};

  my $pdbFiles =
    join(util::Constants::SLASH,
         $pdbDirectory,
         $properties->{pdbFiles});
  my $server =
    $properties->{pdbUserName} . '@' . $properties->{pdbServer};

  my $pdbFileRoot = 
    $cmds->createDirectory
      ($properties->{pdbFileRoot},
       'Creating Destination Directory',
       util::Constants::TRUE);
  chdir($pdbFileRoot);

  my $msgs = {};
  $msgs->{cmd} = "scp $server:$pdbFiles .";
  $cmds->executeCommand( $msgs, $msgs->{cmd}, 'copying pdb files');
}

################################################################################

1;

__END__

=head1 NAME

rate4site.pm

=head1 DESCRIPTION

This class defines the mechanism for getting the pdb files necessary
for running rate4site.

=head1 STATIC CONSTANTS


=head1 METHODS

The following methods are exported by this class.

=head2 B<new parallel::Component::Preprocess::rate4site(controller, error_mgr, tools)>

This is the constructor for the class.

=cut
