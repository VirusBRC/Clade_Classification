package parallel::Utils;
################################################################################
#
#				Required Modules
#
################################################################################

use strict;

use FileHandle;
use Pod::Usage;

use util::Constants;
use util::Tools;

use parallel::ErrMsgs;

use fields qw(
  error_mgr
  job_info
  standard_properties
  tools
);

################################################################################
#
#			            Class Constants
#
################################################################################
###
### Standard Properties
###
sub DATASETNAME_PROP        { return 'datasetName'; }
sub EMAILTO_PROP            { return 'emailTo'; }
sub EMAIL_PROP              { return 'email'; }
sub ERRORFILES_PROP         { return 'errorFiles'; }
sub JOBINFO_PROP            { return 'jobInfo'; }
sub MAXPROCESSES_PROP       { return 'maxProcesses'; }
sub PIPELINECOMPONENTS_PROP { return 'pipelineComponents'; }
sub PIPELINEORDER_PROP      { return 'pipelineOrder'; }
sub PROCESSSLEEP_PROP       { return 'processSleep'; }
sub RETRYLIMIT_PROP         { return 'retryLimit'; }
sub RETRYSLEEP_PROP         { return 'retrySleep'; }
sub RUNSCOLS_PROP           { return 'runsCols'; }
sub RUNSINFO_PROP           { return 'runsInfo'; }
sub RUNTOOL_PROP            { return 'runTool'; }
sub STATUSFILE_PROP         { return 'statusFile'; }

sub RUNVERSION_PROP { return 'runVersion'; }
###
### Component Types
###
sub AGGREGATE_COMP       { return 'Aggregate'; }
sub DATAACQUISITION_COMP { return 'DataAcquisition'; }
sub MOVE_COMP            { return 'Move'; }
sub PREPROCESS_COMP      { return 'Preprocess'; }
sub RUNTOOL_COMP         { return 'RunTool'; }

sub COMPONENT_CLASS_PREFIX { return 'parallel::Component::'; }
sub TOOL_CLASS_PREFIX      { return 'tool::'; }
###
### Statuses
###
sub UNKNOWN_FAILURE { return 'Unknown Failure'; }
###
### Job Information Components
###
sub ERR_EXPRS_COMP         { return 'err_exprs'; }
sub REPORT_FILE_EXPRS_COMP { return 'report_file_exprs'; }
sub JOB_INFO_COMPS { return ( ERR_EXPRS_COMP, REPORT_FILE_EXPRS_COMP ); }
###
### Tool Output Suffixes
###
sub ERR_OUTPUT_SUFFIX { return 'err'; }
sub STD_OUTPUT_SUFFIX { return 'std'; }
###
### Error Category
###
sub ERR_CAT { return parallel::ErrMsgs::UTILS_CAT; }

################################################################################
#
#			            Public Methods
#
################################################################################

sub new($$$) {
  my parallel::Utils $this = shift;
  my ( $error_mgr, $tools ) = @_;
  $this = fields::new($this) unless ref($this);

  $this->{error_mgr}           = $error_mgr;
  $this->{tools}               = $tools;
  $this->{standard_properties} = [
    DATASETNAME_PROP,
    EMAILTO_PROP,
    EMAIL_PROP,
    ERRORFILES_PROP,
    JOBINFO_PROP,
    MAXPROCESSES_PROP,
    PIPELINECOMPONENTS_PROP,
    PROCESSSLEEP_PROP,
    RETRYLIMIT_PROP,
    RETRYSLEEP_PROP,
    RUNSCOLS_PROP,
    RUNSINFO_PROP,
    RUNTOOL_PROP,
    STATUSFILE_PROP,

    $tools->WORKSPACE_ROOT_PROP,
    $tools->SERVER_TYPE_PROP,
    $tools->DATABASE_NAME_PROP,
    $tools->USER_NAME_PROP,
    $tools->PASSWORD_PROP,
    $tools->SCHEMA_OWNER_PROP,
  ];

  $this->{job_info} = {};
  foreach my $comp (JOB_INFO_COMPS) { $this->{job_info}->{$comp} = []; }

  return $this;
}

################################################################################
#
#			            Component and Tool Creation Methods
#
################################################################################

sub createComponent {
  my parallel::Utils $this = shift;
  my ( $controller, $className ) = @_;

  my $class      = COMPONENT_CLASS_PREFIX . $className;
  my @eval_array = (
    'use ' . $class . ';',
    '$component =',
    'new ' . $class,
    '  ($controller,',
    '   $this,',
    '   $this->{error_mgr},',
    '   $this->{tools});'
  );
  my $eval_str = join( util::Constants::NEWLINE, @eval_array );
  $this->{error_mgr}->printMsg("createComponent:  eval_str=\n$eval_str");
  my $component = undef;
  eval $eval_str;
  my $status = $@;
  $this->{error_mgr}->exitProgram( ERR_CAT, 3, [ $class, $status ],
    ( defined($status) && $status )
      || util::Constants::EMPTY_LINE($component) );

  return $component;
}

sub createTool {
  my parallel::Utils $this = shift;
  my ( $className, @params ) = @_;

  my $params_str = util::Constants::EMPTY_STR;
  if ( @params >= 1 ) {
    foreach my $index ( 0 .. $#params ) {
      if ( $index > 0 ) { $params_str .= util::Constants::COMMA_SEPARATOR; }
      $params_str .= '$params[' . $index . ']';
    }
    $params_str .= util::Constants::COMMA_SEPARATOR;
  }
  my $class      = TOOL_CLASS_PREFIX . $className;
  my @eval_array = (
    'use ' . $class . ';',
    '$tool =', 'new ' . $class,
    '  (', $params_str, '   $this,',
    '   $this->{error_mgr},',
    '   $this->{tools});',
  );
  my $eval_str = join( util::Constants::NEWLINE, @eval_array );
  $this->{error_mgr}->printMsg("createTool:  eval_str=\n$eval_str");
  my $tool = undef;
  eval $eval_str;
  my $status = $@;
  $this->{error_mgr}->exitProgram(
    ERR_CAT, 4,
    [ $class, $status ],
    ( defined($status) && $status ) || util::Constants::EMPTY_LINE($tool)
  );

  return $tool;
}

################################################################################
#
#			            Command Creation Methods
#
################################################################################

sub getCmdWithRedirection {
  my parallel::Utils $this = shift;
  my ( $cmd, $params, $errOut, $stdOut ) = @_;
  my $fcmd = join( util::Constants::SPACE,
    $cmd, @{$params},
    '>> ' . $stdOut,
    '2>> ' . $errOut
  );
  return $fcmd;
}

sub getRunToolCmd {
  my parallel::Utils $this = shift;
  my ( $runTool, $propertiesFile, $workspaceRoot, $outPrefix ) = @_;
  my $errOut = join( util::Constants::SLASH,
    $workspaceRoot,
    join( util::Constants::DOT, $outPrefix, ERR_OUTPUT_SUFFIX ) );
  my $stdOut = join( util::Constants::SLASH,
    $workspaceRoot,
    join( util::Constants::DOT, $outPrefix, STD_OUTPUT_SUFFIX ) );
  my $cmd = $this->getCmdWithRedirection( $runTool, [ '-P', $propertiesFile ],
    $errOut, $stdOut );
  return $cmd;
}

################################################################################
#
#			            Utility Methods
#
################################################################################

sub getStatus {
  my parallel::Utils $this = shift;
  my ($sfile) = @_;

  return UNKNOWN_FAILURE
    if ( !( -e $sfile && !-z $sfile && -r $sfile ) );
  my $fh = new FileHandle;
  $fh->open( $sfile, '<' );
  my $status = undef;
  while ( !$fh->eof ) {
    $status = $fh->getline;
    chomp($status);
    last;
  }
  $fh->close;
  return $status;
}

sub getJobInfo {
  my parallel::Utils $this = shift;
  my ($comp) = @_;

  return $this->{job_info}->{$comp};
}

sub writeRunsInfo {
  my parallel::Utils $this = shift;
  my ( $properties, $runVersion ) = @_;

  my $tools      = $this->{tools};
  my $serializer = $tools->serializer;

  my @data = ();
  foreach my $property ( @{ $properties->{&RUNSCOLS_PROP} } ) {
    if ( $property eq RUNVERSION_PROP ) { push( @data, $runVersion ); }
    else {
      my $val = $properties->{$property};
      if ( ref($val) eq $serializer->HASH_TYPE ) {
        $val = join( util::Constants::COMMA_SEPARATOR, %{$val} );
      }
      elsif ( ref($val) eq $serializer->ARRAY_TYPE ) {
        $val = join( util::Constants::COMMA_SEPARATOR, @{$val} );
      }
      push( @data, $val );
    }
  }
  my $fileExists =
    ( -e $properties->{&RUNSINFO_PROP} )
    ? util::Constants::TRUE
    : util::Constants::FALSE;
  my $fh = new FileHandle;
  $fh->open( $properties->{&RUNSINFO_PROP}, '>>' );
  $fh->autoflush(util::Constants::TRUE);
  my $header =
    join( util::Constants::TAB, @{ $properties->{&RUNSCOLS_PROP} } )
    . util::Constants::NEWLINE;
  my $info = join( util::Constants::TAB, @data ) . util::Constants::NEWLINE;
  $fh->print($header) if ( !$fileExists );
  $fh->print($info);
  $fh->close;
  return $header . $info;
}

################################################################################
#
#			  Pattern/Replacement Methods
#
################################################################################

sub getPatternInfo {
  my parallel::Utils $this = shift;
  my ( $str, $patterns ) = @_;

  my $struct = {};
  foreach my $pattern_data ( @{$patterns} ) {
    my $pattern = $pattern_data->[0];
    my $map     = $pattern_data->[1];
    if ( $str =~ /$pattern/mi ) {
      my $vals = [];
      foreach my $index ( 0 .. $#{$map} ) {
        my $place_num = $index + 1;
        my $val       = undef;
        my $eval_str  = '$val = $' . $place_num . ';';
        eval $eval_str;
        push( @{$vals}, $val );
      }
      foreach my $index ( 0 .. $#{$map} ) {
        $struct->{ $map->[$index] } = $vals->[$index];
      }
      last;
    }
    elsif ( $str =~ /$pattern/smi ) {
      my $vals = [];
      foreach my $index ( 0 .. $#{$map} ) {
        my $place_num = $index + 1;
        my $val       = undef;
        my $eval_str  = '$val = $' . $place_num . ';';
        eval $eval_str;
        push( @{$vals}, $val );
      }
      foreach my $index ( 0 .. $#{$map} ) {
        $struct->{ $map->[$index] } = $vals->[$index];
      }
      last;
    }
  }

  return $struct;
}

sub getAllPatternInfo {
  my parallel::Utils $this = shift;
  my ( $str, $patterns ) = @_;

  my $struct = {};
  foreach my $pattern_data ( @{$patterns} ) {
    my $pattern = $pattern_data->[0];
    my $map     = $pattern_data->[1];
    if ( $str =~ /$pattern/mi ) {
      my $vals = [];
      foreach my $index ( 0 .. $#{$map} ) {
        my $place_num = $index + 1;
        my $val       = undef;
        my $eval_str  = '$val = $' . $place_num . ';';
        eval $eval_str;
        push( @{$vals}, $val );
      }
      foreach my $index ( 0 .. $#{$map} ) {
        $struct->{ $map->[$index] } = $vals->[$index];
      }
    }
    elsif ( $str =~ /$pattern/smi ) {
      my $vals = [];
      foreach my $index ( 0 .. $#{$map} ) {
        my $place_num = $index + 1;
        my $val       = undef;
        my $eval_str  = '$val = $' . $place_num . ';';
        eval $eval_str;
        push( @{$vals}, $val );
      }
      foreach my $index ( 0 .. $#{$map} ) {
        $struct->{ $map->[$index] } = $vals->[$index];
      }
    }
  }

  return $struct;
}

sub foundPattern {
  my parallel::Utils $this = shift;
  my ( $str, $patterns ) = @_;

  foreach my $pattern ( @{$patterns} ) {
    return util::Constants::TRUE if ( $str =~ /$pattern/i );
  }
  return util::Constants::FALSE;
}

sub doReplacements {
  my parallel::Utils $this = shift;
  my ( $str, $patterns ) = @_;

  foreach my $pattern ( @{$patterns} ) {
    my $substitutor = $pattern->[0];
    my $replacement = $pattern->[1];
    my $stmt        = '$str =~ s/' . $substitutor . '/' . $replacement . '/g';
    eval $stmt;
  }
  return $str;
}

################################################################################
#
#			            Setter Methods
#
################################################################################

sub setJobInfo {
  my parallel::Utils $this = shift;
  my ($jobInfo) = @_;

  return
    if ( util::Constants::EMPTY_LINE($jobInfo)
    || ref($jobInfo) ne $this->{tools}->serializer->HASH_TYPE );
  foreach my $comp (JOB_INFO_COMPS) {
    my $exprs = $jobInfo->{$comp};
    next
      if ( util::Constants::EMPTY_LINE($exprs)
      || ref($exprs) ne $this->{tools}->serializer->ARRAY_TYPE );
    push( @{ $this->{job_info}->{$comp} }, @{$exprs} );
  }
}

sub setLocalProperties {
  my parallel::Utils $this = shift;
  my ( $entity_type, $properties ) = @_;

  my $all_properties = {};
  return $all_properties
    if ( util::Constants::EMPTY_LINE($properties)
    || ref($properties) ne $this->{tools}->serializer->ARRAY_TYPE );
  foreach my $property ( @{$properties} ) {
    $all_properties->{$property} = $this->{tools}->getProperty($property);
    $this->{error_mgr}->exitProgram(
      ERR_CAT, 2,
      [ $entity_type, $property ],
      !defined( $all_properties->{$property} )
    );
  }
  return $all_properties;
}

sub setProperties {
  my parallel::Utils $this = shift;
  my ( $entity_type, $properties ) = @_;

  my $all_properties = $this->setLocalProperties( $entity_type, $properties );
  foreach my $property ( @{ $this->{standard_properties} } ) {
    $all_properties->{$property} = $this->{tools}->getProperty($property);
    $this->{error_mgr}->exitProgram(
      ERR_CAT, 1,
      [ $entity_type, $property ],
      !defined( $all_properties->{$property} )
    );
  }
  return $all_properties;
}

sub getOffsetTrailing {
  my parallel::Utils $this = shift;
  my ($seq) = @_;

  my $aseq = undef;
  if ( ref($seq) eq $this->{tools}->serializer->ARRAY_TYPE ) {
    $aseq = $seq;
  }
  else {
    $aseq = [ split( //, $seq ) ];
  }
  my $offset = 0;
  foreach my $index ( 0 .. $#{$aseq} ) {
    next
      if ( $aseq->[$index] eq util::Constants::HYPHEN );
    $offset = $index;
    last;
  }
  my $trailing = $#{$aseq};
  foreach my $index ( reverse 0 .. $#{$aseq} ) {
    next if ( $aseq->[$index] eq util::Constants::HYPHEN );
    $trailing = $index;
    last;
  }
  return ( $offset, $trailing )
    if ( ref($seq) eq $this->{tools}->serializer->ARRAY_TYPE );
  return ( $offset, $trailing, $aseq );
}

sub openFile {
  my parallel::Utils $this = shift;
  my ( $file, $mode, $return_handle ) = @_;

  $mode = util::Constants::EMPTY_LINE($mode) ? '>' : $mode;
  $return_handle =
    ( !util::Constants::EMPTY_LINE($return_handle) && $return_handle )
    ? util::Constants::TRUE
    : util::Constants::FALSE;
  $this->{error_mgr}->printMsg("openFile:  ($file, $mode)");
  my $file_str = util::Constants::EMPTY_STR;
  if ( $file =~ /(\.gz|\.Z)$/ ) {
    if ( $mode eq '<' ) {
      $file_str = 'gunzip -c ' . $file . '|';
    }
    elsif ( $mode eq '>' || $mode eq '>>' ) {
      $file_str = '| gzip -c ' . " $mode $file";
    }
  }
  else {
    $file_str = $mode . $file;
  }
  my $fh     = new FileHandle;
  my $status = !$fh->open($file_str);
  $fh->autoflush(util::Constants::TRUE)
    if ( !$status && ( $mode eq '>' || $mode eq '>>' ) );
  return $fh   if ( !$status );
  return undef if ($return_handle);
  $this->{error_mgr}
    ->exitProgram( ERR_CAT, 5, [ $mode, $file, 'failed to open file', ],
    $status );
}


################################################################################

1;

__END__

=head1 NAME

Types.pm

=head1 DESCRIPTION

This class defines the basic utilities for parallel library.

=head1 METHODS


=cut
