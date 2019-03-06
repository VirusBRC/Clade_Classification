package util::Utils;

use strict;

use base qw(Exporter);
use vars qw(@EXPORT);

@EXPORT = qw(&error
&warning
&HashThis
&safeExternalOpen
&debug
&verbose
&setVerbose
&setDebug
&setQuiet
&logThis
&setLogging
&ArrayThese
);

my $error_log    = $main::ERRORLOG || '-';
setLogging(1);  #Logging is on by default
my $admin_emails = $main::ADMIN_EMAIL;
my($verbose,$DEBUG,$quiet,$logging);


sub getSequenceFromFasta{

    my $inputFile = shift;

    unless(defined $inputFile && -e $inputFile){
        return undef;
    }

    my @result=();

    my ($seq,$isdid);

    open F,"<$inputFile" or die "Cannot open file $inputFile";

    while(<F>){
        $_ = util::Utils::trim($_);

        if ( /^>/) {   
            $_ =~ s/>//;
            my @r = ($isdid,$seq);
            push(@result, \@r ) if(defined $isdid);
            $isdid = $_;
            $seq = "";              
        }else {
            $seq .= $_;    # other lines add to seq
        }
    }

    my @r= ($isdid,$seq);
    push (@result, \@r) if (defined $isdid && defined $seq);

    return \@result;
}

sub setVerbose     {$verbose = $_[0]}
sub setDebug    {$DEBUG   = $_[0]}
sub setQuiet     {$quiet   = $_[0]}
sub setLogging    {$logging = $_[0]}






#copied from perl_script_template.pl on 4/24/2007 and modified (heavily)
##
## Subroutine that prints errors with a leading program identifier containing a
## trace route back to main to see where all the subroutine calls were from,
## the line number of each call, an error number, and the name of the files
## which generated the error.  It stores the number of errors in a variable in
## main and uses two other variables that may be in main ($verbose and $quiet -
## treated as booleans).
##
sub error
{
    return(0) if($quiet);

    #Gather and concatenate the error message and split on hard returns
    my @error_message = split("\n",join('',grep {ref($_) eq ''} @_));
    pop(@error_message) if($error_message[-1] !~ /\S/);

    #Find the parameters hash and set the notify and log flags
    my($params_hash)  = grep {ref($_) eq 'HASH'} @_;
    my $notify_flag   = $params_hash->{NOTIFY};
    my $log_flag      = $params_hash->{LOG};

    #Store a global error number that is the same for all instances
    $main::error_number++;

    my $script = $0;
    $script =~ s/^.*\/([^\/]+)$/$1/;

    #Assign the values from the calling subroutines/main
    #caller() does things a little back-asswards in my opinion.  The line
    #number, file name, and isrequire values reported for one stack level seem
    #to correspond with the called sub of the next stack level (where the sub
    #is located).  So I'm getting the info for the first level and then
    #starting the loop and getting the subroutine from the next level.
    my @caller_info   = caller(0);
    my $line_num      = $caller_info[2];
    my $filename      = $caller_info[1];
    my $package       = $caller_info[0];
    my $isrequire     = $caller_info[7];
    my $caller_string = '';
    my $stack_level   = 1;
    my($calling_sub,$last_filename);
    my $mason_flag    = 0;

    while(@caller_info = caller($stack_level))
    {
        #Get rid of the path in front of the script
        $filename =~ s/^.*\/([^\/]+)$/$1/;

        #If we run into mason components, don't trace them and set the mason
        #flag to true
        if($filename eq 'Interp.pm'    ||
            $filename eq 'Component.pm' ||
            $filename =~ /mason/i)
        {
            $mason_flag = 1;
            last;
        }

        #Determine the name of the subroutine that was called on $line_num
        $calling_sub  = $caller_info[3];
        #Get rid of the module hierarchy
        $calling_sub =~ s/^.*::// if(defined($calling_sub));

        #Only report a trace level if it refers to a specific line number
        if(defined($line_num) && $line_num != 0)
        {
            #If this is a new file in the trace, add it to the string
            if(!defined($last_filename) || $filename ne $last_filename)
            {$caller_string .= (defined($last_filename) ? ']:' : '') .
                "$filename\["}
            else
            {$caller_string .= ','}

            #Add the line num where the error originated (at this stack level)
            $caller_string .= "LINE$line_num";

            #If the line num is inside a subroutine, add it in parentheses
            if(defined($calling_sub)     &&
                $calling_sub ne 'BEGIN'   &&
                $calling_sub ne '(eval)'  &&
                !$isrequire)
            {$caller_string .= "($calling_sub)"}
        }

        #Store the last filename so we can tell when we've jumped to a new file
        $last_filename = $filename;

        #Get caller info for the next call
        $line_num = $caller_info[2];
        $filename = $caller_info[1];
        $package  = $caller_info[0];

        #Increment the stack level
        $stack_level++;
    }

    #Add the last call if it was directly from main, or just finish off the
    #last one
    if(!defined($calling_sub) ||
        ($calling_sub ne '(eval)' && $line_num == 0))
    {$caller_string .= "$script\[$package(LINE$line_num)]: "}
    else
    {$caller_string .= ']: '}

    #Put the whole leader string together
    my $leader_string = "ERROR$main::error_number:$caller_string";

    #Figure out the length of the first line of the error
    my $error_length = length(($error_message[0] =~ /\S/ ?
            $leader_string : '') .
        $error_message[0]);

    #Put location information at the beginning of each line of the message
    foreach my $line (@error_message)
    {
        my $message = ($line =~ /\S/ ? $leader_string : '') .
        $line .
        ($verbose &&
            defined($main::last_verbose_state) &&
            $main::last_verbose_state ?
            ' ' x ($main::last_verbose_size - $error_length) : '') .
        "\n";
        if($mason_flag)
        {warn($message)}
        else
        {print STDERR ($message)}
        logThis($message);
    }

    #Reset the verbose states if verbose is true
    if($verbose)
    {
        $main::last_verbose_size  = 0;
        $main::last_verbose_state = 0;
    }

    #Return success
    return(0);
}

##
## Subroutine that prints warnings with a leader string containing a warning
## number
##
sub warning
{
    return(0) if($quiet);

    $main::warning_number++;

    #Gather and concatenate the warning message and split on hard returns
    my @warning_message = split("\n",join('',@_));
    pop(@warning_message) if($warning_message[-1] !~ /\S/);

    my $leader_string = "WARNING$main::warning_number: ";

    #Figure out the length of the first line of the error
    my $warning_length = length(($warning_message[0] =~ /\S/ ?
            $leader_string : '') .
        $warning_message[0]);

    #Put leader string at the beginning of each line of the message
    foreach my $line (@warning_message)
    {
        print STDERR (($line =~ /\S/ ? $leader_string : ''),
            $line,
            ($verbose &&
                defined($main::last_verbose_state) &&
                $main::last_verbose_state ?
                ' ' x ($main::last_verbose_size - $warning_length) :
                ''),
            "\n");
        logThis(($line =~ /\S/ ? $leader_string : ''),
            $line,
            ($verbose &&
                defined($main::last_verbose_state) &&
                $main::last_verbose_state ?
                ' ' x ($main::last_verbose_size - $warning_length) : ''),
            "\n");
    }

    #Reset the verbose states if verbose is true
    if($verbose)
    {
        $main::last_verbose_size = 0;
        $main::last_verbose_state = 0;
    }

    #Return success
    return(0);
}

##Copied from webfiles.pm and modified 4/30/2007 - Rob
#
#  Name:        HashThis
#  Usage:       HashThis(<Filenames>)
#  Purpose:     Creates a simple hash from a 2 column, tab delimited file - key
#               followed by value
#  Takes:       A list of filenames
#  Returns:     One hash reference with all the keys and values from the files
#
#  Author:      Robert Leach
#  Company:     LANL
#  Date:        9/8/2000
#
sub HashThis
{
    use strict;

    my($file,$key,$val);
    my $hash = {};

    unless(@_ > 0)
    {
        error("This subroutine has not received a file name.");
        return($hash);
    }

    my @files = @_;

    foreach $file (@files)
    {
        unless(open(FILE,$file))
        {
            error("Could not open file: [$file].\n$!");
            return($hash);
        }
        while(<FILE>)
        {
            next if(/^\#/ || /^\s*$/);
            chomp;
            ($key,$val) = (/^ *(.+?) *\t *(.*?) *$/g);
            if(!$key)
            {($key) = (/^ *(.*?) *$/);$val = ''}
            $hash->{$key} = $val if($key =~ /\S/);
        }
        close FILE;
    }

    return(wantarray ? %$hash : $hash);
}


sub safeExternalOpen
{
    my $file_handle          = $_[0];
    my $unvalidated_filename = $_[1];
    my $write_flag           = $_[2]; #Assumed provided by code
    my($validated_filename);
    my $message_array = [];

    if(isValidExternalFilename($unvalidated_filename,$message_array))
    {error(@$message_array)}
    else
    {
        $validated_filename = $unvalidated_filename;

        if(!open($file_handle,
                ($write_flag ? '>' : '') . $validated_filename))
        {
            error("Unable to open file: [$validated_filename].  $!");
            return(0);
        }
    }

    return(1);
}


sub isValidExternalFilename
{
    my @safe_paths    = map {my $x=$_;$x=~s/\/+$//;$x} ('../share','/tmp','/tmp/profileBlast');
    my $safe_paths_pattern = '^(' . join('|',map {quotemeta($_)} @safe_paths) .
    ')\/';
    my $filename      = $_[0];
    my $message_array = $_[1];
    my $problem       = 0;
    my($err_msg);

    if(scalar(@_) > 1 && ref($message_array) ne 'ARRAY')
    {warning("The message array sent in must be defined as an empty array.")}

    if($filename =~ /[^A-Za-z0-9_\.\-\/]/)
    {
        my @chars = ($filename =~ /([^A-Za-z0-9_\.\-\/])/g);
        $err_msg = "Unsafe characters have been found in your file " .
        "path/name: [@chars].  Please edit the file path/name and try " .
        "again.";
        push(@$message_array,$err_msg);

        #Report an error unless it's due to white spaces
        error("An attempt was made to 'open' this 'file' which contains ",
            "illegal characters: [$filename].  Illegal characters ",
            "found: [@chars].")
        unless(scalar(grep {/\s/} @chars) == scalar(@chars));
                    $problem++;
                    }
                    if($filename !~ /$safe_paths_pattern[^\/]*$/)
                    {
                    $err_msg = "The file path is not one of the preconfigured " .
                    "'safe paths'.";
                    push(@$message_array,$err_msg);
                    error("An attempt to open this file: [$filename] failed ",
                    "because it didn't match a safe path, but it was caught ",
                    "by safeOpen.  Update the \@safe_paths array in this ",
                    "subroutine (indicated by the trace) if you feel this file ",
                    "should be readable and writable to the world.  otherwise, ",
                    "do not use safeOpen to open it.  Use safeOpen when ",
                    "opening cache files and user input file paths.");
                    $problem++;
                    }
                    if($filename =~ /[^\/\.]\/+\.\.(\/|\Z)/)
                {
                    $err_msg = "The file path contains inappropriate parent directory references.";
                    push(@$message_array,$err_msg);
                    error("An attempt to open this file: [$filename] failed ",
                        "because it appears to contain inappropriate \"../'s\".");
                    $problem++;
                }

                return($problem);
            }


##
## This subroutine allows the user to print debug messages containing the line
## of code where the debug print came from and a debug number.  Debug prints
## will only be printed (to STDERR) if the debug option is supplied on the
## command line.
##
            sub debug
            {
                return(0) unless($DEBUG);

                $main::debug_number++;

                #Gather and concatenate the error message and split on hard returns
                my @debug_message = split("\n",join('',@_));
                pop(@debug_message) if($debug_message[-1] !~ /\S/);

                #Assign the values from the calling subroutine
                #but if called from main, assign the values from main
                my($junk1,$junk2,$line_num,$calling_sub);
                (($junk1,$junk2,$line_num,$calling_sub) = caller(1)) ||
                (($junk1,$junk2,$line_num) = caller());

                #Edit the calling subroutine string
                $calling_sub =~ s/^.*?::(.+)$/$1:/ if(defined($calling_sub));

                my $leader_string = "DEBUG$main::debug_number:LINE$line_num:" .
                (defined($calling_sub) ? $calling_sub : '') .
                ' ';

                #Figure out the length of the first line of the error
                my $debug_length = length(($debug_message[0] =~ /\S/ ?
                        $leader_string : '') .
                    $debug_message[0]);

                #Put location information at the beginning of each line of the message
                foreach my $line (@debug_message)
                {print STDERR (($line =~ /\S/ ? $leader_string : ''),
                        $line,
                        ($verbose &&
                            defined($main::last_verbose_state) &&
                            $main::last_verbose_state ?
                            ' ' x ($main::last_verbose_size - $debug_length) : ''),
                        "\n")}

                #Reset the verbose states if verbose is true
                if($verbose)
                {
                    $main::last_verbose_size = 0;
                    $main::last_verbose_state = 0;
                }

                #Return success
                return(0);
            }


##
## Subroutine that prints formatted verbose messages.  Specifying a 1 as the
## first argument prints the message in overwrite mode (meaning subsequence
## verbose, error, warning, or debug messages will overwrite the message
## printed here.  However, specifying a hard return as the first character will
## override the status of the last line printed and keep it.  Global variables
## keep track of print length so that previous lines can be cleanly
## overwritten.
##
            sub verbose
            {
                return(0) unless($verbose);

                #Read in the first argument and determine whether it's part of the message
                #or a value for the overwrite flag
                my $overwrite_flag = $_[0];

                #If a flag was supplied as the first parameter (indicated by a 0 or 1 and
                #more than 1 parameter sent in)
                if(scalar(@_) > 1 && ($overwrite_flag eq '0' || $overwrite_flag eq '1'))
                {shift(@_)}
                else
                {$overwrite_flag = 0}

                #Read in the message
                my $verbose_message = join('',@_);

                $overwrite_flag = 1 if(!$overwrite_flag && $verbose_message =~ /\r/);

                #Initialize globals if not done already
                $main::last_verbose_size  = 0 if(!defined($main::last_verbose_size));
                $main::last_verbose_state = 0 if(!defined($main::last_verbose_state));
                $main::verbose_warning    = 0 if(!defined($main::verbose_warning));

                #Determine the message length
                my($verbose_length);
                if($overwrite_flag)
                {
                    $verbose_message =~ s/\r$//;
                    if(!$main::verbose_warning && $verbose_message =~ /\n|\t/)
                    {
                        warning("Hard returns and tabs cause overwrite mode to not work ",
                            "properly.");
                        $main::verbose_warning = 1;
                    }
                }
                else
                {chomp($verbose_message)}

                if(!$overwrite_flag)
                {$verbose_length = 0}
                elsif($verbose_message =~ /\n([^\n]*)$/)
                {$verbose_length = length($1)}
                else
                {$verbose_length = length($verbose_message)}

                #Overwrite the previous verbose message by appending spaces just before the
                #first hard return in the verbose message IF THE VERBOSE MESSAGE DOESN'T
                #BEGIN WITH A HARD RETURN.  However note that the length stored as the
                #last_verbose_size is the length of the last line printed in this message.
                if($verbose_message =~ /^([^\n]*)/ && $main::last_verbose_state &&
                    $verbose_message !~ /^\n/)
                {
                    my $append = ' ' x ($main::last_verbose_size - length($1));
                    unless($verbose_message =~ s/\n/$append\n/)
                    {$verbose_message .= $append}
                }

                #If you don't want to overwrite the last verbose message in a series of
                #overwritten verbose messages, you can begin your verbose message with a
                #hard return.  This tells verbose() to not overwrite the last line that was
                #printed in overwrite mode.

                #Print the message to standard error
                print STDERR ($verbose_message,
                    ($overwrite_flag ? "\r" : "\n"));

                #Record the state
                $main::last_verbose_size  = $verbose_length;
                $main::last_verbose_state = $overwrite_flag;

                #Return success
                return(0);
            }



            sub logThis
            {
                return(0) unless($logging);

                my $message = join('',@_);
                $message =~ s/\r/\n/g;
                $message .= "\n" unless($message =~ /\n$/);
                if(open(LOG,">>$error_log"))
                {
                    print LOG (scalar(localtime(time())),"\n",$message);
                    close(LOG);
                }
                else
                {return(1)}
                return(0);
            }



            #
#  Name:        ArrayThese
#  Usage:       ArrayThese(<Filenames>)
#  Purpose:     Creates a 2D array from a tab delimited file where each line
#               represents an entry in the outer array and each tab separated
#               value represents elements in an inner array.
#  Takes:       A list of filenames
#  Returns:     An array reference to a 2D array of strings
            #
#  Author:      Robert Leach
#  Company:     LANL
#  Date:        7/22/03
            #
            sub ArrayThese
            {
                unless(@_ > 0)
                {
                    error("This subroutine has not received the required parameters.  ",
                        "At least 1 file name is required.");
                    return([]);
                }

                use strict;

                my @files = @_;

                my($file,$array);
                $array = [];
                foreach $file (@files)
                {
                    unless(open(FILE,$file))
                    {
                        my $error = "Could not open file: [$file].\n$!\n";
                        error($error);
                    }
                    while(<FILE>)
                    {
                        foreach(split(/\r/))
                        {
                            next if(/^\#/ || /^\s*$/);
                            s/^ *(.*)[ \n]*/$1/;
                            push(@$array,[(split(/ *\t */))]);
                        }
                    }
                    close(FILE);
                }
                return(wantarray ? @$array : $array);
            }

            sub trim{

                my $str = shift;
                $str =~ s/^\s+//;
                $str =~ s/\s+$//;
                return $str;
            }




=head1 CLASS

Utils

=head1 AUTHOR

Robert W. Leach

=head1 DATE

5/29/2007

=head1 PURPOSE

This class is intended to encapsulate generic methods useful for web development.

=head1 DEPENDENCIES

 None.

=head1 CLASS STANDARDS
 1. This class is for use in web interfaces.
 2. This class will not contain any database interface or store biological
    data.

=head1 VERSION HISTORY
 Initial Version 1.0

=head1 ASSUMPTIONS
 1. UNIX Environment
 2. This class will be used by Mason scripts to generate and display data.

=head1 LIMITATIONS
 None.

=head1 ATTRIBUTES	
 NAME           TYPE       DESCRIPTION              NECESSITY
 error_log      file path  Path to a log file       OPTIONAL
 admin_emails   list of    List of email addresses  OPTIONAL
                emails     for error reporting
 verbose        boolean                             OPTIONAL
 DEBUG          boolean                             OPTIONAL
 quiet          boolean                             OPTIONAL
 logging        boolean                             OPTIONAL

=head1 METHODS
 NAME              PARAMETERS          RETURNS
 error             error message       success status
 warning           warning message     success status
 HashThis          list of file names  hash
 safeExternalOpen  file handle         file handle
                   file name
                   write flag
 debug             debug message       success status
 verbose           overwrite flag      success status
                   verbose message
 setVerbose        boolean             success status
 setDebug          boolean             success status
 setQuiet          boolean             success status
 logThis           log message         success status
 setLogging        boolean             success status
 ArrayThese        list of file names  2D array

=head1 DATA STRUCTURES
No complex data structures.

=head1 SEE ALSO
None.

=cut






1;
