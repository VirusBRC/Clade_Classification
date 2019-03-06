package util::Tools;
################################################################################
#
#				Required Modules
#
################################################################################

use strict;

use Cwd 'chdir';
use File::Basename;
use Pod::Usage;
use POSIX;

use util::Cmd;
use util::ConfigParams;
use util::Constants;
use util::Db;
use util::ErrMsgs;
use util::FileTime;
use util::PathSpecifics;
use util::PerlObject;
use util::Table;

use fields qw(
  bcp_dir
  bin
  cmds
  config_params
  context
  db
  die_on_error
  end_time
  error_mgr
  execution_dir
  file_properties
  header
  logging_file
  email
  print_properties
  print_stats
  properties
  script_name
  script_path
  serializer
  start_time
  status
  statuses
  table_info
  tool_order
  user_name
  run_status
);

################################################################################
#
#			            Static Class Constants
#
################################################################################
###
### Suffixes
###
sub MODULE     { return 'pm'; }
sub PERL       { return 'pl'; }
sub PROPERTIES { return 'properties'; }
sub TABLES     { return 'tables'; }
sub SCRIPTS    { return 'scripts'; }
sub TOOLS      { return 'tools'; }
sub XML        { return 'xml'; }
###
### Properties
###
sub DEFAULT_PROPERTIES { return 'defaults'; }
sub TOOLS_PROPERTIES   { return 'tools'; }
###
### Status File Flags
###
sub FAILED    { return 'FAILED'; }
sub SUCCEEDED { return 'SUCCEEDED'; }

sub STATUSES {
  return {
    &FAILED    => util::Constants::FALSE,
    &SUCCEEDED => util::Constants::FALSE,
  };
}
###
### Required Context Properties
###
sub DEBUG_SWITCH_PROP        { return 'debugSwitch'; }
sub EXECUTION_DIRECTORY_PROP { return 'executionDirectory'; }
sub LOG_INFIX_PROP           { return 'logInfix'; }
sub WORKSPACE_ROOT_PROP      { return 'workspaceRoot'; }
###
### Other Basic Context Properties
###
sub ANCILLARY_PROPERTIES_PROP { return 'ancillaryProperties'; }
sub HEADER_MESSAGE_PROP       { return 'headerMessage'; }
sub PROPERTY_SET_PROP         { return 'propertySet'; }
###
### Database Specific Properties
###
sub SERVER_TYPE_PROP   { return 'serverType'; }
sub DATABASE_NAME_PROP { return 'databaseName'; }
sub USER_NAME_PROP     { return 'userName'; }
sub PASSWORD_PROP      { return 'password'; }
sub SCHEMA_OWNER_PROP  { return 'schemaOwner'; }
###
### Property Message
###
sub PROPERTY_COL { return 'Property'; }
sub VALUE_COL    { return 'Value'; }
sub MSG_COLS     { return ( PROPERTY_COL, VALUE_COL ); }
###
### Config Parameters Loading Types
###
sub FILE_TYPE   { return 'FILE'; }
sub MODULE_TYPE { return 'MODULE'; }
###
### Error Category
###
sub ERR_CAT { return util::ErrMsgs::TOOLS_CAT; }

################################################################################
#
#				Private Methods
#
################################################################################
###
### _getItem:
###
### Given the library name (lib), retrun the filename for the
### item (name) of a given type (type).  The type must be
### defined, as well as the item within the type.  Also, this
### method checks that the filename exists and is of the proper
### file mode.
###
sub _getItem($$$$) {
  my util::Tools $this = shift;
  my ( $name, $lib, $type ) = @_;

  if ( $type eq TOOLS ) {
    $name =~ s/\.pl$//;
    $name .= util::Constants::DOT . PERL;
  }
  elsif ( $type eq PROPERTIES ) {
    $name =~ s/\.properties$//;
    $name .= util::Constants::DOT . PROPERTIES;
  }
  elsif ( $type eq XML ) {
    $name =~ s/\.properties$//;
    $name .= util::Constants::DOT . XML;
  }
  ###
  ### Create the path
  ###
  ### Note:  if the library is undefined, then the tool is directly in bin
  ###
  my @path_array = ( $this->{bin} );
  push( @path_array, $lib ) if ( !util::Constants::EMPTY_LINE($lib) );
  push( @path_array, $name );
  my $item = getPath( join( util::Constants::SLASH, @path_array ) );
  my $predicate = ( !-e $item || !-f $item || !-r $item );
  if ( $type eq TOOLS
    || $type eq SCRIPTS )
  {
    $predicate = ( $predicate || !-x $item );
  }
  $this->exitProgram( ERR_CAT, 2, [ $name, $lib, $type, $item ], $predicate );

  return $item;
}

sub _getTime {
  my util::Tools $this = shift;
  my ( $time, $as_date ) = @_;
  $as_date =
    !util::Constants::EMPTY_LINE($as_date)
    ? util::Constants::TRUE
    : util::Constants::FALSE;
  return $time if ( !$as_date );
  my $date = &get_oracle_str( get_unix_time($time) );
  return $date;
}

sub _printPropertyMessage {
  my util::Tools $this = shift;
  ###
  ### Create table
  ###
  my @ord  = MSG_COLS;
  my %cols = ();
  foreach my $col (@ord) { $cols{$col} = $col; }
  my $table = new util::Table( $this->{error_mgr}, %cols );
  ###
  ### Set Configuration
  ###
  $table->setColumnOrder(@ord);
  $table->setRowOrder(
    'sub {$a->{' . &PROPERTY_COL . '} cmp $b->{' . &PROPERTY_COL . '};}' );
  $table->setInHeader(util::Constants::TRUE);
  foreach my $col (@ord) {
    $table->setColumnJustification( $col, util::Table::LEFT_JUSTIFY );
  }
  my $config_params = $this->getConfigParams;
  my ( $properties, $loadingType, $loaded ) =
    $this->newConfigParams($config_params);
  my $header =
      "configParams (-P)\n"
    . "  loadingType = $loadingType\n"
    . "  -P          = $loaded\n";
  $properties = new util::ConfigParams( $this->{error_mgr} );
  my @data            = ();
  my $file_properties = $this->{file_properties};
  while ( my ( $property, $value ) = each %{ $this->{properties} } ) {
    $properties->setProperty( $property, $value );
    $value = $properties->getPropertyStr($property);
    ###
    ### only report file properties basenames, if requested.
    ###
    if ( defined( $file_properties->{$property} )
      && !util::Constants::EMPTY_LINE($value) )
    {
      $value = basename($value);
    }
    my $struct = {
      &PROPERTY_COL => $property,
      &VALUE_COL    => $value,
    };
    push( @data, $struct );
  }
  $table->setData(@data);
  ###
  ### Generat Table
  ###
  $table->generateTable($header);
}

################################################################################
#
#                           Public Methods
#
################################################################################

sub new($$;$) {
  my util::Tools $this = shift;
  my ( $error_mgr, $error_categories ) = @_;
  $this = fields::new($this) unless ref($this);
  ###
  ### First, set the basic error messages for util
  ###
  $error_mgr->addErrorMsgs(util::ErrMsgs::ERROR_MSGS);
  $error_mgr->addErrorCats(util::ErrMsgs::ERROR_CATS);
  ###
  ### Now add other error message categories if there are any to add
  ###
  if ( !util::Constants::EMPTY_LINE($error_categories)
    && ref($error_categories) eq util::PerlObject::ARRAY_TYPE
    && @{$error_categories} > 0 )
  {
    foreach my $error_category ( @{$error_categories} ) {
      my $error_msg_class =
        join( util::Constants::DOUBLE_COLON, $error_category, 'ErrMsgs' );
      my $error_cats =
        join( util::Constants::DOUBLE_COLON, $error_msg_class, 'ERROR_CATS' );
      my $error_msgs =
        join( util::Constants::DOUBLE_COLON, $error_msg_class, 'ERROR_MSGS' );
      my @eval_array = (
        'use ' . $error_msg_class . ';',
        '$error_mgr->addErrorMsgs(' . $error_msgs . ');',
        '$error_mgr->addErrorCats(' . $error_cats . ');'
      );
      my $eval_str = join( util::Constants::NEWLINE, @eval_array );
      $error_mgr->printDebug("Constructor:  eval_str=\n$eval_str");
      eval $eval_str;
      my $status = $@;
      $error_mgr->exitProgram(
        ERR_CAT, 1,
        [ $error_msg_class, $status ],
        defined($status) && $status
      );
    }
  }
  ###
  ### Set the execution directory
  ###
  chdir(util::Constants::DOT);
  $this->{execution_dir} = $ENV{PWD};
  ###
  ### Determine name of the executingtool
  ### and absolute path to it
  ###
  ( $this->{script_name}, $this->{script_path} ) = setPath($0);
  ###
  ### Set other attributes
  ###
  $this->{bcp_dir}          = undef;
  $this->{bin}              = $ENV{DEVEL_BIN};
  $this->{cmds}             = new util::Cmd($error_mgr);
  $this->{config_params}    = undef;
  $this->{context}          = [];
  $this->{db}               = undef;
  $this->{die_on_error}     = util::Constants::TRUE;
  $this->{email}            = undef;
  $this->{error_mgr}        = $error_mgr;
  $this->{file_properties}  = {};
  $this->{header}           = util::Constants::EMPTY_STR;
  $this->{logging_file}     = undef;
  $this->{print_properties} = util::Constants::TRUE;
  $this->{print_stats}      = util::Constants::TRUE;
  $this->{properties}       = {};
  $this->{run_status}       = {};
  $this->{start_time}       = time;
  $this->{statuses}         = STATUSES;
  $this->{status}           = undef;
  $this->{table_info}       = {};
  $this->{tool_order}       = [];
  $this->{user_name}        = $ENV{USERNAME};

  $this->{serializer} =
    new util::PerlObject( undef, undef, $this->{error_mgr} );

  $this->setContextProperty(DEBUG_SWITCH_PROP);
  $this->setContextProperty(EXECUTION_DIRECTORY_PROP);
  $this->setContextProperty(LOG_INFIX_PROP);
  $this->setContextProperty(WORKSPACE_ROOT_PROP);

  return $this;
}

sub setContextWithoutOpenLogging {
  my util::Tools $this = shift;
  my ( $config_params, @properties ) = @_;
  ###
  ### Add the standard context and setup properties hash
  ###
  push( @properties, @{ $this->{context} } );
  $this->{properties} = {};
  ###
  ### Get properties
  ###
  my ( $properties, $loadingType, $loaded ) =
    $this->newConfigParams($config_params);
  ###
  ### Get properties and make sure they are defined
  ###
  foreach my $property (@properties) {
    $this->{properties}->{$property} = $properties->getProperty($property);
    $this->exitProgram(
      ERR_CAT, 3,
      [ $loadingType, $loaded, $property ],
      !$properties->containsProperty($property)
    );
  }
  ###
  ### Set debugging if requested
  ###
  $this->{error_mgr}->setDebug if ( $this->{properties}->{&DEBUG_SWITCH_PROP} );
  ###
  ### Set the Execution Focus
  ###
  $this->setExecutionDir( $this->{properties}->{&EXECUTION_DIRECTORY_PROP} );
  ###
  ### At this point, one can use ancillary properties
  ### so that common properties over a set of tools
  ### can be factored out
  ###
  my $ancillaryProperties = $this->getProperty(ANCILLARY_PROPERTIES_PROP);
  if ( !util::Constants::EMPTY_LINE($ancillaryProperties) ) {
    my @aproperties = $this->getPropertySet($ancillaryProperties);
    my ( $aProperties, $aloadingType, $aloaded ) =
      $this->newConfigParams($ancillaryProperties);
    foreach my $property (@aproperties) {
      ###
      ### Properties in the original properties
      ### files overrides the ancillary property
      ### value
      ###
      next if ( exists( $this->{properties}->{$property} ) );
      $this->{properties}->{$property} = $aProperties->getProperty($property);
      $this->exitProgram(
        ERR_CAT, 3,
        [ $ancillaryProperties, $property ],
        !$aProperties->containsProperty($property)
      );
    }
  }
  $this->{config_params} = $loaded;
  return %{ $this->{properties} };
}

sub setContext {
  my util::Tools $this = shift;
  my ( $config_params, @properties ) = @_;
  ###
  ### Set context
  ###
  $this->setContextWithoutOpenLogging( $config_params, @properties );
  ###
  ### Set Log File
  ###
  $this->openLogging(
    $this->{properties}->{&LOG_INFIX_PROP},
    $this->{properties}->{&HEADER_MESSAGE_PROP},
    util::Constants::TRUE
  );
  ###
  ### Printer header message.
  ###
  $this->_printPropertyMessage if ( $this->{print_properties} );

  return %{ $this->{properties} };
}

sub generate {
  my util::Tools $this = shift;
  my ($config_params) = @_;
  foreach my $tool ( $this->getToolOrder ) {
    my $msg        = "Executing $tool";
    my $tool_cmd   = $this->getTool($tool);
    my $cmd        = "$tool_cmd -P $config_params";
    my $cmd_status = $this->executeTool( $cmd, $msg );
    $this->{run_status}->{$tool} = $cmd_status ? FAILED : SUCCEEDED;
  }
}

sub openLogging {
  my util::Tools $this = shift;
  my ( $infix, $header_message, $keep_log ) = @_;

  $keep_log =
    ( !util::Constants::EMPTY_LINE($keep_log) && $keep_log )
    ? util::Constants::TRUE
    : util::Constants::FALSE;
  $infix = util::Constants::EMPTY_LINE($infix) ? $this->getStartTime : $infix;
  my $logging_file = join( util::Constants::SLASH,
    $this->executionDir,
    join( util::Constants::DOT, $this->scriptPrefix, $infix, 'log' ) );
  unlink($logging_file) if ( !$keep_log );
  $this->{error_mgr}->openFile($logging_file);
  my $header = undef;

  if ( util::Constants::EMPTY_LINE( $this->{header} ) ) {
    $header = $this->scriptName;
  }
  else {
    $header = $this->{header};
  }
  if ( util::Constants::EMPTY_LINE($header_message) ) {
    $header_message = util::Constants::EMPTY_STR;
  }
  else {
    $header_message = "$header_message\n\n\n";
  }
  $this->{error_mgr}->printMsg($header);
  $this->{error_mgr}->printHeader( $header_message
      . "STARTED RUN - "
      . $this->getStartTime(util::Constants::TRUE) );
  $this->{logging_file} = $logging_file;
}

sub openLoggingWithLogFile {
  my util::Tools $this = shift;
  my ( $logging_file, $header_message, $keep_log ) = @_;

  $keep_log =
    ( !util::Constants::EMPTY_LINE($keep_log) && $keep_log )
    ? util::Constants::TRUE
    : util::Constants::FALSE;
  $logging_file = getPath($logging_file);
  unlink($logging_file) if ( !$keep_log );
  $this->{error_mgr}->openFile($logging_file);
  my $header = undef;
  if ( util::Constants::EMPTY_LINE( $this->{header} ) ) {
    $header = $this->scriptName;
  }
  else {
    $header = $this->{header};
  }
  if ( util::Constants::EMPTY_LINE($header_message) ) {
    $header_message = util::Constants::EMPTY_STR;
  }
  else {
    $header_message = "$header_message\n\n\n";
  }
  $this->{error_mgr}->printMsg($header);
  $this->{error_mgr}->printHeader( $header_message
      . "STARTED RUN - "
      . $this->getStartTime(util::Constants::TRUE) );
  $this->{logging_file} = $logging_file;

  $this->_printPropertyMessage if ( $this->{print_properties} );
}

sub closeLogging {
  my util::Tools $this = shift;
  $this->{error_mgr}->printStats if ( $this->{print_stats} );
  my $header = undef;
  if ( util::Constants::EMPTY_LINE( $this->{header} ) ) {
    $header = $this->scriptName;
  }
  else {
    $header = $this->{header};
  }
  my $runTime = $this->getRunTime;
  $this->{error_mgr}->printHeader( "Run statistics\n\n"
      . "$header\n\n"
      . "RUN TIME  - $runTime Seconds\n"
      . "ENDED RUN - "
      . $this->getEndTime(util::Constants::TRUE) );
  $this->{error_mgr}->closeFile;
}

sub executeTool {
  my util::Tools $this = shift;
  my ( $cmd, $msg ) = @_;
  my $cmd_status = $this->cmds->executeCommand( { cmd => $cmd }, $cmd, $msg );
  $this->{error_mgr}->registerError( ERR_CAT, 5, [ $msg, $cmd ], $cmd_status )
    if ($cmd_status);
  if ( $cmd_status && $this->getDieOnError ) {
    $this->closeLogging;
    $this->{error_mgr}
      ->hardDieOnError( ERR_CAT, 5, [ $msg, $cmd ], util::Constants::TRUE );
  }
  return $cmd_status;
}

sub terminate {
  my util::Tools $this = shift;
  $this->setStatus(SUCCEEDED) if ( !defined( $this->getStatus ) );
  my $status = $this->getStatus;
  POSIX::_exit(0) if ( $status eq SUCCEEDED );
  POSIX::_exit(2);
}

sub debugStruct {
  my util::Tools $this = shift;
  my ( $title, $struct ) = @_;

  return if ( !$this->{error_mgr}->isDebugging );
  $this->{error_mgr}->printDebug(
    "$title = "
      . $this->serializer->serializeObject(
      $struct, $this->serializer->PERL_OBJECT_WRITE_OPTIONS
      )
  );
}

sub printStruct {
  my util::Tools $this = shift;
  my ( $title, $struct ) = @_;

  $this->{error_mgr}->printMsg(
    "$title = "
      . $this->serializer->serializeObject(
      $struct, $this->serializer->PERL_OBJECT_WRITE_OPTIONS
      )
  );
}

sub exitProgram {
  my util::Tools $this = shift;
  my ( $err_cat, $err_num, $msgs, $error ) = @_;

  my $print_error_msgs = $this->{error_mgr}->printErrorMsgs;
  $this->{error_mgr}->setPrintErrorMsgs(util::Constants::TRUE)
    if ( !$print_error_msgs );
  $this->{error_mgr}->exitProgram( $err_cat, $err_num, $msgs, $error );
  $this->{error_mgr}->setPrintErrorMsgs(util::Constants::FALSE)
    if ( !$print_error_msgs );
}

sub executeCommand {
  my util::Tools $this = shift;
  my ( $header_msg, $cmd ) = @_;

  my $msgs = {
    header => $header_msg,
    cmd    => $cmd,
  };
  $this->mailAndExit( $header_msg,
    $this->cmds->executeCommand( $msgs, $cmd, $header_msg ) );
}

sub mailMsg {
  my util::Tools $this = shift;
  my ( $header, $header_msg, $date, $msg ) = @_;

  my ( $status, $tmp_file ) = $this->cmds->CREATE_TMP_FILE($msg);
  return if ($status);
  $this->mailFile( $header, $header_msg, $date, $tmp_file );
  unlink($tmp_file);
}

sub mailFile {
  my util::Tools $this = shift;
  my ( $header, $header_msg, $date, $file ) = @_;
  ###
  ### Create mail message
  ###
  return if ( !defined( $this->getEmail ) );
  my $subject = join( util::Constants::SPACE,
    "$header($header_msg):  ",
    $this->scriptName, basename( $this->getConfigParams ), $date
  );
  my $msgs = {};
  $msgs->{cmd} = join( util::Constants::SPACE,
    'mail', '-s', '"' . $subject . '"',
    $this->getEmail, '<', $file
  );
  $this->cmds->executeCommand( $msgs, $msgs->{cmd}, 'mailing message' );
}

################################################################################
#
#			       Setter Methods
#
################################################################################

sub getRunTime($) {
  my util::Tools $this = shift;
  $this->{end_time} = time;
  return $this->{end_time} - $this->{start_time};
}

sub saveStatus($$$) {
  my util::Tools $this = shift;
  my ($status_file) = @_;

  $this->setStatus(SUCCEEDED) if ( !defined( $this->getStatus ) );
  $this->exitProgram( ERR_CAT, 7, [$status_file],
    !open( STATUS_OUTPUT, ">$status_file" ) );
  print STATUS_OUTPUT $this->{status} . util::Constants::NEWLINE;
  close(STATUS_OUTPUT);
}

sub setHeader {
  my util::Tools $this = shift;
  my ($header) = @_;
  $this->{header} = $header;
}

sub setPrintProperties {
  my util::Tools $this = shift;
  my ($print_properties) = @_;
  $this->{print_properties} =
    ( !util::Constants::EMPTY_LINE($print_properties) && $print_properties )
    ? util::Constants::TRUE
    : util::Constants::FALSE;
}

sub setPrintStats {
  my util::Tools $this = shift;
  my ($print_stats) = @_;
  $this->{print_stats} =
    ( !util::Constants::EMPTY_LINE($print_stats) && $print_stats )
    ? util::Constants::TRUE
    : util::Constants::FALSE;
}

sub setContextProperty {
  my util::Tools $this = shift;
  my ($property) = @_;
  return if ( util::Constants::EMPTY_LINE($property) );
  push( @{ $this->{context} }, $property );
}

sub setDieOnError {
  my util::Tools $this = shift;
  my ($dieOnError) = @_;
  $this->{die_on_error} =
    ( !util::Constants::EMPTY_LINE($dieOnError) && $dieOnError )
    ? util::Constants::TRUE
    : util::Constants::FALSE;
}

sub setExecutionDir {
  my util::Tools $this = shift;
  my ( $executionDir, $removeDir ) = @_;

  $removeDir =
    ( !util::Constants::EMPTY_LINE($removeDir) && $removeDir )
    ? util::Constants::TRUE
    : util::Constants::FALSE;
  $executionDir =
    $this->{cmds}->createDirectory( $executionDir,
    "Creating Execution Directory $executionDir", $removeDir );
  $this->exitProgram( ERR_CAT, 4, [$executionDir], !chdir($executionDir) );
  $this->{execution_dir} = $executionDir;
}

sub setFileProperties {
  my util::Tools $this = shift;
  my (@file_properties) = @_;
  foreach my $file_property (@file_properties) {
    next if ( util::Constants::EMPTY_LINE($file_property) );
    $this->{file_properties}->{$file_property} = util::Constants::EMPTY_STR;
  }
}

sub setInitializations {
  my util::Tools $this = shift;
  ###############################
  ### RE-IMPLEMENTABLE METHOD ###
  ###############################
  ###
  ### NO-OP
  ###
}

sub setStatus {
  my util::Tools $this = shift;
  my ($status) = @_;

  my $statuses = $this->{statuses};
  $this->exitProgram( ERR_CAT, 6, [$status], !defined( $statuses->{$status} ) );
  $this->{status} = $status;
}

sub setToolOrder {
  my util::Tools $this = shift;
  my ($tool_order) = @_;
  return
    if ( util::Constants::EMPTY_LINE($tool_order)
    || ref($tool_order) ne util::PerlObject::ARRAY_TYPE );
  $this->{tool_order} = [];
  foreach my $tool ( @{$tool_order} ) {
    push( @{ $this->{tool_order} }, $tool );
  }
}

sub setWorkspaceProperty {
  my util::Tools $this = shift;
  my (%properties) = @_;

  my $workspaceRootProp = WORKSPACE_ROOT_PROP;
  my $workspaceRoot     = $this->getProperty($workspaceRootProp);
  my $toolProperties    = $this->{properties};
  return %properties if ( !defined($workspaceRoot) );
  foreach my $property ( keys %properties ) {
    next
      if ( util::Constants::EMPTY_LINE( $properties{$property} )
      || $properties{$property} !~ /^$workspaceRootProp/ );
    $properties{$property} =~ s/^$workspaceRootProp/$workspaceRoot/;
    next if ( !defined( $toolProperties->{$property} ) );
    $toolProperties->{$property} = $properties{$property};
  }
  return %properties;
}

sub setWorkspaceForProperty {
  my util::Tools $this = shift;
  my ($property) = @_;

  my $workspaceRootProp = WORKSPACE_ROOT_PROP;
  my $workspaceRoot     = $this->getProperty($workspaceRootProp);
  return $property
    if ( !defined($workspaceRoot)
    || $property !~ /^$workspaceRootProp/ );
  $property =~ s/^$workspaceRootProp/$workspaceRoot/;
  return $property;
}

sub setEmail {
  my util::Tools $this = shift;
  my ($email) = @_;

  return if ( util::Constants::EMPTY_LINE($email) );
  $this->{email} = $email;
}

sub setProperty {
  my util::Tools $this = shift;
  my ( $property, $value ) = @_;
  $this->{properties}->{$property} = $value;
}

################################################################################
#
#			    Getter Methods
#
################################################################################

sub cmds {
  my util::Tools $this = shift;
  return $this->{cmds};
}

sub executionDir {
  my util::Tools $this = shift;
  return $this->{execution_dir};
}

sub scriptName {
  my util::Tools $this = shift;
  return $this->{script_name};
}

sub scriptPath {
  my util::Tools $this = shift;
  return $this->{script_path};
}

sub scriptPrefix {
  my util::Tools $this = shift;
  my $script_prefix = $this->{script_name};
  $script_prefix =~ s/\.pl$//;
  return $script_prefix;
}

sub serializer {
  my util::Tools $this = shift;
  return $this->{serializer};
}

sub getDieOnError {
  my util::Tools $this = shift;
  return $this->{die_on_error};
}

sub getEndTime {
  my util::Tools $this = shift;
  my ($as_date) = @_;
  return $this->{end_time} if ( !defined( $this->{end_time} ) );
  return $this->_getTime( $this->{end_time}, $as_date );
}

sub getLoggingFile {
  my util::Tools $this = shift;
  return $this->{logging_file};
}

sub getProcessId {
  my util::Tools $this = shift;
  return $$;
}

sub getEmail {
  my util::Tools $this = shift;
  return $this->{email};
}

sub getProperty {
  my util::Tools $this = shift;
  my ($property) = @_;
  return $this->{properties}->{$property};
}

sub getProperties {
  my util::Tools $this = shift;
  my ( $properties_name, $properties_lib ) = @_;
  return $this->_getItem( $properties_name, $properties_lib, PROPERTIES );
}

sub getConfigParams {
  my util::Tools $this = shift;
  return $this->{config_params};
}

sub getScript {
  my util::Tools $this = shift;
  my ( $tool_name, $tool_lib ) = @_;
  return $this->_getItem( $tool_name, $tool_lib, SCRIPTS );
}

sub getStartTime {
  my util::Tools $this = shift;
  my ($as_date) = @_;
  return $this->_getTime( $this->{start_time}, $as_date );
}

sub getTool {
  my util::Tools $this = shift;
  my ( $tool_name, $tool_lib ) = @_;
  return $this->_getItem( $tool_name, $tool_lib, TOOLS );
}

sub getStatus {
  my util::Tools $this = shift;
  my ($status) = @_;
  return $this->{status};
}

sub getStatusFile($$) {
  my util::Tools $this = shift;
  my ($status_file) = @_;

  $this->exitProgram( ERR_CAT, 8, [$status_file],
    !open( STATUS_FILE, "<$status_file" ) );
  my $status = <STATUS_FILE>;
  chomp($status);
  close(STATUS_FILE);

  return $status;
}

sub getUserName {
  my util::Tools $this = shift;
  return $this->{user_name};
}

sub getXml {
  my util::Tools $this = shift;
  my ( $xml_name, $xml_lib ) = @_;
  return $this->_getItem( $xml_name, $xml_lib, XML );
}

sub getRunStatus {
  my util::Tools $this = shift;
  my ($tool) = @_;
  return $this->{run_status}->{$tool};
}

sub getToolOrder {
  my util::Tools $this = shift;
  return @{ $this->{tool_order} };
}

sub getErrorMgr {
  my util::Tools $this = shift;
  return $this->{error_mgr};
}

sub newConfigParams {
  my util::Tools $this = shift;
  my ($config_params) = @_;

  my $properties         = new util::ConfigParams( $this->{error_mgr} );
  my $config_params_file = getPath($config_params);
  my $loadingType        = undef;
  my $loaded             = undef;
  if ( -e $config_params_file ) {
    $loadingType = FILE_TYPE;
    $loaded      = $config_params_file;
    $properties->loadFile($config_params_file);
  }
  else {
    $loadingType = MODULE_TYPE;
    $loaded      = $config_params;
    $properties->configModule($config_params);
  }
  return ( $properties, $loadingType, $loaded );
}

sub getPropertySet {
  my util::Tools $this = shift;
  my ($config_params) = @_;

  my ( $properties, $loadingType, $loaded ) =
    $this->newConfigParams($config_params);
  my $property_set = $properties->getProperty(PROPERTY_SET_PROP);
  return ( sort @{$property_set} )
    if ( ref($property_set) eq $this->serializer->ARRAY_TYPE );
  return ();
}

################################################################################
#
#		    Database Specific Methods
#
################################################################################

sub getSession {
  my util::Tools $this = shift;
  return $this->{db};
}

sub openSessionExplicit {
  my util::Tools $this = shift;
  my ( $serverType, $databaseName, $userName, $password, $schemaOwner ) = @_;
  ###
  ### Close session if necessary.
  ###
  $this->closeSession if ( defined( $this->{db} ) );
  ###
  ### Open database session
  ###
  $this->{db} =
    new util::Db( $serverType, $databaseName, $userName, $password,
    $schemaOwner, $this->{error_mgr} );
  ###
  ### Set long read length
  ###
  my $server = $this->{db}->getServer;
  if ( $server eq 'OracleDB' ) {
    $this->{db}->setLongReadLen( $this->{db}->LOB_LENGTH );
  }
  ###
  ### Initialize Database Data, as necessary
  ###
  $this->setInitializations;
}

sub openSession {
  my util::Tools $this = shift;
  my ($force_open) = @_;
  ###
  ### Check to see if session is openable
  ###
  my $serverType   = $this->{properties}->{&SERVER_TYPE_PROP};
  my $databaseName = $this->{properties}->{&DATABASE_NAME_PROP};
  my $userName     = $this->{properties}->{&USER_NAME_PROP};
  my $password     = $this->{properties}->{&PASSWORD_PROP};
  my $schemaOwner  = $this->{properties}->{&SCHEMA_OWNER_PROP};
  return
    if ( util::Constants::EMPTY_LINE($serverType)
    || util::Constants::EMPTY_LINE($databaseName)
    || util::Constants::EMPTY_LINE($userName)
    || util::Constants::EMPTY_LINE($password)
    || util::Constants::EMPTY_LINE($schemaOwner) );
  ###
  ### Check to see if return immediately
  ###
  $force_open =
    ( !util::Constants::EMPTY_LINE($force_open) && $force_open )
    ? util::Constants::TRUE
    : util::Constants::FALSE;
  return if ( !$force_open && defined( $this->{db} ) );
  ###
  ### Close session if necessary.
  ###
  $this->closeSession if ( defined( $this->{db} ) );
  ###
  ### Open database session
  ###
  $this->{db} =
    new util::Db( $serverType, $databaseName, $userName, $password,
    $schemaOwner, $this->{error_mgr} );
  ###
  ### Set long read length
  ###
  my $server = $this->{db}->getServer;
  if ( $server eq 'OracleDB' ) {
    $this->{db}->setLongReadLen( $this->{db}->LOB_LENGTH );
  }
  ###
  ### Initialize Database Data, as necessary
  ###
  $this->setInitializations;
}

sub closeSession {
  my util::Tools $this = shift;

  return if ( !defined( $this->{db} ) );
  $this->{db}->closeSession;
  $this->{db} = undef;
}

sub startTransaction {
  my util::Tools $this = shift;
  my ($force_open) = @_;

  $this->openSession($force_open);
  my $db = $this->getSession;
  $db->startTransaction;
  return $db;
}

sub finalizeTransaction {
  my util::Tools $this = shift;
  my ($msg) = @_;

  my $db = $this->getSession;
  $db->finalizeTransaction($msg);
  $this->{db} = undef;
}

sub rollbackTransaction {
  my util::Tools $this = shift;
  my ($msg) = @_;

  my $db = $this->getSession;
  $db->rollbackAndClose;
  $this->{db} = undef;
}

################################################################################
#
#                        Database Loader Methods
#
################################################################################

sub getBcpDir {
  my util::Tools $this = shift;

  return $this->{bcp_dir} if ( defined( $this->{bcp_dir} ) );
  $this->setBcpDir( $this->getBcpDirectoryRoot );
  return $this->{bcp_dir};
}

sub getBcpDirectoryRoot {
  my util::Tools $this = shift;
  return join( util::Constants::SLASH,
    $this->executionDir, 'bcp.db', $this->scriptPrefix );
}

sub getTableInfo {
  my util::Tools $this = shift;
  return $this->{table_info};
}

sub setBcpDir {
  my util::Tools $this = shift;
  my ($bcp_directory) = @_;
  return if ( util::Constants::EMPTY_LINE($bcp_directory) );
  $this->{bcp_dir} = $bcp_directory;
}

sub setTableInfo {
  my util::Tools $this = shift;
  my ($table_info) = @_;
  return
    if ( util::Constants::EMPTY_LINE($table_info)
    || ref($table_info) ne util::PerlObject::HASH_TYPE );
  $this->{table_info} = $table_info;
}

sub createBcpDir {
  my util::Tools $this = shift;
  $this->setBcpDir(
    $this->cmds->createDirectory(
      $this->getBcpDir, "Creating BCP directory = " . $this->getBcpDir,
      util::Constants::TRUE
    )
  );
}

sub getLoader {
  my util::Tools $this = shift;
  my ( $className, $directory, $fileName, @params ) = @_;
  ###
  ### Create the bcp directory
  ###
  my $bcpClassName = $className;
  $bcpClassName =~ s/::/./g;
  $this->setBcpDir(
    join( util::Constants::SLASH, $this->getBcpDirectoryRoot, $bcpClassName ) );
  $this->createBcpDir;
  ###
  ### Create the Class Name
  ###
  my $class = 'db::Schema::Generate::Loader::' . $className;
  ###
  ### Set the file name, if any (both directory and file must be defined
  ###
  my $file       = undef;
  my $file_param = util::Constants::EMPTY_STR;
  if ( !util::Constants::EMPTY_LINE($directory)
    && !util::Constants::EMPTY_LINE($fileName) )
  {
    $file = join( util::Constants::SLASH, $directory, $fileName );
    $file_param = '$file,';
  }
  my $params_param = util::Constants::EMPTY_STR;
  if ( @params != 0 ) {
    foreach my $index ( 0 .. $#params ) {
      $params_param .= ' $params[' . $index . '],';
    }
  }
  ###
  ### Create the loader
  ###
  my $loader     = undef;
  my @eval_array = (
    'use ' . $class . ';',
    '$loader =',
    'new ' . $class,
    '  (' . $file_param,
    '   $this,', $params_param, '   $this->{error_mgr});'
  );
  my $eval_str = join( util::Constants::NEWLINE, @eval_array );
  $this->{error_mgr}->printDebug("getLoader:  eval_str=\n$eval_str");
  eval $eval_str;
  my $status = $@;
  $this->{error_mgr}->hardDieOnError(
    ERR_CAT, 9,
    [ $status, $eval_str ],
    defined($status) && $status
  );
  ###
  ### Return the loader
  ###
  return $loader;
}

sub runLoader {
  my util::Tools $this = shift;
  my ( $className, $directory, $fileName, @params ) = @_;
  ###
  ### Create the loader
  ###
  my $loader = $this->getLoader( $className, $directory, $fileName, @params );
  ###
  ### Generate and load the data.
  ###
  $loader->generate;
  $loader->load;
}

sub runUpdater {
  my util::Tools $this = shift;
  my ( $className, $directory, $fileName, @params ) = @_;
  ###
  ### Create the loader
  ###
  my $loader = $this->getLoader( $className, $directory, $fileName, @params );
  ###
  ### Generate and update the data.
  ###
  $loader->generate;
  $loader->update;
}

sub openLoader {
  my util::Tools $this = shift;
  my (@use_tables)     = @_;
  my $server           = $this->getSession->getServer;
  my $class            = undef;
  if    ( $server eq 'OracleDB' ) { $class = 'db::Schema::Load::Oracle'; }
  elsif ( $server eq 'mySQL' )    { $class = 'db::Schema::Load::MySql'; }
  my $loader     = undef;
  my @eval_array = (
    'use ' . $class . ';',
    '$loader =',
    'new ' . $class,
    '  ($this->getTableInfo,',
    '   $this->getBcpDir,',
    '   $this->getSession,',
    '   $this->{error_mgr},',
    '   @use_tables);'
  );
  my $eval_str = join( util::Constants::NEWLINE, @eval_array );
  $this->{error_mgr}->printDebug("openLoader:  eval_str=\n$eval_str");
  eval $eval_str;
  my $status = $@;
  $this->{error_mgr}->hardDieOnError(
    ERR_CAT, 9,
    [ $status, $eval_str ],
    ( defined($status) && $status ) || !defined($loader)
  );
  return $loader;
}

################################################################################

1;

__END__

=head1 NAME

Tools.pm

=head1 DESCRIPTION

This class defines the basics capabilities for running tools.

=head1 STATIC CONSTANTS

The following status constants are exported from the this class:

The following suffixes are exported:

   util::Tools::MODULE     -- pm
   util::Tools::PERL       -- pl
   util::Tools::PROPERTIES -- properties
   util::Tools::TABLES     -- tables
   util::Tools::SCRIPTS    -- scripts
   util::Tools::TOOLS      -- tools
   util::Tools::XML        -- xml

The following types of properties for a property manager are exported:

   util::Tools::DEFAULT_PROPERTIES -- defaults
   util::Tools::TOOLS_PROPERTIES   -- tools

The following status flags are exported:

   util::Tools::FAILED    -- FAILED
   util::Tools::SUCCEEDED -- SUCCEEDED

The basic set of context properties are exported:

   util::Tools::DEBUG_SWITCH_PROP        -- debugSwitch
   util::Tools::EXECUTION_DIRECTORY_PROP -- executionDirectory
   util::Tools::HEADER_MESSAGE_PROP      -- headerMessage
   util::Tools::LOG_INFIX_PROP           -- logInfix
   util::Tools::WORKSPACE_ROOT_PROP      -- workspaceRoot

   util::Tools::SERVER_TYPE_PROP         -- serverType
   util::Tools::DATABASE_NAME_PROP       -- databaseName
   util::Tools::USER_NAME_PROP           -- userName
   util::Tools::PASSWORD_PROP            -- password
   util::Tools::SCHEMA_OWNER_PROP        -- schemaOwner

The following property message table properties:

   util::Tools::PROPERTY_COL -- Property
   util::Tools::VALUE_COL    -- Value

   util::Tools::MSG_COLS returns the ordered list
     util::Tools::PROPERTY_COL
     util::Tools::VALUE_COL

=head1 METHODS

The following methods are exported by this class.

=head2 B<new util::Tools(error_mgr[, error_categories])>

This is the constructor for the class.  This method sets the following
scripting information: start_time (the current Linux time), and
standard bin directory (environment variable B<$DEVEL_BIN>), execution
directory (environment variable B<$PWD>), and the script name
executing this class.  Also, the standard context properties include
at a minimum:

   util::Tools::DEBUG_SWITCH_PROP        -- debugSwitch
   util::Tools::EXECUTION_DIRECTORY_PROP -- executionDirectory
   util::Tools::LOG_INFIX_PROP           -- logInfix

The optional parameter B<error_categories> if defined and a non-empty
referenced Perl array, then add error messages and categories to the
B<error_mgr> (an instance of B<util::ErrMgr>).  Each error categories
is a library name in which the static class B<library::ErrMsgs> is
defined and this class must contains the static methods
B<library::ErrMsgs::ERROR_MGS> and B<library::ErrMsgs::ERROR_CATS>.

=head2 B<%properties = setContext(config_params, @properties)>

This method sets the standard execution context for a tool.  It
assumes that the B<config_params> contains at a minimum the
following context properties:

   debugSwitch        -- boolean debugging switch
   executionDirectory -- the execution directory focus
   logInfix           -- logging file infix to use

This method also guarantees that the list of properties B<@properties>
also exists in the properties file and creates a B<%properties> hash
containing the context properties and the properties in the
B<@properties> list and returns it as a Perl hash.  Also, it sets the
execution directory (B<executionDirectory>), the debugging mode
(B<debugSwitch>), and opens the logging file using the B<logInfix> and
and B<headerMessage>.  Finally, it prints the properties_file into the
log if print_properties is TRUE (1).

=head2 B<generate(properties_file)>

This method executes each of the tools in the B<tool_order> attribute
list serially in order.  This method provides the tool with
B<properties_file> using the B<-P> option.  Each tool is determined
using tool name in the list and bin directory determined by the
constructor.

=head2 B<openSession([force_open])>

This method opens the db session and initializes data if the
B<dbConfigFile> property has been set by a subclass or object
before the method 
L<"%properties = setContext(properties_file, @properties)">
has been executed.

This method opens the db session if it is not already open, executes
the re-implementable method L<"setInitializations">, and sets long
read length.  If B<force_open> is not present or is FALSE (0) and the
db session is already open, the method is a no-op and returns
immediately.  Otherwise, it closes the current session, as necessary,
and opens a new session.

=head2 B<closeSession>

If a database session has been opened, this method closes it.

=head2 B<openLogging([infix[, header_message]]>

This method opens the standard logging file for the executing tool:

   <execution_dir>/<script_prefix>.<infix>.log

If infix is empty or undefined, then the start time (B<getStartTime>)
is used as the infix.  If the B<header> is defined (see
L<"setHeader(header)">), then it is written as the first line of the
log, othewise the script filename executing this class is written to
the log.  If the B<header_message> is defined, then a header is
generated with B<header_message> and start time and is written to the
log, othewise a header is generated with script filename and the start
time and is written to the log file.

=head2 B<closeLogging>

This method write the B<error_mgr> statistics if the B<print_stats>
attribute is TRUE (1).  Then it sets the run time, and writes standard
final header message to the log file including the B<header> (see
L<"setHeader(header)">) and run time.  Finally, it closes the log
file.

=head2 B<$cmd_status = executeTool(cmd, msg)>

This method executes the cmd with the message as a child process.  If
the child fails, then an error is recorded into the log.  Moreover, if
the child fails and the B<die_on_error> attribute is set to TRUE (1),
then the parent (this script) also fails.  In this case, before the
parent fails, the log is closed.  The attribute B<die_on_error> is set,
by default, to be TRUE (1).  The attribute B<dieOnEror> can be changed
and accessed by the methods B<setDieOnError>, and B<getDieOnError>,
respectively.

This method returns the command status, TRUE(1) if tool failed,
FALSE(0) if it succeeded.

=head2 B<terminate>

This method terminates the script using POSIX exit.  If the status
is not set or set to B<SUCCEEDED>, then it terminates with status
zero (0), else it terminates with status two (2).

=head2 B<debugStruct(title, struct)>

This method write the serialized version of the Perl data-structure
struct to the log if debugging is set.

=head2 B<printStruct(title, struct)>

This method write the serialized version of the Perl data-structure
struct to the log.

=head2 B<exitProgram(err_cat, err_num, msgs, error)>

This method executes the L<util::ErrMgr> method B<exitProgram> while
managing the whether error messages are to be printed or not.

=head1 SETTER METHODS

The following methods are exported by this class.

=head2 B<$run_seconds = getRunTime>

This method sets the B<end_time> and then returns the number of
seconds since the class was instantiated.

=head2 B<saveStatus(status_file)>

This method save the current status in the B<status_file>.  If the
status is not set, then it is set to B<SUCCEEDED> and stored in the
file.

=head2 B<setHeader(header)>

This method sets the header to write out at the beginning and at the
end of the log file when reporting run time information.

=head2 B<setPrintProperties(print_properties)>

This method toggles whether the properties file content is printed at
the beginning of the log file (print_properties TRUE(1)) or not
(print_properties FALSE(0)).  This method manages the
B<print_properties> attribute.

=head2 B<setPrintStats(print_stats)>

This method toggles whether the B<error_mgr> statistics are generated
at the end of the log file before closing the log file.  If
print_stats is TRUE(1)), then it is printed, otherwise (FALSE (0)) it
is not.  This method manages the B<print_stats> attribute.

=head2 B<setContextProperty(property)>

This method adds another context property to the basic set of context
properties:

   debugSwitch        -- boolean debugging switch
   executionDirectory -- the execution directory focus
   logInfix           -- logging file infix to use

=head2 B<setDieOnError(dieOnError)>

This method sets the attribute B<die_on_error>.  If B<dieOnError> is
defined and TRUE (1), then it sets the attribute B<die_on_error> to
TRUE (1), otherwise it sets the attribute to FALSE (0);

=head2 B<setExecutionDir(executionDir[, remove_dir])>

This method sets the execution directory focus to B<executionDir>.  If
the directory does not exist, then it is created.  If there is an
error in creating the directory or set the focus to the directory,
then this method causes the program to terminate abnormally.  If the
B<remove_dir> parameter is present and TRUE (1), then the existing
execution directory is removed before it is created, otherwise the
execution directory is left 'as-is'.

=head2 B<setFileProperties(@file_properties)>

This method set the B<file_properties> attribute to the list of file
properties so that when the properties are written to the log, only
the basename of these properties is shown.

=head2 B<setInitializations>

This re-implementable method is used by openSession to initialize
specific information after a database session is opened using the
method B<openSession>.  The default implementation is a NO-OP.

=head2 B<setStatus(status_file, status)>

This method sets the B<status> (either B<SUCCEEDED> OR B<FAILED>) and
write it to the B<status_file>.

=head2 B<setToolOrder(tool_order)>

If B<tool_order> is a referenced Perl array, then the tool order is
re-initialized and each tool name in the array is added in order to
the B<tool_order> attribute to be used by the
L<"generate(properties_file)"> method.

=head2 B<%properties = setWorkspaceProperty(%properties)>

If the B<workspaceRoot> property is defined, then this method replaces
the prefix B<workspaceRoot> in each property in B<%properties> with the
values of the B<workspaceRoot> property, otherwise it returns
B<%properties> unchanged.

=head2 B<$property = setWorkspaceForProperty(property)>

If the B<workspaceRoot> property is defined, then this method replaces
the prefix B<workspaceRoot> in the property and returns it, otherwise
it returns the property unchanged.

=head1 GETTER METHODS

The following methods are exported by this class.

=head2 B<$cmds = cmds>

This method returns an instance of the B<util::Cmd> class.

=head2 B<$executionDir = executionDir>

This method returns the execution directory of the executing script.

=head2 B<$scriptName = scriptName>

This method returns the name of the executing script

=head2 B<$scriptPath = scriptPath>

This method returns the path to executing script.

=head2 B<$scriptPrefix = scriptPrefix>

This method returns the script name prefix (without '.pl').

=head2 B<$serializer = serializer>

This method returns Perl serializer object (instance of
L<util::PerlObject>).

=head2 B<getDieOnError>

This method returns TRUE (1) if B<die_on_error> is TRUE(1),
otherwise it returns FALSE (0).  The default value for this attribute
is TRUE (1).

=head2 B<$end_time = getEndTime([as_date])>

If B<as_date> is missing or FALSE (0), then this method returns the
Linux end_time, otherwise it returns its (oracle) date string.  If the
end time is not defined, then undef if returned.

=head2 B<$value = getProperty(property)>

This method returns the value of the property that has been stored
into the object by B<setContext> method.

=head2 Bxo<$properties_path = getProperties(properties_name, properties_lib)>

This method returns the properties file for the given properties name
and library.  It guarantees that the properties file

   properties_lib/properties_name.properties

exists and it readable.

=head2 B<$db_session = getSession>

This method returns the database session created by the object.

=head2 B<$script_path = getScript(tool_name, tool_lib)>

This method returns the tool for the given tool name and library.  It
guarantees that the tool

   tool_lib/tool_name

exists and is executable.

=head2 B<$start_time = getStartTime([as_date])>

If B<as_date> is missing or FALSE (0), then this method returns the
Unix start time, otherwise it returns its (oracle) date string.

=head2 B<$tool_path = getTool(tool_name, tool_lib)>

This method returns the tool for the given tool name and library.  It
guarantees that the tool

   tool_lib/tool_name.pl

exists and is executable.

=head2 B<$status = getStatus>

This method returns the status that is currently set.

=head2 B<$status = getStatusFile(status_file)>

This method returns the status for a given status file.

=head2 B<$user_name = getUserName>

This method returns the user name of the executing process.

=head2 B<$xml_path = getXml(xml_name, $xml_lib)>

This method returns the xml file for the given xml name and library.
It guarantees that the xml file

   xml_lib/xml_name.xml

exists and it readable.

=head2 B<$run_status = getRunStatus(tool)>

This method returns the run status (FAILED or SUCCEEDED) for the given
tool.  If the tool has not been run, then undef is returned.

=head2 B<@tool_order = getToolOrder>

This method returns the current tool list assigned to this object.

=head2 B<$error_mgr = getErrorMgr>

This method the B<error_mgr> object for this class.

=cut
