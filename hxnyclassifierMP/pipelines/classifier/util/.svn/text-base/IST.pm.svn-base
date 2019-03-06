package util::IST;

use util::Utils;

use base qw(Exporter);
use vars qw(@EXPORT);

@EXPORT = qw(&isDNA
             &formatSequence
	     &isSameSegment
	     &getSeqCharInconsistencies);

my $DNACHARS = 'ATGCBDHVRYKMSWN';

#Note this is temporary because we need to be able to same they're the same
#when they're either a number or name
sub isSameSegment
  {
    my $segment1 = $_[0];
    my $segment2 = $_[1];
    return($segment1 eq $segment2);
  }

sub isDNA
  {
    my $sequence = $_[0];
    return($sequence !~ /[^$DNACHARS\s\r\n\-]/i);
  }

#Copied from seq-lib.pl on 9/9/04 so as to be independent -Rob
sub formatSequence
  {
    #1. Read in the parameters.
    my $sequence          = $_[0];
    my $chars_per_line    = $_[1];
    my $coords_left_flag  = $_[2];
    my $coords_right_flag = $_[3];
    my $start_coord       = $_[4];
    my $coords_asc_flag   = $_[5];
    my $coord_upr_bound   = $_[6];
    my $uppercase_flag    = $_[7];
    my $print_flag        = $_[8];
    my $nucleotide_flag   = $_[9];

    my($formatted_sequence,
       $sub_string,
       $sub_sequence,
       $coord,
       $max_num_coord_digits,
       $line_size_left,
       $lead_spaces,
       $line);
    my $coord_separator = '  ';

    #2. Error check the parameters and set default values if unsupplied.
    my $default_chars_per_line    = 50;
    my $default_coords_left_flag  = 0;
    my $default_coords_right_flag = 0;
    my $default_start_coord       = 1;
    my $default_coords_asc_flag   = 1;
    my $default_coord_upr_bound   = undef();  #infinity (going past 1 produces
    my $default_uppercase_flag    = undef();  #          negative numbers)
    my $default_print_flag        = 0;

    my $tmp_sequence = $sequence;
    $tmp_sequence =~ s/[\s\n\r]+//g;
    $tmp_sequence =~ s/<[^>]*>//g;
    my $seq_len = length($tmp_sequence);

    if(!defined($chars_per_line) || $chars_per_line !~ /^\d+$/)
      {
        if($chars_per_line !~ /^\d+$/ && $chars_per_line =~ /./)
          {warning("Invalid chars_per_line: [$chars_per_line] - using ",
		   "default: [$default_chars_per_line].")}
        #end if(chars_per_line !~ /^\d+$/)
        $chars_per_line = $default_chars_per_line;
      }
    elsif(!$chars_per_line)
      {$chars_per_line = ''}
    #end if(!defined($chars_per_line) || $chars_per_line !~ /^\d+$/)
    if(!defined($coords_left_flag))
      {$coords_left_flag = $default_coords_left_flag}
    #end if(!defined(coords_left_flag))
    if(!defined($coords_right_flag))
      {$coords_right_flag = $default_coords_right_flag}
    #end if(!defined(coords_right_flag))
    if(!defined($start_coord) || $start_coord !~ /^\-?\d+$/)
      {
        if($start_coord && $start_coord !~ /^\d+$/ && $start_coord =~ /./ &&
           ($coords_left_flag || $coords_right_flag))
          {warning("Invalid start_coord: [$start_coord] - using default: ",
		   "[$default_start_coord].")}
        #end if($start_coord !~ /^\d+$/)
        $start_coord = $default_start_coord;
      }
    #end if(!defined($start_coord) || $start_coord !~ /^\d+$/)
    if(!defined($coords_asc_flag))
      {$coords_asc_flag = $default_coords_asc_flag}
    #end if(!defined(coords_right_flag))
    if(defined($coord_upr_bound) && $coord_upr_bound !~ /^\d+$/)
      {undef($coord_upr_bound)}
    if(!defined($print_flag))
      {$print_flag = $default_print_flag}
    #end if(!defined($print_flag))

    if(defined($coord_upr_bound) && $start_coord < 1)
      {$start_coord = $coord_upr_bound + $start_coord}
    elsif($start_coord < 1)
      {$start_coord--}
    elsif(defined($coord_upr_bound) && $start_coord > $coord_upr_bound)
      {$start_coord -= $coord_upr_bound}

    #3. Initialize the variables used for formatting.  (See the DATASTRUCTURES
    #   section.)
    if($coords_asc_flag)
      {
        if(defined($coord_upr_bound) &&
           ($seq_len + $start_coord) > $coord_upr_bound)
          {$max_num_coord_digits = length($coord_upr_bound)}
        else
          {$max_num_coord_digits = length($seq_len + $start_coord - 1)}

        $coord = $start_coord - 1;
      }
    else
      {
        if(defined($coord_upr_bound) && ($start_coord - $seq_len + 1) < 1)
          {$max_num_coord_digits = length($coord_upr_bound)}
        elsif(!defined($coord_upr_bound) &&
              length($start_coord - $seq_len - 1) > length($start_coord))
          {$max_num_coord_digits = length($start_coord - $seq_len - 1)}
        else
          {$max_num_coord_digits = length($start_coord)}

        $coord = $start_coord + 1;
      }
    $line_size_left = $chars_per_line;
    $lead_spaces    = $max_num_coord_digits - length($start_coord);

    #5. Add the first coordinate with spacing if coords_left_flag is true.
    $line = ' ' x $lead_spaces . $start_coord . $coord_separator
      if($coords_left_flag);

    #6. Foreach sub_string in the sequence where sub_string is either a
    #   sub_sequence or an HTML tag.
    foreach $sub_string (split(/(?=<)|(?<=>)/,$sequence))
      {
        #6.1 If the substring is an HTML tag
        if($sub_string =~ /^</ && $sub_string =~ />$/)
          #6.1.1 Add it to the current line of the formatted_sequence
          {$line .= $sub_string}
        #end if(sub_string =~ /^</)
        #6.2 Else
        else
          {
            $sub_string =~ s/\s+//g;

            if($nucleotide_flag)
              {
                my(@errors);
                (@errors) = ($sub_string =~ /([^$DNACHARS])/ig);
                $sub_string =~ s/[^$DNACHARS]//ig;
                if(scalar(@errors))
                  {warning("[",scalar(@errors),"] bad nucleotide characters ",
			   "were filtered out of your sequence: [",
			   join('',@errors),
			   "].\n")}
              }

            #6.2.1 If the sequence is to be uppercased
            if(defined($uppercase_flag) && $uppercase_flag)
              #6.2.1.1 Uppercase the sub-string
              {$sub_string = uc($sub_string)}
            #end if(defined($uppercase_flag) && $uppercase_flag)
            #6.2.2 Else if the sequence is to be lowercased
            elsif(defined($uppercase_flag) && !$uppercase_flag)
              #6.2.2.1 Lowercase the sub-string
              {$sub_string = lc($sub_string)}
            #end elsif(defined($uppercase_flag) && !$uppercase_flag)

	    my $pattern = '';
	    if(!$line_size_left)
	      {$pattern = '.+'}
	    else
	      {$pattern = ".{1,$line_size_left}"}

            #6.2.3 While we can grab enough sequence to fill the rest of a line
            while($sub_string =~ /($pattern)/g)
              {
                $sub_sequence = $1;
                #6.2.3.1 Add the grabbed sequence to the current line of the
                #        formatted sequence
                $line .= $sub_sequence;
                #6.2.3.2 Increment the current coord by the amount of sequence
                #        grabbed
                my $prev_coord = $coord;
                if($coords_asc_flag)
                  {
                    $coord += length($sub_sequence);
                    if(defined($coord_upr_bound)      &&
                       $prev_coord <= $coord_upr_bound &&
                       $coord > $coord_upr_bound)
                      {$coord -= $coord_upr_bound}
                  }
                else
                  {
                    $coord -= length($sub_sequence);
                    if(defined($coord_upr_bound) &&
                       $prev_coord >= 1 && $coord < 1)
                      {$coord = $coord_upr_bound + $coord - 1}
                    elsif($prev_coord >= 1 && $coord < 1)
                      {$coord--}
                  }
                #6.2.3.3 If the length of the current sequence grabbed
                #        completes a line
                if( !$line_size_left || 
                    length($sub_sequence) == $line_size_left) 
                  {
                    $lead_spaces = $max_num_coord_digits - length($coord);
                    #6.2.3.3.1 Conditionally add coordinates based on the
                    #          coords flags
                    $line .= $coord_separator . ' ' x $lead_spaces . $coord
                      if($coords_right_flag);

                    #6.2.3.3.2 Add a hard return to the current line of the
                    #          formatted sequence
                    $line .= "\n" if($chars_per_line);

                    #6.2.3.3.3 Add the current line to the formatted_sequence
                    $formatted_sequence .= $line;
                    #6.2.3.3.4 Print the current line if the print_flag is true
                    print $line if($print_flag);

                    #6.2.3.3.5 Start the next line
                    $lead_spaces = $max_num_coord_digits - length($coord+1);
                    $line = '';
                    $line = ' ' x $lead_spaces
                          . ($coords_asc_flag ? ($coord+1) : ($coord-1))
                          . $coord_separator
                      if($coords_left_flag);

                    #6.2.3.3.6 Reset the line_size_left (length of remaining
                    #          sequence per line) to chars_per_line
                    $line_size_left = $chars_per_line;
                  }
                #end if(length($sub_sequence) == $line_size_left)
                #6.2.3.4 Else
                else
                  #6.2.3.4.1 Decrement line_size_left (length of remaining
                  #          sequence per line) by the amount of sequence
                  #          grabbed
                  {$line_size_left -= length($sub_sequence)}
                #end 6.2.3.4 Else
              }
            #end while($sub_string =~ /(.{1,$line_size_left})/g)
          }
        #end 6.2 Else
      }
    #end foreach $sub_string (split(/(?=<)|(?<=>)/,$sequence))
    #7. Add the last coodinate with enough leadin white-space to be lined up
    #   with the rest coordinates if the coords_right_flag is true
    $lead_spaces = $max_num_coord_digits - length($coord);
    $line .= ' ' x $line_size_left . $coord_separator . ' ' x $lead_spaces
          . $coord
      if($coords_right_flag && $line_size_left != $chars_per_line);
    $line =~ s/^\s*\d+$coord_separator\s*$// if($coords_left_flag);

    #8. Add the ending PRE tag to the last line of the formatted sequence
    $line =~ s/\n*$/\n/s;

    #9. Add the last line to the formatted_sequence
    $formatted_sequence .= $line;
    #10. Print the last line if the print_flag is true
    print $line if($print_flag);

    if($coord < 1 && ($coords_left_flag || $coords_right_flag))
      {warning("The sequence straddles the origin.  Coordinates are ",
	       "inaccurate.")}

    #Remove the last hard return for retuning pure sequence
    if(!$chars_per_line)
      {chomp($formatted_sequence)}

    #11. Return the formatted_sequence
    return $formatted_sequence;
  }



sub getSeqCharInconsistencies
  {
    #Declare & read in the parameters: trusted_flu_type, trusted_segment,
    #trusted_serotype, flu_type, segment, message, & serotype
    my $trusted_flu_type = uc($_[0]);
    my $trusted_segment  = uc($_[1]);
    my $trusted_serotype = uc($_[2]);
    my $flu_type         = uc($_[3]);
    my $segment          = uc($_[4]);
    my $serotype         = uc($_[5]);

    #Declare an empty problems array
    my @problems = ();

    ##
    ##Validate the parameters for presence and a value
    ##

    #If argument array is less than 6 in size
    if(scalar(@_) < 6)
      {
	push(@problems,"Not enough arguments [" . scalar(@_) . "] sent in.");
	#4.1. error("Not enough arguments sent in")
	error($problems[-1]);
	#4.2. return problems
	return(@problems);
      }

    #If trusted_flu_type is not defined or has no value
    if(!defined($trusted_flu_type) || $trusted_flu_type !~ /\S/)
      {
	#Push "A flu type could not be determined for comparison" onto problems
	push(@problems,"A flu type could not be determined for comparison");
      }

    #If trusted_segment is not defined or has no value
    if(!defined($trusted_segment) || $trusted_segment !~ /\S/)
      {
	#Push "A segment could not be determined for comparison" onto problems
	push(@problems,"A segment could not be determined for comparison");
      }
    #Else if(defined($serotype) && $serotype =~ /\S/ &&
    #        (!defined($trusted_serotype) || $trusted serotype !~ /\S/))
    elsif(defined($serotype) && $serotype =~ /\S/ &&
	  (!defined($trusted_serotype) || $trusted_serotype !~ /\S/))
      {
	#Push "A serotype could not be determined for comparison" onto problems
	push(@problems,"A serotype could not be determined for comparison");
      }

    #If(defined($flu_type) && defined($trusted_flu_type) &&
    #   $flu_type =~ /\S/  && $trusted_flu_type =~ /\S/  &&
    #   $trusted_flu_type ne $flu_type)
    if(defined($flu_type) && defined($trusted_flu_type) &&
       $flu_type =~ /\S/  && $trusted_flu_type =~ /\S/  &&
       $trusted_flu_type ne $flu_type)
      {
	#Push "Flu type inconsistency with derived value [$flu_type is not the
	#same as $trusted_flu_type]" onto problems
	push(@problems,
	     "Flu type inconsistency with derived value [$flu_type is not " .
	     "the same as $trusted_flu_type]");
      }

    #if(defined($segment) && defined($trusted_segment) &&
    #   $segment =~ /\S/  && $trusted_segment =~ /\S/  &&
    #   !isSameSegment($segment,$trusted_segment))
    if(defined($segment) && defined($trusted_segment) &&
       $segment =~ /\S/  && $trusted_segment =~ /\S/  &&
       !isSameSegment($segment,$trusted_segment))
      {
	#Push "Segment inconsistency with derived value [$segment is not the
	#same as $trusted_segment]" onto problems
	push(@problems,
	     "Segment inconsistency with derived value [$segment is not the " .
	     "same as $trusted_segment]");
      }

    #9. if(defined($trusted_flu_type) && defined($trusted_segment) &&
    #       $trusted_flu_type =~ /^a$/i && $trusted_segment =~ /^[HN]A$/i &&
    #       defined($trusted_serotype) && defined($serotype) &&
    #       $trusted_serotype =~ /\S/ && $serotype =~ /\S/ &&
    #       $trusted_serotype ne $serotype)
    if(defined($trusted_flu_type) && defined($trusted_segment) &&
       $trusted_flu_type =~ /^a$/i && $trusted_segment =~ /^[HN]A|[46]$/i &&
       defined($trusted_serotype) && defined($serotype) &&
       $trusted_serotype =~ /\S/ && $serotype =~ /\S/ &&
       $trusted_serotype ne $serotype)
      {
	#Push "Serotype inconsistency with derived value [$serotype is not the
	#same as $trusted_serotype]" onto problems
	push(@problems,
	     "Serotype inconsistency with derived value [$serotype is not " .
	     "the same as $trusted_serotype]");
      }

    #10. return(@problems)
    return(@problems);
  }



=head1 CLASS

IST

=head1 AUTHOR

Robert W. Leach

=head1 DATE

3/27/2007

=head1 PURPOSE

This class is intended to encapsulate the scientific methods, analysis, and data processing of influenza data.

=head1 DEPENDENCIES

 Perl Modules
	Utils

=head1 CLASS STANDARDS

 1. This class is for use in command line scripts and web interfaces.
 2. This class will not contain any database interface or store biological
    data.

=head1 VERSION HISTORY

 Version 1.1 - Removed blast dependencies whose functionality was
               encapsulated elsewhere.
 Initial Version 1.0

=head1 ASSUMPTIONS

 1. UNIX Environment
 2. This class will be used by Mason scripts to generate and display data.

=head1 LIMITATIONS

 None.

=head1 ATTRIBUTES
	
 NAME           TYPE      DESCRIPTION           NECESSITY
 admins         array of  email addresses       OPTIONAL
               strings

=head1 METHODS

 NAME                       PARAMETERS        RETURNS
 isSameSegment              segment1          boolean
                            segment2
 isDNA                      sequence          boolean
 formatSequence             sequence          sequence
 getSeqCharInconsistencies  trusted flu type  message list
                            trusted segment
                            trusted serotype
                            flu type
                            segment
                            serotype

=head1 DATA STRUCTURES

No complex data structures.

=head1 SEE ALSO

None.







=cut








=head1 METHOD NAME

getSeqCharInconsistencies

=head2 AUTHOR

Robert W. Leach (I<E<lt>robleach@lanl.govE<gt>>)

=head2 DATE

4/17/2007

=head2 PURPOSE

To determine whether user supplied characteristics (flu type, segment, and serotype) are consistent with a trusted set of characteristics.

=head2 DEPENDENCIES

 Perl Modules
  Utils

=head2 VERSION HISTORY

Initial Version 1.0

=head2 ASSUMPTIONS

 1. The trusted characteristics were produced by getSequenceCharacteristics.
    Thus, undefined values for trusted_flu_type or trusted_segment should
    always produce an invalid result.  Serotype may be ignored unless flu
    type is A and segment is either HA or NA.

=head2 LIMITATIONS

None.

=head2 PARAMETERS

 NAME              TYPE     DESCRIPTION                NECESSITY
 trusted_flu_type  string   Name of flu type           REQUIRED
 trusted_segment   string   Name or number of segment  REQUIRED
 trusted_serotype  string   Name of serotype           REQUIRED
 flu_type          string   Name of flu type           OPTIONAL
 segment           string   Name or number of segment  OPTIONAL
 serotype          string   Name of serotype           OPTIONAL

=head2 RETURNS

 NAME              TYPE     DESCRIPTION                NECESSITY
 problems          list of  Series of problem          ALWAYS [empty list]
                   strings  descriptions with input

=head2 DATA STRUCTURES

A note about parameter strings.  While all parameters are required, they may be undefined, though if they are, the return will contain problems except for serotype when trusted flu tyoe and trusted segment are not A and (HA or NA).

=head2 PRELIMINARY DESIGN

 1. Read in parameters
 2. Validate that there were at least 6 parameters sent in
 3. Validate the flu_type variable type
 4. Validate the segment variable type
 5. Validate the serotype variable type
 6. Validate that trusted_flu_type and flu_type are the same
 7. Validate that trusted_segment and segment are the same
 8. If trusted_flu_type is 'A' and trusted_segment is either HA or NA
 8.1. Validate that trusted_serotype and serotype are the same
 9. Else if a serotype was supplied and it could not be determined

=head2 END PRELIMINARY DESIGN

=head2 PSEUDOCODE

 1. Declare and read in self
 2. Declare & read in the parameters: trusted_flu_type, trusted_segment,
    trusted_serotype, flu_type, segment, message, & serotype
 3. Declare an empty problems array
    #Validate the parameters for presence and a value
 4. if argument array is less than 6 in size
 4.1. error("Not enough arguments sent in")
 4.2. return problems
 5. if trusted_flu_type is not defined or has no value
 5.1. push "A flu type could not be determined for comparison" onto problems
 6. if trusted_segment is not defined or has no value
 6.1. push "A segment could not be determined for comparison" onto problems
 7. else if(defined($serotype) && $serotype =~ /\S/ &&
            (!defined($trusted_serotype) || $trusted serotype !~ /\S/))
 7.1. push "A serotype could not be determined for comparison" onto problems
 7. if(defined($flu_type) && defined($trusted_flu_type) &&
       $flu_type =~ /\S/  && $trusted_flu_type =~ /\S/  &&
       $trusted_flu_type ne $flu_type)
 7.1. push "Flu type inconsistency with derived value [$flu_type is not the
      same as $trusted_flu_type]" onto problems
 8. if(defined($segment) && defined($trusted_segment) &&
       $segment =~ /\S/  && $trusted_segment =~ /\S/  &&
       !isSameSegment($segment,$trusted_segment))
 8.1. push "Segment inconsistency with derived value [$segment is not the same
      as $trusted_segment]" onto problems
 9. if(defined($trusted_flu_type) && defined($trusted_segment) &&
        $trusted_flu_type =~ /^a$/i && $trusted_segment =~ /^[HN]A$/i &&
        defined($trusted_serotype) && defined($serotype) &&
        $trusted_serotype =~ /\S/ && $serotype =~ /\S/ &&
        $trusted_serotype ne $serotype)
 9.1. push "Serotype inconsistency with derived value [$serotype is not the
      same as $trusted_serotype]" onto problems
 10. return(@problems)

=head2 END PSEUDOCODE

=head2 NOTES

This method calls isSameSegment to determine whether segments are the same.

=head2 SEE ALSO

IST_class_design.txt






=cut


=head1 METHOD NAME

isSameSegment

=head2 AUTHOR

Robert W. Leach (I<E<lt>robleach@lanl.govE<gt>>)

=head2 DATE

4/17/2007

=head2 PURPOSE

To determine whether two segment strings refer to the same segment.

=head2 DEPENDENCIES

None.

=head2 VERSION HISTORY

Initial Version 1.0 - This version is a place holder for something more comprehensive.

=head2 ASSUMPTIONS

We will only be asked to compare strings to strings and numbers to numbers.

=head2 LIMITATIONS

 1. This version does not compare segment numbers to segment strings.

=head2 PARAMETERS

 NAME        TYPE           DESCRIPTION      NECESSITY
 segment1    scalar         Segment name     REQUIRED
 segment2    scalar         Segment name     REQUIRED

=head2 RETURNS

 NAME        TYPE           DESCRIPTION       NECESSITY [DEFAULT]
 same        boolean        whether segment1  ALWAYS
                            is the same as
                            segment2

=head2 DATA STRUCTURES

None.

=head2 PRELIMINARY DESIGN

None.

=head2 END PRELIMINARY DESIGN

=head2 PSEUDOCODE

None.

=head2 END PSEUDOCODE

=head2 NOTES

This method is intended to be replaced with something which can compare strings and numbers and determine whether they refer to the same segments.  The next version will have to take the flu type and serotype because the segments are numbered/named differently depending on these types.

=head2 SEE ALSO

None.






=cut


=head1 METHOD NAME

isDNA

=head2 AUTHOR

Robert W. Leach (I<E<lt>robleach@lanl.govE<gt>>)

=head2 DATE

4/17/2007

=head2 PURPOSE

To guess whether a sequence is DNA or not.

=head2 DEPENDENCIES

None.

=head2 VERSION HISTORY

Initial Version 1.0

=head2 ASSUMPTIONS

None.

=head2 LIMITATIONS

None.

=head2 PARAMETERS

 NAME        TYPE           DESCRIPTION      NECESSITY
 sequence    string         possible DNA     REQUIRED

=head2 RETURNS

 NAME        TYPE           DESCRIPTION      NECESSITY
 isdna       boolean        whether or not   ALWAYS
                            the sequence is
                            DNA

=head2 DATA STRUCTURES

None.

=head2 PRELIMINARY DESIGN

None.

=head2 END PRELIMINARY DESIGN

=head2 PSEUDOCODE

None.

=head2 END PSEUDOCODE

=head2 NOTES

This method uses a global variable which defines DNA characters (including the ambiguous character set defined by IUPAC).
It allows hard returns but not spaces.

=head2 SEE ALSO

None.






=cut


=head1 METHOD NAME

formatSequence

=head2 AUTHOR

Robert W. Leach (I<E<lt>robleach@lanl.govE<gt>>)

=head2 DATE

4/17/2007

=head2 PURPOSE

To format sequence given a number of characters to wrap on (along with other niceties to mke the sequence look great in plain text).

=head2 DEPENDENCIES

None.

=head2 VERSION HISTORY

 Version 1.1 - Fixed a bug which was chopping off sequence if a bad character
               '>' was in the middle of the sequence.
 Initial Version 1.0 - Copied from seq-lib.pl

=head2 ASSUMPTIONS

None.

=head2 LIMITATIONS

None.

=head2 PARAMETERS

 NAME               TYPE     DESCRIPTION             NECESSITY
 sequence           string   DNA or other sequence   REQUIRED
 chars_per_line     integer  Number of characters    OPTIONAL [50]
                             per line
 coords_left_flag   boolean  Display coordinates     OPTIONAL [Off]
                             to the left of the
                             sequence
 coords_right_flag  boolean  Display coordinates     OPTIONAL [Off]
                             to the right of the
                             sequence
 start_coord        integer  The starting            OPTIONAL [1]
                             coordinate to display
 coords_asc_flag    boolean  Display coordinates in  OPTIONAL [On]
                             ascending order
 coords_upr_bound   integer  Last coordinate of a    OPTIONAL [undef]
                             circular genome
 uppercase_flag     boolean  Uppercase the sequence  OPTIONAL [Off]
 print_flag         boolean  Print the formatted     OPTIONAL [Off]
                             sequence
 nucleotide_flag    boolean  Filter out non-         OPTIONAL [Off]
                             nucleotide characters

=head2 RETURNS

 NAME                 TYPE     DESCRIPTION             NECESSITY
 formatted_sequence   string   DNA or other sequence   ALWAYS
                               with formatting

=head2 DATA STRUCTURES

None.

=head2 PRELIMINARY DESIGN

None.

=head2 END PRELIMINARY DESIGN

=head2 PSEUDOCODE

Embedded pseudocode in '#' comments.

=head2 END PSEUDOCODE

=head2 NOTES

This method allows HTML tags and displays coordinates and wraps sequence accordingly.

=head2 SEE ALSO

None.






=cut



1;
