package tool::Tool;
################################################################################
#
#				Required Modules
#
################################################################################

use strict;

use Pod::Usage;

use util::Constants;
use util::Tools;

use fields qw(
  error_mgr
  local_properties
  properties
  tool_type
  tools
  utils
);

################################################################################
#
#			            Static Class Constants
#
################################################################################
###
### Interproscan Properties
###
sub DATAFILELOCK_PROP           { return 'dataFileLock'; }
sub DATAFILE_PROP               { return 'dataFile'; }
sub ERRFILE_PROP                { return 'errFile'; }
sub OUTPUTFILE_PROP             { return 'outputFile'; }
sub SLEEPINTERVAL_PROP          { return 'sleepInterval'; }
sub STATUSFILE_PROP             { return 'statusFile'; }
sub STDFILE_PROP                { return 'stdFile'; }
sub TOOLCLASS_PROP              { return 'toolClass'; }
sub TOOLNAME_PROP               { return 'toolName'; }
sub TOOLOPTIONS_PROP            { return 'toolOptions'; }
sub TOOLOPTIONREPLACEMENTS_PROP { return 'toolOptionReplacements'; }
sub TOOLOPTIONVALS_PROP         { return 'toolOptionVals'; }
sub TOOLRUNDIRECTORY_PROP       { return 'toolRunDirectory'; }
sub OUTPUTFILESUFFIX_PROP       { return 'outputFileSuffix'; }

sub TOOL_PROPERTIES {
  return (
    DATAFILE_PROP,
    DATAFILELOCK_PROP,
    ERRFILE_PROP,
    OUTPUTFILE_PROP,
    SLEEPINTERVAL_PROP,
    STATUSFILE_PROP,
    STDFILE_PROP,
    TOOLCLASS_PROP,
    TOOLNAME_PROP,
    TOOLOPTIONS_PROP,
    TOOLOPTIONREPLACEMENTS_PROP,
    TOOLOPTIONVALS_PROP,
    TOOLRUNDIRECTORY_PROP,
    OUTPUTFILESUFFIX_PROP,

    util::Tools::EXECUTION_DIRECTORY_PROP,
    util::Tools::WORKSPACE_ROOT_PROP
  );
}

################################################################################
#
#                           Public Methods
#
################################################################################

sub new($$$$$$) {
  my tool::Tool $this = shift;
  my ( $tool_type, $properties, $utils, $error_mgr, $tools ) = @_;
  $this = fields::new($this) unless ref($this);

  $this->{error_mgr}        = $error_mgr;
  $this->{local_properties} = [ @{$properties} ];
  $this->{tool_type}        = $tool_type;
  $this->{tools}            = $tools;
  $this->{utils}            = $utils;

  push( @{$properties}, TOOL_PROPERTIES );
  $this->{properties} = $utils->setLocalProperties( $tool_type, $properties );

  return $this;
}

sub run {
  my tool::Tool $this = shift;
  ########################
  #### Abstract Method ###
  ########################
}

sub executeSimpleTool {
  my tool::Tool $this = shift;
  my ( $toolName, $params, $msg, $input, $output ) = @_;

  my $properties = $this->getProperties;
  my $tools      = $this->{tools};
  my $cmds       = $tools->cmds;

  if ( util::Constants::EMPTY_LINE($msg) ) { $msg = "executing $toolName"; }

  if ( !util::Constants::EMPTY_LINE($input) ) { $input = '< ' . $input; }
  else { $input = util::Constants::EMPTY_STR; }

  if ( util::Constants::EMPTY_LINE($output) ) {
    $output = $properties->{stdFile};
  }

  my $cmd = join( util::Constants::SPACE,
    $toolName, $params, $input,
    '>> ' . $output,
    '2>> ' . $properties->{errFile}
  );
  my $msgs = { cmd => $cmd, };
  return $cmds->executeCommand( $msgs, $cmd, $msg );
}

sub executeTool {
  my tool::Tool $this = shift;
  my ($params) = @_;

  my $properties = $this->getProperties;
  my $tools      = $this->{tools};
  my $cmds       = $tools->cmds;

  my $cmd = join( util::Constants::SPACE,
    $properties->{toolName},
    $properties->{toolOptions},
    $params,
    '> ' . $properties->{stdFile},
    '2> ' . $properties->{errFile}
  );
  my $msgs = { cmd => $cmd, };
  return $cmds->executeCommand( $msgs, $cmd,
    'executing command for tool type ' . $this->getToolType );
}

sub executeToolWithVals {
  my tool::Tool $this = shift;
  my ( $params, $replacements ) = @_;

  my $properties = $this->getProperties;
  my $tools      = $this->{tools};
  my $cmds       = $tools->cmds;

  my @optionsArray   = ();
  my $toolOptionVals = $properties->{toolOptionVals};
  foreach my $toolOption ( @{ $properties->{toolOptions} } ) {
    push( @optionsArray, $toolOption );
    my $option = $toolOption;
    $option =~ s/^-+//;
    next if ( !defined( $toolOptionVals->{$option} ) );
    my $optionVal = $toolOptionVals->{$option};
    foreach my $pattern ( keys %{$replacements} ) {
      my $replacement = $replacements->{$pattern};
      $optionVal =~ s/$pattern/$replacement/;
    }
    push( @optionsArray, $optionVal );
  }

  my $cmd = join( util::Constants::SPACE,
    $properties->{toolName},
    @optionsArray, $params,
    '> ' . $properties->{stdFile},
    '2> ' . $properties->{errFile}
  );
  my $msgs = { cmd => $cmd, };
  return $cmds->executeCommand( $msgs, $cmd,
    'executing command for tool type ' . $this->getToolType );
}

################################################################################
#
#                           Getter Methods
#
################################################################################

sub getToolType {
  my tool::Tool $this = shift;
  return $this->{tool_type};
}

sub getProperties {
  my tool::Tool $this = shift;
  return $this->{properties};
}

sub getLocalProperties {
  my tool::Tool $this = shift;
  return sort @{ $this->{local_properties} };
}

sub getLocalDataProperties {
  my tool::Tool $this = shift;

  my $properties = {};
  ###
  ### Get the properties specific class
  ###
  foreach my $property ( $this->getLocalProperties ) {
    $properties->{$property} = $this->getProperties->{$property};
  }
  return $properties;
}

################################################################################

1;

__END__

=head1 NAME

interproScan.pm

=head1 DESCRIPTION

This class defines the runner for interproscan.

=head1 STATIC CONSTANTS


=head1 METHODS

The following methods are exported by this class.

=head2 B<new tool::Tool(tool_type, properties, utils, error_mgr, tools)>

This is the constructor for the class.

=cut
