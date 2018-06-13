#   @(#) $Id: ClientQuery.pm,v 1.36 2011/04/21 14:46:26 Frank-Christian_Otto Exp $
# ------------------------------------------------------------------------- #
#
#   RCM - Reliable Configuration Management
#
#   (C) Copyright IBM Corporation 1999,2004
#   All Rights Reserved.
#
# ------------------------------------------------------------------------- #
#
#   SOS - batch tool set
#
# ------------------------------------------------------------------------- #
#
#   Module:	ClientQuery.pm
#
#   Author:	Dr. Frank-Christian Otto
#
#   Date:	July - September 2000, Nov 2004
#
#   Purpose:    data handling, i/o, ... for copy_table.pl, rcm_insert.pl
#               and their relatives
#
# ------------------------------------------------------------------------- #

=pod

=head1 NAME

ClientQuery.pm  - Class to select/insert/update/delete/print/read RCM data

=head1 SYNOPSIS

    use Susi::ClientQuery;

=head1 DESCRIPTION

Susi::ClientQuery provides a set of methods to support "batch"
processing on the RCM database. It uses Susi::Client to communicate
with the database. Susi::Description is used to get some database
object information.

Susi::ClientQuery is intended to be a toolkit adequate to write
powerful programs which make database "batch" processing an easy task.

Susi::ClientQuery supports:

    select data from the database
    read data from an input stream (a couple of formats are supported)
    store data in an internal hash
    modify stored data (column sort)
    discard data from the internal hash
    print data to an output stream (a couple of formats are supported)
    build insert/update/delete commands based on the stored data
    execute the generated commands (some error reporting is supported)

=head1 EXAMPLES

Example 1: read some data from RCM and print it

  use Susi::Client;
  use Susi::ClientQuery;

  my $susi = Susi::Client->new();            # build Susi::Client object
  $susi->host($host);                        # do
  $susi->user($user);                        # some
  $susi->password($pw_read_from_stdin));     # settings
  $susi->login;                              # log in (optional)

  my $client = Susi::ClientQuery->new($susi, # create Susi::ClientQuery
                                             # object, reference to constructed
                                             # Susi::Client is mandatory
         {mode => "select", debug => 4});    # optional: set some parameters
                                             # at object creation time
  # retrieve some data
  $client->collect_table_data ($table_1, $query_1);
  $client->collect_table_data ($table_2, $query_2);
  $client->collect_table_data ($table_3, $query_3);

  # print data using "stanza" format
  @buffer = $client->print_table_data ("stanza");

Example 2: convert/sort data coming from a text buffer

  ... as above ...

  my $client = Susi::ClientQuery->new($susi,
        {mode => "select", 
         table_sort => 1,                   # enable table sort 
         column_sort => 1}                  # enable column sort 

  # read data from text buffer assuming "passwd" format
  $client->read_table_data ("passwd", @buffer);

  # optional: force column sort via explicite method call
  #$client->column_sort();

  # print all stuff (using another format)
  # table sort and column sort are done implicitely
  @buffer = $client->print_table_data ("stanza");

  ... add some more examples ...

=head1 FORMATS

On reading/printing several formats are supported.
A description of them follows. 

=over 4

=item "stanza" format

Except some subtile differencies this is exactly the AIX stanza format. 
A new stanza begins with a line of the form

    <table_name>:

which cannot contain white spaces at the beginning. Then we expect
an arbitrary number of lines containing <field-value-pairs> of the
form

    <column_name> = "<value>"

or 

    <column_name> = <value>

White spaces are ignored. The first form is necessary when treating
values containing white spaces. Empty values should always be given
as "". Blank lines are ingored.


=item "passwd" format

This format ensures compatibility with good old 'h2p' and is best
suited for manipulations by hand.

This format is "table oriented" whereas "plain" and "stanza" are
"data row oriented".
Empty lines and lines containing nothing but a # at position one
followed by white spaces are ignored. Furthermore lines of the form

    # ------arbitrary many dashes---- #

and those starting with two consecuteive '#' are ignored.

The begin of a new table with identifier <table_name> is marked by
a line of the form

    # FORMAT of table <table_name>:

The number sign (#) must occur at position one. White spaces between
words are ignored.

Then before the first data line we expect a line of the form

    # <name_of_column_1>:<name_of_column_2>:...

which determines the names and positions of the columns of table
<table_name>. Again # is placed at position one.

Data lines are of the form

    <value_1>:<value_2>:...

Each data line is treated according to the last found column
specification and <table_name>.
The data lines have to match the column specification line according
to number and position of fields.

Note that the "passwd" format runs into trouble if a value contains 
a ':' since ':' is already used as separator. To cope with this
on reading we convert ':' into '&colon;' and back on writing.

=item HTML format

copy_machine.pl can write its output using HTML. This is used for better
visualization only and cannot be feed back into copy_machine.pl.
The html code generated is prepared for transition to XHTML.

=item XML format

The output/input stream will be an XML structure like:

 <rcm_data>
   <table name="rcm.cron_def">
    <field name="hour">23</field>
    <field name="month">*</field>
    <field name="login">root</field>
    <field name="minute">15</field>
    <field name="day">*</field>
    <field name="action">/home/ldapsupp/bin/ldap.del.old.logs.sh &gt;&gt; /var/tmp/ldap/ldap.del.old.logs.log 2&gt;&amp;1</field>
    <field name="weekdays">*</field>
    <field name="cronid">gsnptac_id1</field>
   </table>
 </rcm_data>

Pls. not those special construct like '&gt;', '&amp;'. Those are the usual replacements for special characters like '>', '&', and so on (http://en.wikipedia.org/wiki/Character_encodings_in_HTML). 

In select mode those replacements will take place automatically.

If, however, you're preparing XML input data manually you need to take care of suitable replacements by yourself.

=item CSV format

Qquite similar to the 'passwd' format but instead of writing a header (that is usuable for reading that data back) it will simply write an additional line containing the field names (in uppercase)

=item "plain" format

Each line contains exactly one row of data and has the form

    <table_name><separator><field-value-pair><separator><field-value-pair>...

As <separator> we use '§' which will hopefully never occur in your data.
The <field-value-pairs> are af the form

    <column_name>="<value>"

White spaces are allowed inside values only.
Empty lines are not allowed. Comment lines does not exist.

This format is the only one which is robust against shuffling lines.

This format is also used to store data internally.

=item "sql" format

special format for developers of clever scripts

=back

=head1 KNOWN PROBLEMS

=over 4

=item 1.

So far duplicates of data lines are not removed.

=item 2.

Entries containing a colon (:) are not suited for the "passwd" format
since there colons are used as field separator. So far, this problem
is solved by replacing ':' within data by '&colon;' when writing "passwd"
format and vice versa when reading.
You should keep this conversion in mind when editing/parsing files using the
"passwd" format by yourself.

=back

=cut

# ---------------------------------------------------------------------------#
#  here we go...
# ---------------------------------------------------------------------------#

use utf8;
use Carp;
use File::Basename;
use Susi::Client;
use Susi::Description;

package Susi::ClientQuery;

my ($s_rsep, $s_fsep); # record/field separator used by Susi::Client sub object
my ($rsep, $fsep) = ("\n", "&fsep;"); #'§' chr(167)"\247"
my ($asgn_char, $quote_char) = ('=', '"'); #"

# within 'passwd' we need to replace ':' with something different
# since ':' is used as separator
#my $passwd_replace_colon = chr(228); #'ä' # alternatives: '§',
#my $passwd_replace_colon = "\x{A4C3}"; #'ä' # alternatives: '§',
my $passwd_replace_colon = "&colon;"; #'ä' # alternatives: '§',
                            # 'ä' was chosen to be compatible with 'h2p'

# within 'xml' format we decided to not used CDATA during output:
my $xml_use_cdata = 0;
# special character translation is not needed 
# (XML::DOM, XML::Writer are performing such thing automatically)
#my $xml_replace_gt = "&gt;";
#my $xml_replace_lt = "&lt;";

#
# supported formats
#
my ($_UNSUPPORTED_,$_READ_,$_WRITE_) = (0,1,2);
my %formats = ("plain" => $_READ_ | $_WRITE_, 
	       "stanza" => $_READ_ | $_WRITE_, 
	       "passwd" => $_READ_ | $_WRITE_,
	       "xml" => $_READ_ | $_WRITE_,
	       "html"   => $_WRITE_,
	       "sql"   => $_WRITE_,
	       "csv"   => $_WRITE_);



=head1 GENERAL METHODS

=cut 

# ---------------------------------------------------------------------------#
#  SUB new  (constructor method)
# ---------------------------------------------------------------------------#

=head2 new ($susi [,$params])

mandatory arguments: $susi

optional arguments: $params

sample call: $client=Susi::ClientQuery->new($susi,{debug =>1})

$susi must be a reference to an already constructed Susi::Client object.
$params is a hash reference. It could be used to set some internal
parameters:

=over 4

=item debug 

debug level: 0,1,2,...

=item mode

main mode used for sorting, command building etc.: 
"select", "insert", "update", "delete"

=item table_sort

A value of 1 forces a table sort before data is print.
Table sort is off by default. The sorting
depends on the value of <mode>.

=item column_sort

A value of 1 forces a column sort of ....

=item exec_mode

So far just the value "script" is supported.

=back

=cut

# 
#  SUB new  (constructor method)
# ---------------------------------------------------------------------------#
sub new($;$) {
    my $proto = shift;
    my $class = ref $proto || $proto;

    my $susi = shift;
    my $params = shift;

    my $self = {};
    bless $self, $class;

    if (! defined $susi ) {
        Carp::croak ("constructor expects already constructed Susi::Client object as 1st arg\n"); 
        # TODO improve this
    } elsif ($susi->state ne "login") {
        # fire login procedure from Susi::Client 
        Carp::croak ("could not connect to RCM database") 
        unless ($susi->login());
    }

    $self->{SUSI} = $susi;      # store client object (socket) for later usage
    $s_rsep = $susi->RSEP;
    $s_fsep = $susi->FSEP;
    $self->{TABLE_DATA} = {};   # we use an anonymous hash to store data
    $self->{PARAMS} = {
        debug => 0,
        mode => "select",       # "select", "insert","update","delete"
        table_sort => 0,        # 0 (do nothing), 1 (to do)
        column_sort => 0,       # 0 (do nothing), 1 (to do)
        exec_mode => "script",  # value for parameter "execmode" of rcm procs
        SortedTables => undef   # presorted List of table names to
                                # be used in get_table_order() in select mode
    };
    $self->{TABLE_PROCS} = {};
    $self->{BAD_TABLE_DATA} = {};
    $self->{STATUS} = {
        column_sort_done => 0,  # 0 (nothing done), 1 (done) 
        column_sort_mode => "", # mode had been active during sort
        column_sort_add_values => 0,
        column_sort_exact_match => 0,
        get_proc_done => 0,     # 0 (nothing done), 1 (done)
        get_proc_mode => "",    # mode had been active during get_procedures
        norm_tab_names_done => 0, # 0 (nothing done), 1 (done)
        norm_tab_names_remove_unknown => 0,
    };
			 
    if (defined $params ) {
        foreach my $key (keys %{$params}) {
            # TODO so far no value check!
            # idea: offer a method check() which does this
	    if (exists $self->{PARAMS}->{$key}) {
                $self->{PARAMS}->{$key} = $params->{$key};
	    } else {
                Carp::croak ("parameter $key not supported by objects".
                             " of type $class\n");
	    }
        }
    }
   
    return $self;
}
# ---------------------------------------------------------------------------#


# ---------------------------------------------------------------------------#
#  SUB debug  (set/get debug level)
# ---------------------------------------------------------------------------#

=head2 debug ([$debuglevel])

mandatory arguments: 

optional arguments: $debuglevel

sample call: $client->debug(0)

If called with its optional argument, the debug level of the object
is changed to the given value. In any case the current setting is returned.

Supported values are: 0,1,2,...

0 means no debug. A positive number generates some output. Higher numbers
will produce more debug messages.

=cut

#  SUB debug  (set/get debug level)
# ---------------------------------------------------------------------------#
sub debug($;$) {
    my $self = shift;
    my $debug = shift;

    if (defined $debug) {
	$self->{PARAMS}->{debug} = $debug; 
    }
    return $self->{PARAMS}->{debug};
}
# ---------------------------------------------------------------------------#

# ---------------------------------------------------------------------------#
#  SUB mode  (set/get main working mode)
# ---------------------------------------------------------------------------#

=head2 mode ([$mode])

mandatory arguments: 

optional arguments: $mode

sample call: $current_mode = $client->mode

If called with its optional argument, the main working mode of the object
is changed to the given value. In any case the current setting is returned.
Valid values for $mode are:

"select", "insert", "update", "delete"

The main working mode is used by almost all methods working on the
objects data. Usually you will set the mode once and run all needed
method after that.

=cut

#  SUB mode  (set/get main working mode)
# ---------------------------------------------------------------------------#
sub mode($;$) {
    my $self = shift;
    my $mode = shift;

    if (defined $mode) {
	# TODO no value check here!
	$self->{PARAMS}->{mode} = $mode; # switch mode
    }
    return $self->{PARAMS}->{mode};
}
# ---------------------------------------------------------------------------#

# ---------------------------------------------------------------------------#
#  SUB exec_mode (set/get exec_mode for RCM Databases procedured)
# ---------------------------------------------------------------------------#

=head2 exec_mode ([$exec_mode])

mandatory arguments: 

optional arguments: $exec_mode

sample call: $current_exec_mode = $client->exec_mode

If called with its optional argument, the internal variable $exec_mode
is changed to the given value. In any case the current setting is returned.
The value of $exec_mode is passed through all called RCM Database
procedures having an EXEC_MODE argument. 
So far nothing but "script" is supported.

=cut

#  SUB exec_mode (set/get exec_mode for RCM Databases procedured)
# ---------------------------------------------------------------------------#
sub exec_mode($;$) {
    my $self = shift;
    my $exec_mode = shift;

    if (defined $exec_mode) {
	# TODO no value check here!
	$self->{PARAMS}->{exec_mode} = $exec_mode; # switch exec_mode
    }
    return $self->{PARAMS}->{exec_mode};
}
# ---------------------------------------------------------------------------#

# ---------------------------------------------------------------------------#
#  SUB status (print object status)
# ---------------------------------------------------------------------------#

=head2 status ()

no arguments

sample call: @buffer = $client->status

The current settings of several internal object variables are reported.
The result set includes variables which are accessible by any method.
The report contains lines of the form

<variable_name>  <value>

If the procedure is called in scalar context the result set is
concatenated with newlines.

Besides the values which can be set using the constructor (explained above)
the following values are returned:

=over 4

=item column_sort_done

1: the data is column sorted

0: the column sort state is in doubt


=item column_sort_mode

contains the value of $client->mode which was active during the last
column sort.

=item column_sort_add_values

1: the lost column sort has add empty strings for all missing columns

0: the last column sort has just reorderd the available data


=item column_sort_exact_match

0: the last column sort was a normal one allowing renaming of 
   column names

1: the last columns sort required data records to possess all 
   columns with the correct names

See L<UNDERSTANDING COLUMN SORT> for more information.

=item get_proc_done

1: all procedure names for the current contents of the data hash
   have been retrieved

0: it is in doubt whether all needed procedure names have been retrieved


=item get_proc_mode

contains the value of $self->mode which was active during the last
run of $client->get_procedures

=item norm_tab_names_done

1: all tables names have been normalized

0: it is in doubt whether all tables names have been normalized

=item norm_tab_names_remove_unknown 

1: within the last run of $client->normalize_table_names unresolved
   table names are treated as bad data

0: within the last run of $client->normalize_table_names unresolved
   table names are simply ignored


=back

The returned data might be used by the caller to decide whether some
action should be taken or not. For example of column_sort_done is zero
or column_sort_mode is not what you expected than you might wish
to start a new column sort. If all is fine you do not need a new sort.
(The package maintains these variables in a safe way, e.g. column_sort_done
is reset to 0 if new data, usually unsorted, is added to the data hash.) 

=cut

#  SUB status (print object status)
# ---------------------------------------------------------------------------#
sub status($) {
    my $self =shift;
    my $result = "";

    foreach my $key ( keys %{$self->{PARAMS}}) {
	$result .= sprintf("%s\t%s\n", $key, $self->{PARAMS}->{$key});
    }
    foreach my $key ( keys %{$self->{STATUS}}) {
	$result .= sprintf("%s\t%s\n", $key, $self->{STATUS}->{$key});
    }

    wantarray ? split ('\n', $result) : $result;
}
# ------------------------------------------------------------------------- #

# ------------------------------------------------------------------------- #
# SUB get_query_columns (build list of columns a query would return)
# ------------------------------------------------------------------------- #

=head2 get_query_columns ($query)

mandatory arguments: $query

optional arguments: 

sample call: @column_list = $client->get_query_columns($query)

Assumed that $query is a valid SQL query against the RCM database
the procedure will return a list of the columns the query would
yield.

If the procedure is called in scalar context the result set is
concatenated with newlines.

This procedure is used internally but might also be useful outside.

=cut

# SUB get_query_columns (build list of columns a query would return)
# ------------------------------------------------------------------------- #
sub get_query_columns {
    my $self = shift;
    my $query = shift;
    my ($status, $msg, $ret);
    my @result = ();
      
    ($status, $msg) = 
	$self->{SUSI}->open_query($query);
    if ($status != 1403 && $status > 0) {
	Carp::croak("Error reading from RCM -- $msg\nLast action -- open_query($query)\n") ;
    }
    ($status, $ret) = 
	$self->{SUSI}->close_query();
    if ($status != 1403 && $status > 0) {
	Carp::croak("Error reading from RCM -- $ret\nLast action -- close_query\n") ;
    }
    @result = split /$s_rsep/, $msg;
    shift @result; # drop 1st line (number of columns)
    for ( my $i=0 ; $i <= $#result ; $i++ ) {
	my @temp = split /$s_fsep/, $result[$i];
	$result[$i] = lc( shift @temp ); # we need 1st entry only
    }
    if ( $self->debug >= 4 ) {
	print STDERR " * * * * building column list:\n";
	print STDERR "\tquery : $query\n";
	print STDERR "\tresult: ";
	print STDERR "@result\n";
    }

    wantarray ? @result : join "\n", @result;
}
# ------------------------------------------------------------------------- #

# ------------------------------------------------------------------------- #
# SUB get_table_columns (build list of columns of a database table/view)
# ------------------------------------------------------------------------- #

=head2 get_table_columns ($table)

mandatory arguments: $table

optional arguments: 

sample call: @column_list = $client->get_table_columns($table)

Assumed that $table is an accessible table or view in the RCM database
the procedure will return a list of the columns of the table/view.

If the procedure is called in scalar context the result set is
concatenated with newlines.

This procedure is used internally but might also be useful outside.

=cut

# SUB get_query_columns (build list of columns a query would return)
# ------------------------------------------------------------------------- #
sub get_table_columns {
    my $self = shift;
    my $table = shift;

    my @result = $self->get_query_columns ("select * from $table");

    wantarray ? @result : join "\n", @result;
}
# ------------------------------------------------------------------------- #

# ------------------------------------------------------------------------- #
# SUB validate_read_format
# ------------------------------------------------------------------------- #

=head2 validate_read_format ($format)

mandatory arguments: 

optional arguments: $format

sample call: $client->validate_read_format ($my_format)

If $format is a format which could be parsed by the object 
validate_read_format terminates normally. Otherwise an error
is raised.

This procedure is used internally but might also be useful outside.

=cut

# SUB validate_read_format
# ------------------------------------------------------------------------- #
sub validate_read_format {  
    my $class = shift;
    my $read_format = shift;

    if ( !defined ($formats{$read_format})) {
      Carp::croak ("unknown format \"$read_format\"\n");
    } elsif (( $_READ_ & $formats{$read_format}) == 0) {
      Carp::croak ("operation \"read\" not supported for format \"$read_format\"\n");
    } else {
	return 1;
    }
}
# ------------------------------------------------------------------------- #

# ------------------------------------------------------------------------- #
# SUB validate_print_format
# ------------------------------------------------------------------------- #
#
# usage: validate_print_format (<print_format>)
#   check whether <print_format> is a valid one
#

=head2 validate_print_format ($format)

mandatory arguments: 

optional arguments: $format

sample call: $client->validate_prin_format ($my_format)

If $format is a format which could be used to print object data 
validate_read_format terminates normally. Otherwise an error
is raised.

This procedure is used internally but might also be useful outside.

=cut

# SUB validate_print_format
# ------------------------------------------------------------------------- #
sub validate_print_format {  
    my $class = shift;
    my $print_format = shift;

    if ( !defined ($formats{$print_format})) {
      Carp::croak ("unknown format \"$print_format\"\n");
    } elsif ( ($_WRITE_ & $formats{$print_format}) == 0) {
      Carp::croak ("operation \"print\" not supported for format \"$read_format\"\n");
    } else {
	return 1;
    }
}
# ------------------------------------------------------------------------- #

# ------------------------------------------------------------------------- #
# SUB list_tables
# ------------------------------------------------------------------------- #

=head2 list_tables

mandatory arguments: 

optional arguments:

sample call: my @array = $client->list_tables()

returns the names of all tables for which currently data is stored internally

=cut

# SUB list_tables
# ------------------------------------------------------------------------- #
sub list_tables {
    my $self = shift;

    return keys %{$self->{TABLE_DATA}};
}
# ------------------------------------------------------------------------- #

# ------------------------------------------------------------------------- #
# SUB get_table_order
# ------------------------------------------------------------------------- #

=head2 get_table_order ([$mode])

mandatory arguments: 

optional arguments: $mode

sample call: @ordered_table_list = $client->get_table_order ("insert")

get_table_order uses the database table RCMADM.RCM_TABLES to construct
and order list of table names in dependence of $mode if present
or $client->mode otherwise. The table ordering returned is exactly the same
which is used by build_and_execute_commands when the data stored
internally is translated into dml commands.

In select mode, the function would use a alternative sort order 
if supplied by the internal object data 'SortedTables' which is a reference
to a sorted list of table names. Used in copy_records.pl to apply the
sort order defined in the ORDER_NUM columns of the table RCMADM.DUMP_DATA

This procedure is used internally but might also be useful outside.

=cut

# SUB get_table_order
# ------------------------------------------------------------------------- #
#
# retrieve table_names from RCMADM.RCM_TABLES order depends on mode:
#  "select"   INS_POSITION ascending 
#  "insert"   INS_POSITION ascending 
#  "update"   INS_POSITION descending (might not work!) 
#  "delete"   INS_POSITION descending 
#
#  usage: get_table_order ([<mode>])
#  if <mode> is not specified $self->{PARAMS}->{mode} is used
#
# 
sub get_table_order {
    my $self = shift;
    my $mode = shift || $self->mode;
    my ($status,$msg,$query);
    
    SWITCH: {
        if ($mode eq "select") {
            
            # if sort order was provided by SortedTables
            # parameter then we just use this presorted list
            if (defined $self->{PARAMS}->{SortedTables}) {
                my $ref = $self->{PARAMS}->{SortedTables};
                return @$ref;
            }
            
            $query = "select table_name from rcmadm.rcm_tables " . 
                     "order by ins_position";
        } elsif ($mode eq "insert") {
            $query = "select table_name from rcmadm.rcm_tables " . 
                     "order by ins_position";
            last SWITCH;
        } elsif ($mode eq "update" || $mode eq "delete") {
            $query = "select table_name from rcmadm.rcm_tables " . 
                     "order by ins_position desc";
            last SWITCH;
        }
        # TODO cry when arriving here
    }
    ($status, $msg) = $self->{SUSI}->query($query);
    Carp::Croak("Error reading from RCM -- $msg\nLast action -- $query\n") 
	if ($status != 1403 && $status > 0);

    return split /$s_rsep/, lc($msg);
}
# ------------------------------------------------------------------------- #

=head1 METHODS working on the object data

=cut 

# ------------------------------------------------------------------------- #
# SUB collect_table_data (retrieve data from the database and store it
#     within the object)
# ------------------------------------------------------------------------- #
#
#   store the result in $self->{TABLE_DATA}->{$table}
#

=head2 collect_table_data ($table_name, $query [, $replacement])

mandatory arguments: $table_name, $query

optional arguments: $replacement

sample call: $client->collect_table_data ("host", 
					  "SELECT * FROM host WHERE os_version = '5.8.0.0'", {"os_version" => "5.9.0.0"})

collect_table_data runs $query against the RCM database and
stores the result in the internal data hash under the key $table_name.
Usually $table_name would be the name of the database table which
is requested by $query, but in principle you can store the
retrieved data under an arbitrary $table_name. (See remarks below
on column/table sort)

The optional parameter $replacement is a hash reference. The hash
keys correspond to columns (retrieved by $query) whereas the hash
values are used to overwrite the retrieved values for those columns.
In the example all values of the "os_version" are set to the value
"5.9.0.0" before data is stored internally.

=cut

# SUB collect_table_data (retrieve data from the database in store it
#     within the object)
# ------------------------------------------------------------------------- #
sub collect_table_data {  # performs replacement
    my $self = shift;
    my $table = shift;
    my $query = shift;
    my $replacement = shift; # reference to a hash of form:
                             #   <column> => <value_to_set>

    my $ptr = $self->{TABLE_DATA};

    $self->_collect_table_data ($ptr, $table, $query, $replacement);

} # sub collect_table_data

sub _collect_table_data {
    my $self = shift;
    my $ptr = shift;         # pointer to current data hash
    my $table = shift;
    my $query = shift;
    my $replacement = shift; # reference to a hash of form:
                             #   <column> => <value_to_set>

    my ($key, $line, $status, $msg);
    my @values = (); 
    my @fields = $self->get_query_columns ($query);

    if ($self->debug >= 4) {
	print STDERR " * * * * performing query:\n";
	print STDERR "\ttarget table: $table\n";
	print STDERR "\tquery       : $query\n";
    }

    ($status, $msg) = $self->{SUSI}->query($query);
    Carp::croak("Error reading from RCM -- $msg\nLast action -- $query\n") 
	if ($status != 1403 && $status > 0);

    if ($self->debug >= 4) {
	print STDERR "\tresult       : $msg\n";
    }
    # if $table is unknown, but data has been found
    #    => make new anonymous list
    $ptr->{$table} = [] 
	if (! defined $ptr->{$table} and $msg ne "");
    foreach $line (split /$s_rsep/, $msg) {
	# force that trailing NULL values are translated into "" 
	@values = split /$s_fsep/, $line, $#fields +1;

	# the following replacement strategy might look inefficient
	# but I want to retain the column order (not guarenteed when
	# using a hash)
	if (defined $replacement and (keys %{$replacement} != 0) ) {
	    foreach $key (keys %{$replacement}) {
		for (my $i=0; $i <= $#fields; $i++ ) {
		    $values[$i] = $replacement->{$key} 
		    if ($key eq $fields[$i]);
		}
	    }
	}
	push (@{$ptr->{$table}}, 
	      _compose_line_order_ccvv (@fields, @values));
    }

    # TODO make status setting dependent of $ptr (current data hash)

    # after collecting data some status flags are reset since their 
    # corresponding state is in doubt
    $self->{STATUS}->{column_sort_done} = 0;
    $self->{STATUS}->{get_proc_done} = 0;
    $self->{STATUS}->{norm_tab_names_done} = 0;

} # sub _collect_table_data
# ------------------------------------------------------------------------- #

# ------------------------------------------------------------------------- #
# SUB remove_table_data (remove some or all data from the objects
#      internal data hash) 
# ------------------------------------------------------------------------- #
#
#   removes $self->{TABLE_DATA}->{$table} with $table=<table_name>
#   if <table_name> is not given all data is removed

=head2 remove_table_data ([$table])

mandatory arguments: 

optional arguments: $table

sample call: $client->remove_table_data ("host")

Without any argument remove_table_data discards all data stored
within the objects internal data hash. If $table is specified
then only the data stored under the key $table is removed from the
data hash.

=cut

# SUB remove_table_data (remove some or all data from the objects
#      internal data hash) 
# ------------------------------------------------------------------------- #
sub remove_table_data {  
    my $self = shift;
    my $table = shift;

    my $ref = \$self->{TABLE_DATA};

    # TODO: no check whether $table argument, if specified, is a valid
    #       key for $data_hash

    if ( defined $table) {
	delete $$ref->{$table};
    } else {
	$$ref = {};
    }

}
# ------------------------------------------------------------------------- #

# ------------------------------------------------------------------------- #
# SUB remove_bad_table_data (remove some or all data from the objects
#      internal error data hash) 
# ------------------------------------------------------------------------- #
#
#   removes $self->{BAD_TABLE_DATA}->{$table} with $table=<table_name>
#   if <table_name> is not given all data is removed

=head2 remove_bad_table_data ([$table])

mandatory arguments: 

optional arguments: $table

sample call: $client->remove_bad_table_data ("host")

Without any argument remove_bad_table_data discards all data stored
within the objects internal error data hash. If $table is specified
then only the data stored under the key $table is removed from the
error data hash.

=cut

# SUB remove_bad_table_data (remove some or all data from the objects
#      internal error data hash) 
# ------------------------------------------------------------------------- #
sub remove_bad_table_data {  
    my $self = shift;
    my $table = shift;

    my $ref = \$self->{BAD_TABLE_DATA};

    # TODO: no check whether $table argument, if specified, is a valid
    #       key for $data_hash

    if ( defined $table) {
	delete $$ref->{$table};
    } else {
	$$ref = {};
    }

}
# ------------------------------------------------------------------------- #

# ------------------------------------------------------------------------- #
# SUB read_table_data
# ------------------------------------------------------------------------- #
# data is stored in $self->{TABLE_DATA}

=head2 read_table_data ($format, @in_buffer)

mandatory arguments: $format, @in_buffer

optional arguments: 

sample call: $client->read_table_data ("stanza", @buffer)

The text buffer @in_buffer is expected to contain table data
in format $format. That buffer will be parsed and the results
are stored in the objects internal data hash.

Since table data coming from a text buffer could be unsorted
the column sort state of the object is reset to 0 ("not done").

=cut

# SUB read_table_data
# ------------------------------------------------------------------------- #
sub read_table_data {  
    my $self = shift;
    my $read_format = shift; 
    my @in_array = @_; 

    my $data_hash = $self->{TABLE_DATA};

    $self->validate_read_format($read_format);
    my $work_to_do = "_" . $read_format . "_2_" . "internal";
    chomp(@in_array);
    $self->$work_to_do (@in_array);

    if ($self->debug >= 4) {
	print STDERR " * * * * buffer contents:\n";
	foreach my $key ( keys %{$data_hash} ) {
	    print STDERR "\n\ttable \"$key\":\n";
	    foreach my $entry (@{$data_hash->{$key}}) {
		print STDERR "\t   $entry\n";
	    }
	}
    }
    # after reading data some status flags are reset since their corresponding
    # state is in doubt
    $self->{STATUS}->{column_sort_done} = 0;
    $self->{STATUS}->{get_proc_done} = 0;
    $self->{STATUS}->{norm_tab_names_done} = 0;
}
# ------------------------------------------------------------------------- #

# ------------------------------------------------------------------------- #
# SUB print_table_data
# ------------------------------------------------------------------------- #
# data is read from $self->{TABLE_DATA}
# result depends on $self->{PARAMS}->{mode}
#                   $self->{PARAMS}->{table_sort}
#                   $self->{PARAMS}->{column_sort}

=head2 print_table_data ($format [, $table])

mandatory arguments: $format

optional arguments: $table

sample call: @buffer = $client->print_table_data ("passwd", "host")

In the standard form print_table_data returns the contents of
the internal data hash as a list of text lines using format $format.
If desired (the object parameter table_sort is set to 1) the
tables are sorted implicitely according to $client->mode.

If $table is specified just the data stored under the key $table
is returned.

If the procedure is called in scalar context the result set is
concatenated with newlines.

If needed print_table_data performs a column sort implicitely.

=cut

# SUB print_table_data
# ------------------------------------------------------------------------- #
sub print_table_data {  
    my $self = shift;
    my $print_format = shift;
    my $table = shift;
    my @out_array = ();

    my $data_hash = $self->{TABLE_DATA};

    $self->validate_print_format($print_format);

    # TODO is it usuful to force sort here?
    $self->sort_columns()
	if ( $self->{PARAMS}->{column_sort} &&
	     (! $self->{STATUS}->{column_sort_done}) );

    my $work_to_do ="_internal" . "_2_" . $print_format;
    # TODO: no check whether $table argument, if specified, is a valid
    #       key for $data_hash
    if ( defined $table ) {
	@out_array = $self->$work_to_do ($data_hash, $table);
    } else {
	@out_array = $self->$work_to_do ($data_hash);
    }

    wantarray ? @out_array : join "\n", @out_array;

}

# ------------------------------------------------------------------------- #
# SUB print_bad_table_data
# ------------------------------------------------------------------------- #

=head2  print_bad_table_data ($format [,$table])

mandatory arguments: $format

optional arguments: $table

sample call: @buffer = $client->print_bad_table_data ("stanza")

print_bad_table_data can be used after build_and_execute_commands
to get all data records which were processed unsuccessfully
by build_and_execute_commands. 

In the standard form print_bad_table_data returns the contents of
the those data as a list of text lines using format $format.
No sort (of tables or columns, respectively) is done implicitely.
So data is printed as stored internally.

If $table is specified just the data stored under the key $table
is returned.

If the procedure is called in scalar context the result set is
concatenated with newlines.

=cut

# SUB print_bad_table_data
# ------------------------------------------------------------------------- #
# retrieves data from $self->{BAD_TABLE_DATA} without any sorting
#
# before calling the following procedures should run:
# build_and_execute_commands()
sub print_bad_table_data {  
    my $self = shift;
    my $print_format = shift;
    my $table = shift;
    my @out_array = ();

    my $data_hash = $self->{BAD_TABLE_DATA};

    $self->validate_print_format($print_format);

    # store old table_sort parameter
    my $current_table_sort = $self->{PARAMS}->{table_sort};
    # prevent table sort during output of bad table data
    # since table sorting could skip some data
    $self->{PARAMS}->{table_sort} = 0;

    my $work_to_do ="_internal" . "_2_" . $print_format;
    # TODO: no check whether $table argument, if specified, is a valid
    #       key for $data_hash
    if ( defined $table ) {
	@out_array = $self->$work_to_do ($data_hash, $table);
    } else {
	@out_array = $self->$work_to_do ($data_hash);
    }

    # restore old table_sort parameter
    $self->{PARAMS}->{table_sort} = $current_table_sort;

    wantarray ? @out_array : join "\n", @out_array;

}
# ------------------------------------------------------------------------- #

# ------------------------------------------------------------------------- #
# SUB print_unused_table_data
# ------------------------------------------------------------------------- #

=head2  print_unused_table_data ($format [,$table])

mandatory arguments: $format

optional arguments: $table

sample call: @buffer = $client->print_unused_table_data ("stanza")

print_unused_table_data can be used after build_and_execute_commands
to get all data records which were not processed 
by build_and_execute_commands. (This scenario occurs if data is store
under a key $table which is not listed in RCMADM.RCM_TABLES.)

In the standard form print_unused_table_data returns the contents of
the those data as a list of text lines using format $format.
No sort (of tables or columns, respectively) is done implicitely.
So data is printed as stored internally.

If $table is specified just the data stored under the key $table
is returned.

If the procedure is called in scalar context the result set is
concatenated with newlines.

=cut

# SUB print_unused_table_data
# ------------------------------------------------------------------------- #
# retrieves data from $self->{TABLE_DATA} without any sorting
#
# before calling the following procedures should run:
# build_and_execute_commands()
sub print_unused_table_data {  
    my $self = shift;
    my $print_format = shift;
    my $table = shift;
    my @out_array = ();

    my $data_hash = $self->{TABLE_DATA};

    $self->validate_print_format($print_format);

    # store old table_sort parameter
    my $current_table_sort = $self->{PARAMS}->{table_sort};
    # prevent table sort during output of bad table data
    # since table sorting could skip some data
    $self->{PARAMS}->{table_sort} = 0;

    my $work_to_do ="_internal" . "_2_" . $print_format;
    # TODO: no check whether $table argument, if specified, is a valid
    #       key for $data_hash
    if ( defined $table ) {
	@out_array = $self->$work_to_do ($data_hash, $table);
    } else {
	@out_array = $self->$work_to_do ($data_hash);
    }

    # restore old table_sort parameter
    $self->{PARAMS}->{table_sort} = $current_table_sort;

    wantarray ? @out_array : join "\n", @out_array;

}
# ------------------------------------------------------------------------- #

# ------------------------------------------------------------------------- #
# SUB dump_table_data
# ------------------------------------------------------------------------- #

=head2  dump_table_data ($table)

mandatory arguments: $table

optional arguments: n/a

sample call: $ref = $client->dump_table_data ("rcm.accounts")

converts the data stored under the given table name into an array of hashes.
a reference to that array is returned.

if nothing is known about <$table> undef is returned.

=cut

# SUB dump_table_data
# ------------------------------------------------------------------------- #
sub dump_table_data {
    my $self = shift;
    my $table = shift;

    my $data_hash = $self->{TABLE_DATA};

    return undef unless (exists $data_hash->{$table});

    my @res = ();
    foreach $line (@{$data_hash->{$table}}) {
	my %data = _split_line_order_cvcv ($line);
	push(@res, \%data);
    }
    return \@res;
}
# ------------------------------------------------------------------------- #

# ------------------------------------------------------------------------- #
# SUB sort_columns (sort columns according to mode)
# ------------------------------------------------------------------------- #

=head2  sort_columns([$mode])

mandatory arguments: 

optional arguments: $mode

sample call: $client->sort_columns("delete")

sort_columns sorts the object's data by changing the order
of <column>="<value>" segments within each data record according
to an ordering given by _get_column_list. The ordering depends on
$mode if set or on $client->mode otherwise.

In certain cases sort_columns will be called implicitly. But it is
better to call sort_columns explicitly before you rely on sorted
data. This does not need extra time since implicit sorting occurs 
only if the column sort state is in doubt.

See L<UNDERSTANDING COLUMN SORT> for more information.

=cut

# SUB sort_columns (sort columns according to mode) '
# ------------------------------------------------------------------------- #
#  uses _sort_columns internally
#
#  calling sort_columns forces column sort even if 
#  $self->{PARAMS}->{column_sort} = 0
#
# so far _get_column_list() (which asks _get_procedure ) will be called
# for every table within every call of sort_columns
# ------------------------------------------------------------------------- #
sub sort_columns {  
    my $self = shift;
    my $mode = shift || $self->mode;
    my $add_missing_values = 0;

    $self->_sort_columns ($mode, $add_missing_values);

}
# ------------------------------------------------------------------------- #

# ------------------------------------------------------------------------- #
# SUB remove_surrounding_whitespace (delete leading/trailing white space
#   from data fields)
# ------------------------------------------------------------------------- #

=head2  remove_surrounding_whitespace ([$table])

mandatory arguments:

optional arguments: $table

sample call: $client->remove_surrounding_whitespace ("corba_orbix")

remove leading and trailing white space from all data fields.

=cut

#
# SUB remove_surrounding_whitespace (delete leading/trailing white space
#   from data fields)
# ------------------------------------------------------------------------- #
sub remove_surrounding_whitespace {
    my $self = shift;
    my $table = shift;

    my $data_hash = $self->{TABLE_DATA};
    # TODO: no check whether $table argument, if specified, is a valid
    #       key for $data_hash

    my @table_list = (defined $table) ? ($table) : keys %{$data_hash};

    foreach $table (@table_list) {
	if ($self->debug >= 3) {
	    print STDERR " * * * remove leading/trailing white space "
	      ."from data fields of table " .
		"\"$table\"\n";
	}
	my $line_count = $#{$data_hash->{$table}};
	for (my $i = 0; $i <= $line_count; $i++ ) {
	    my $line = $data_hash->{$table}->[$i];
	    my %data = _split_line_order_cvcv ($line);
	    foreach my $key (keys %data) {
		$data{$key} =~ s/^\s+//o;
		$data{$key} =~ s/\s+$//o;
	    }
	    my $new_line = _compose_line_order_cvcv (%data);
	    $data_hash->{$table}->[$i] = $new_line;
	}
    }
}
# ------------------------------------------------------------------------- #

# ------------------------------------------------------------------------- #
# SUB remove_duplicate_data (drops data records occuring more than once)
# ------------------------------------------------------------------------- #

=head2  remove_duplicate_data ([$table])

mandatory arguments: 

optional arguments: $table

sample call: $client->remove_duplicate_data ("corba_orbix")

remove_duplicate_data removes duplicate data records from the internal
data hash. If $table is specified the efforts are restricted to that
table. remove_duplicate_data requires that the columns are sorted (w.r.t
the main working mode of the object, i.e. $client->mode). If this condition
is not satisfied than an implicite column sort is triggered.

As as side effect remove_duplicate_data sort the data record within
each table or the one table given by $table, respectively.

=cut

#
# SUB remove_duplicate_data (drops data records occuring more than once)
# ------------------------------------------------------------------------- #
# requires that columns are sorted (if not sort_columns() is run
# implicitely. BEWARE: even if the optional $table argument is used
# the implicitely triggerd column sort works on all tables!
# ------------------------------------------------------------------------- #
sub remove_duplicate_data {
    my $self = shift;
    my $table = shift;

    my $data_hash = $self->{TABLE_DATA};
    # TODO: no check whether $table argument, if specified, is a valid
    #       key for $data_hash

    my @table_list = (defined $table) ? ($table) : keys %{$data_hash};

    # force column sort if not done yet
    unless ($self->{STATUS}->{column_sort_done} &&
	    $self->{STATUS}->{column_sort_mode} eq $self->mode) {
	if ($self->debug >= 3) {
	    print STDERR " * * * remove_duplicate_data: " . 
		"trigger column sort for mode \"" . $self->mode . "\"\n";
	}
	$self->sort_columns();
    }

    foreach $table (@table_list) {
	if ($self->debug >= 3) {
	    print STDERR " * * * removing duplicate data for table " .
		"\"$table\"\n";
	}	
	my $list_ref = $data_hash->{$table};
	# after sorting @{$list_ref} duplicate entries are neighbours:
	@{$list_ref} = sort @{$list_ref};
	# loop ends at the penultimate element
	# it might look danagerous to loop over list which changes 
	# its size inside the loop, but that's perl!
	for ( my $i=0; $i < $#{$list_ref}; $i++) {
	    if ( $list_ref->[$i] eq $list_ref->[$i+1] ) {
		if ($self->debug >= 4) {
		    print STDERR "\t removing duplicate record: " .
			$list_ref->[$i] . "\n\n";
		}
		splice (@$list_ref, $i, 1);
		$i--; # decrement counter for the case that a record
		      # occured more than twice
	    }
	}
    }
    
}
# ------------------------------------------------------------------------- #

# ------------------------------------------------------------------------- #
# SUB check_susi_privilege
# ------------------------------------------------------------------------- #

=head2 check_susi_privilege ($susi_roles)

mandatory arguments: $susi_roles

optional arguments:

sample call: $client->check_susi_privilege ("HOST-ADM")

check whether the current user has the given susi privilege.
returns a true value if yes and throws an exception otherwise.

=cut

#
# SUB check_susi_privilege
# ------------------------------------------------------------------------- #
# requires that columns are sorted (if not sort_columns() is run
# implicitely. BEWARE: even if the optional $table argument is used
# the implicitely triggerd column sort works on all tables!
# ------------------------------------------------------------------------- #
sub check_susi_privilege {
    my $self = shift;
    my $susi_role = shift;
    # little check to prevent SQL injection:
    Carp::croak ("SUSI role to check (\"$susi_role)\"".
	" contains invalid characters") unless ($susi_role =~ /^(\w|-)+$/);

    my ($status, $message) =
      $self->{SUSI}->exec_dml("begin rcm.chkgrp('$susi_role', ''); end;");
    if ($status) {
# 	my @msg_lines = split /$s_rsep/, $message;
# 	print STDERR "\n### ERROR occured in command:\n",
# 	  "### $command\n", "### $msg_lines[0]\n", 
# 	    (@msg_lines > 1) ? "### $msg_lines[1]\n" : "\n";
	Carp::croak("Insufficient privileges. $susi_role required.");
    }

    return 1;
}
# ------------------------------------------------------------------------- #

# ------------------------------------------------------------------------- #
# SUB check_and_sort_columns (sort columns according to mode)
# ------------------------------------------------------------------------- #

=head2  check_and_sort_columns([$mode])

mandatory arguments: 

optional arguments: $mode

sample call: $error_count = $client->check_and_sort_columns("delete")

check_and_sort_columns sorts the object's data by changing the order
of <column>="<value>" segments within each data record according
to an ordering given by _get_column_list. The ordering depends on
$mode if set or on $client->mode otherwise.

check_and_sort_columns assumes that all columns occuring in the
order to achieve are present in the data. Data not satisfying this
requirement is moved from the data hash to the error data hash.

The return value of check_and_sort_columns is the number
of data records not containing the expected columns.

See L<UNDERSTANDING COLUMN SORT> for more information.

=cut

# SUB check_and_sort_columns (sort columns according to mode) '
# ------------------------------------------------------------------------- #
# uses _sort_columns_with_check internally
#
# requires exact matching and presence of all columns (except execmode)
# data not satisfying this will be moved to $self->{BAD_TABLE_DATA}
# ------------------------------------------------------------------------- #
sub check_and_sort_columns {  
    my $self = shift;
    my $mode = shift || $self->mode;
    my $add_missing_values = 0;
    my $error_cnt = 0;

    $error_cnt = 
	$self->_sort_columns_with_check ($mode, $add_missing_values);

    return $error_cnt;
}
# ------------------------------------------------------------------------- #

# ------------------------------------------------------------------------- #
# SUB fillup_and_sort_columns
# ------------------------------------------------------------------------- #

=head2  fillup_and_sort_columns([$mode])

mandatory arguments: 

optional arguments: $mode

sample call: $client->fillup_and_sort_columns ("insert")

fill_and_sort_columns sorts the object's data by changing the order
of <column>="<value>" segments within each data record according
to an ordering given by _get_column_list. The ordering depends on
$mode if set or on $client->mode otherwise.

If columns requested by the prescribed column order are not present
in the data they are added to the data (in the correct place) with
empty value.

See L<UNDERSTANDING COLUMN SORT> for more information.

=cut

# SUB fillup_and_sort_columns
# ------------------------------------------------------------------------- #
#  uses _sort_columns internally
#
#  calling sort_columns forces column sort even if 
#  $self->{PARAMS}->{column_sort} = 0
#
# so far _get_column_list() (which asks _get_procedure ) will be called
# for every table within every call of sort_columns
# ------------------------------------------------------------------------- #
sub fillup_and_sort_columns {  
    my $self = shift;
    my $mode = shift || $self->mode;
    my $add_missing_values = 1;

    $self->_sort_columns ($mode, $add_missing_values);

}
# ------------------------------------------------------------------------- #

# ------------------------------------------------------------------------- #
# SUB get_procedures (fill $self->{TABLE_PROCS} according to $mode)
# ------------------------------------------------------------------------- #

=head2  get_procedures([$mode])

mandatory arguments: 

optional arguments: $mode

sample call: $client->get_procedures ("update")

In dependence of $mode (or $self->mode if called without argument)
get_procedures consults RCMADM.RCM_TABLES to retrieve the name
of the insert/update/delete (according to $mode) procedure defined 
there for each table. The results are stored internally for later
use (within build_commands() or build_and_execute_commands()).

=cut

# SUB get_procedures (fill $self->{TABLE_PROCS} according to $mode)
# ------------------------------------------------------------------------- #
# so far all column sort procedures ask theirselves RCMADM.RCM_TABLES
# for insert/update/delete procedures (i.e. they don't rely on a run of
# get_procedures before they are called)
# ------------------------------------------------------------------------- #
sub get_procedures {
    my $self = shift;
    my $mode = shift || $self->mode;

    my $data_hash = $self->{TABLE_DATA};

    if ( $self->debug >= 2 ) {
	print STDERR " * * retrieving \"$mode\" procedures:\n";
    }
    foreach $table (keys %{$data_hash}) {
	$self->{TABLE_PROCS}->{$table} = 
	    $self->_get_procedure ($table, $mode);
	
	if ( $self->debug >= 3 ) {
	    print STDERR "\ttable: " . $table . " \"$mode\"-proc: " 
		. $self->{TABLE_PROCS}->{$table} . "\n";
	}
    }
    $self->{STATUS}->{get_proc_done} = 1;
    $self->{STATUS}->{get_proc_mode} = $mode;

}
# ------------------------------------------------------------------------- #

# ------------------------------------------------------------------------- #
# SUB build_commands (and return they as a list)
# ------------------------------------------------------------------------- #

=head2  build_commands ([$mode])

mandatory arguments: 

optional arguments: $mode

sample call: @buffer = $client->build_commands ("insert")

build_commands translates the data stored in the objects data hash
into SQL dml commands. The commands are returned as a list (which
is joined with newlines if called in scalar context)

To produce correct results you should call get_procedures and
a suitable column sort procedure before running build_commands (and
all these procedures should use the same mode). It is best to 
do it as in the following example:

  # set mode if not already done
  $client->mode($mode_to_use);
  # retrieve procedure name and store it
  $client->get_procedures();
  # sort columns with adding missing columns
  $client->fillup_and_sort_columns();
  # if you are paranoid you can use alternatively
  #$client->check_and_sort_columns();
  # now you can safely build commands
  $client->build_commands();

=cut

# SUB build_commands (and return they as a list)
# ------------------------------------------------------------------------- #
# before calling it the following procedures should run:
# get_procedures()
# fillup_and_sort_columns()
# all with the same mode!!!
# ------------------------------------------------------------------------- #
sub build_commands {
    my $self = shift;
    my $mode = shift || $self->mode;
    my @result = ();

    if ( $self->debug >= 2 ) {
	print STDERR " * * building dml commands for mode \"$mode\"\n";
    }
    foreach $table ( $self->get_table_order($mode) ) {
	if ( $self->debug >= 3 && (defined $self->{TABLE_DATA}->{$table})) {
	    print STDERR " * * * building dml commands: table: \"$table\""
		. " mode: \"$mode\"\n";
	}
	for (my $i = 0; $i <= $#{$self->{TABLE_DATA}->{$table}}; $i++ ) {
	    my $command = $self->_build_command ($table,
	       ${$self->{TABLE_DATA}->{$table}}[$i], $mode );
	    # TODO perhaps improve that one:
	    # we do not worry about empty $command's here
	    # we just skip them
	    push (@result, $command) if ($command);
            if ( $self->debug >= 4 ) {
	       print STDERR "\tcommand: $command\n";
	    }
        }
    }

    wantarray ? @result : join ('\n', @result);
   

} # sub build_commands
# ------------------------------------------------------------------------- #

# ------------------------------------------------------------------------- #
# SUB build_and_execute_commands
# ------------------------------------------------------------------------- #

=head2  build_and_execute_commands ([$mode])

mandatory arguments: 

optional arguments: $mode

sample call: $error_count = $client->build_and_execute_commands ()

build_and_execute_commands translates the data stored in the objects 
data hash into SQL dml commands. The commands are executed immediately.
If a command runs successfully the corresponding data record
is removed from the objects data hash. If an error occurs the data
record is moved from the data hash to the error data hash.
Errors are reported to stderr and build_and_execute_commands will
continue with the next data record.

When build_and_execute_commands finishes the data hash will just
contain those data that are not processed at all. (This can happen
if the table name is not found in RCMADM.RCM_TABLES.)

The return value of build_and_execute_commands is the number
of unsuccessfully processed data records.

To produce correct results you should call get_procedures and
a suitable column sort procedure before running build_commands (and
all these procedures should use the same mode). It is best to 
do it as in the following example:

  # set mode if not already done
  $client->mode($mode_to_use);
  # retrieve procedure name and store it
  $client->get_procedures();
  # sort columns with adding missing columns
  $client->fillup_and_sort_columns();
  # if you are paranoid you can use alternatively
  #$client->check_and_sort_columns();
  # now you can try it
  $client->build_and_execute_commands();

  # ok, now let's see what went wrong:
  @data_never_processed = $client->print_unused_table_data("stanza");
  @data_processed_with_errors = $client->print_bad_table_data("stanza");

=cut

# SUB build_and_execute_commands
# ------------------------------------------------------------------------- #
# before calling it the following procedures should run:
# get_procedures()
# fillup_and_sort_columns()
# all with the same mode!!!
# ------------------------------------------------------------------------- #
sub build_and_execute_commands {
    my $self = shift;
    my $mode = shift || $self->mode;
    my @result = (); # not used so far
    my ($status, $message, $command);
    my $error_cnt = 0;

    my $data_hash = $self->{TABLE_DATA};
    my $error_hash = $self->{BAD_TABLE_DATA};

    if ( $self->debug >= 2 ) {
	print STDERR " * * building dml commands for mode \"$mode\"\n";
    }
    foreach $table ($self->get_table_order($mode)) {
	next if ( ! (defined $data_hash->{$table})
		  || $#{$data_hash->{$table}} < 0);
	if ( $self->debug >= 3 ) {
	    print STDERR " * * * building dml commands: table: \"$table\""
		. " mode \"$mode\"\n";
	}
	# due to 'shift @{}' treated data will be removed 
	# from self->{TABLE_DATA}
	while (  defined (my $line = shift @{$data_hash->{$table}})) {
	    $command = $self->_build_command ($table, $line, $mode);
            if ( $self->debug >= 4 ) {
	       print STDERR "\tcommand: $command\n";
	    }
	    if ($command eq "") {
		print STDERR "\n### ERROR: empty command encountered\n";
		print STDERR "### the corresponding data record of \""
		    . "$table\" might be lost\n";
		next;
	    }
	    ($status, $message) = $self->{SUSI}->exec_dml($command);
	    if ($status) {
		my @msg_lines = split /$s_rsep/, $message;
		print STDERR "\n### ERROR occured in command:\n",
		"### $command\n", "### $msg_lines[0]\n", 
		(@msg_lines > 1) ? "### $msg_lines[1]\n" : "\n";
		# copy bad data to $self->{BAD_TABLE_DATA} for reporting
		$error_hash->{$table} = [] 
		    if (! defined $error_hash->{$table} );
		push (@{$error_hash->{$table}}, $line);
		$error_cnt++;
	    } elsif ($self->exec_mode eq "script") { # TODO change this later
		$self->{SUSI}->commit();
		if ( $self->debug >= 4 ) {
		    print STDERR "\tsuccessfully processed\n\n";
		}
	    }
	}
	# now $self->{TABLE_DATA}->{$table} should be empty
	# remove the empty table in a safe way from $self->{TABLE_DATA}
	delete $data_hash->{$table} if ($#{$data_hash->{$table}} < 0);
    }
    # at this point 
    # $self->{TABLE_DATA} contains unprocessed data 
    #    (occurs if table_name not part of list
    #    derived using $self->get_table_order())
    # $self->{BAD_TABLE_DATA} contains data not successfully processed

    return $error_cnt;
} # sub build_and_execute_commands
# ------------------------------------------------------------------------- #

# ------------------------------------------------------------------------- #
# SUB normalize_table_names
# ------------------------------------------------------------------------- #

=head2 normalize_table_names ([$remove_unresolved])

mandatory arguments: 

optional arguments: $remove_unresolved

sample call: $statistics = $client->normalize_table_names ()

If possible normalize_table_names does change the keys (table names)
of the internal data hash such that they fit table name known in
RCMADM.RCM_TABLES. Then later accesses to RCMADM.RCM_TABLES will
succeed. Usually you call normalize_table_names after read_table_data
(or collect_table_data) has been used. So you are allowed to use
table names which do not match exactly those in RCMADM.RCM_TABLES.
You can use lower case, upper case or even mixed case. If you use tables
belonging to RCM's schema within the RCM database you can
qualify the table name with a leading "rcm." or not. Both variants will
be recognized.

If a hash key (table name) cannot be found in RCMADM.RCM_TABLES
nothing special will happen. However, if you call the method like
$client->normalize_table_names (1) unresolved table names and their
data records will be moved to the error data hash (for later processing).

=cut

# SUB normalize_table_names
# ------------------------------------------------------------------------- #
# change the keys of $self->{TABLE_DATA} (which are in fact table names)
# according to the following rules:
# 1. all table names are lowercase (convert if this is not the case) 
# 2. if uc(<table_name>) is not contained in RCMADM.RCM_TABLES:
#    2a. if <table_name> contains no '.' replace <table_name> by
#        rcm.<table_name> if uc(rcm.<table_name>) occurs in RCMADM.RCM_TABLES
#    2b. if <table_name> is of the form rcm.<name> replace <table_name>
#        by <name> if uc(<name>) occurs in RCMADM.RCM_TABLES
# 
# ------------------------------------------------------------------------- #
sub normalize_table_names {
    my $self = shift;
    # default behaviour: unresolved data remains in $self->{TABLE_DATA}
    my $remove_unresolved = shift || 0;
    my ($status, $message, $command);
    my ($unresolve_cnt, $rename_cnt, $append_cnt) = (0,0,0);
    my $result;

    my $data_hash = $self->{TABLE_DATA};
    my $error_hash = $self->{BAD_TABLE_DATA};

    if ( $self->debug >= 2 ) {
	print STDERR " * * normalizing table names\n";
    }

    foreach my $old_tab_name (keys %{$data_hash}) {
	if ( $self->debug >= 4 ) {
	    print STDERR "\n * * * * working on table \"$old_tab_name\"\n";
	}
	# to be safe: ensure that $old_table_name contains at most
	# one '.'
	if ( ($old_tab_name =~ tr/././) > 1 ) {
	    print STDERR "\n### ERROR: invalid table name format:\n";
	    print STDERR "### $old_tab_name\n";

	    if ( $remove_unresolved ) {
		if ( $self->debug >= 3 ) {
		    print STDERR " * * * discarding table data of "
			. "\"$old_tab_name\"\n";
		}
		# TODO perhaps the following should be improved
		# we expect here that $self->{BAD_TABLE_DATA}->{$old_tab_name}
		# doesn't exists
		# move data: $self->{TABLE_DATA}->{$old_tab_name} ->
		# $self->{BAD_TABLE_DATA}->{$old_tab_name}
		$error_hash->{$old_tab_name} = $data_hash->{$old_tab_name};
		delete  $data_hash->{$old_tab_name};
	    } else {
		if ( $self->debug >= 3 ) {
		    print STDERR " * * * invalid table name "
			. "\"$old_tab_name\" might cause problems later\n";
		}
	    }
	    $unresolve_cnt++;
	    next;
	}

	# convert to upper case for RCM queries
	my $new_tab_name = uc($old_tab_name);

	# distinguish between RCM and nonRCM tables
	if ( $new_tab_name =~ /(?<!RCM)\./ ) { 
	    # nonRCM
	    $query = "select table_name from rcmadm.rcm_tables " .
		"where table_name = '$new_tab_name'";
	} else {
	    # RCM
	    my $second_try;
	    if ( $new_tab_name =~ /\./ ) {
		($second_try = $new_tab_name) =~ s/^RCM\.//;
	    } else {
		$second_try = "RCM." . $new_tab_name;
	    }
	    $query = "select table_name from rcmadm.rcm_tables " .
		"where table_name = '$new_tab_name'
                 union 
                 select table_name from rcmadm.rcm_tables 
                 where table_name = '$second_try'";
	}
	($status, $message) = $self->{SUSI}->query($query);
	  Carp::croak("Error reading from RCM -- $msg\nLast action " . 
		      "-- $query\n") 
	      if ($status != 1403 && $status > 0);
	chomp ($message);

	if ($message eq "") {
	    # no table_found
	    print STDERR "\n### ERROR: unknown table name:\n";
	    print STDERR "### $old_tab_name\n";

	    if ( $remove_unresolved ) {
		if ( $self->debug >= 3 ) {
		    print STDERR " * * * discarding table data of "
			. "\"$old_tab_name\"\n";
		}
		# TODO perhaps the following should be improved
		# we expect here that $self->{BAD_TABLE_DATA}->{$old_tab_name}
		# doesn't exists
		# move data: $self->{TABLE_DATA}->{$old_tab_name} ->
		# $self->{BAD_TABLE_DATA}->{$old_tab_name}
		$error_hash->{$old_tab_name} = $data_hash->{$old_tab_name};
		delete  $data_hash->{$old_tab_name};
	    } else {
		if ( $self->debug >= 3 ) {
		    print STDERR " * * * unknown table name "
			. "\"$old_tab_name\" might cause problems later\n";
		}
	    }
	    $unresolve_cnt++;
	} else {
	    $new_tab_name = lc($message);
	    if ( $new_tab_name ne $old_tab_name )
	    {
		# rename table / append to table
		if ( $self->debug >= 3 ) {
		    print STDERR " * * * renaming table \"$old_tab_name\""
			. " to \"$new_tab_name\"\n";
		}
		if (exists $data_hash->{$new_tab_name} ) {
		    # append
		    if ( $self->debug >= 4 ) {
			print STDERR "\t\tappending data\n";
		    }
		    push (@{$data_hash->{$new_tab_name}}, 
			  @{$data_hash->{$old_tab_name}});
		    delete  $data_hash->{$old_tab_name};
		    $append_cnt++;
		} else {
		    # just move 
		    if ( $self->debug >= 4 ) {
			print STDERR "\t\tmoving data\n";
		    }
		    $data_hash->{$new_tab_name} = $data_hash->{$old_tab_name};
		    delete  $data_hash->{$old_tab_name};
		    $rename_cnt++;
		}
	    }
	}
    }
    
    $self->{STATUS}->{norm_tab_names_done} = 1;
    $self->{STATUS}->{norm_tab_names_remove_unknown} = $remove_unresolved;

    $result = $rename_cnt . "/" . $append_cnt . "/" . $unresolve_cnt;
    wantarray ? split '/', $result : $result;

} # sub normalize_table_names
# ------------------------------------------------------------------------- #

# ------------------------------------------------------------------------- #
# SUB list_one_column
# ------------------------------------------------------------------------- #

=head2 list_one_column ($table, $column)

mandatory arguments: $table, $column

optional arguments: 

sample call: @list = $client->list_one_column (service_plus, service_id)

Using list_one_column you can access all distinct values of a certain column of already retrieved table data. The result will be a list containing all values. This feature is useful if you are going to data that depends on data read before.

=cut

# SUB list_one_column
# ------------------------------------------------------------------------- #
# if somethings goes wrong (missing argument, $column not defined for $table
# ...) the result will be undef or an empty list
# ------------------------------------------------------------------------- #
sub list_one_column {
    my $self = shift;
    my $table = shift;
    my $column = shift;

    my @result = ();
    my %data;

    return unless $table;
    return unless $column;

    foreach my $line (@{$self->{TABLE_DATA}->{$table}}) {
	%data = _split_line_order_cvcv ($line);
	#print STDERR "LINE: $line\n";
	#print STDERR "DATA:\n";
	#foreach (keys %data) {
	#    print STDERR " $_ = $data{$_}\n";
	#}
	push (@result, $data{$column});
    }

    # remove duplicates:
    %data = ();
    foreach (@result) {
	$data{$_} = "";
    }
    @result = keys %data;
    #print STDERR "RESULT: @result\n";

    wantarray ? @result : join (' ', @result);

} # sub list_one_column
# ------------------------------------------------------------------------- #

# ------------------------------------------------------------------------- #
# SUB dump_table
# ------------------------------------------------------------------------- #

=head2 dump_table ($table, $column)

mandatory arguments: $table

optional arguments: 

sample call: $array_ref = $client->dump_table ('service_plus')

Using dump_table you will get the contents of a table buffer as array of hashes. Each array element represents one data row and is a hash ref using the column names as keys.

=cut

# SUB dump_table
# ------------------------------------------------------------------------- #
sub dump_table {
    my $self = shift;
    my $table = shift;

    my @result = ();

    return unless $table;
    foreach my $line (@{$self->{TABLE_DATA}->{$table}}) {
	my %data = _split_line_order_cvcv ($line);
	push (@result, \%data);
    }
    return \@result;
} # sub dump_table
# ------------------------------------------------------------------------- #

=head1 OBJECT STRUCTURE

=over 4

=item $self->{SUSI}

=item $self->{TABLE_DATA}

is the objects main data hash. The key of an entry is the table name 
and its value is a list containing the data belonging to that table.
Each line of such a list contains stores <column>="<value>" pairs
using the "plain" format but without the leading <table_name><separator>
part.

filled by

    collect_table_data
    read_table_data

modified by

    sort_columns
    fillup_and_sort_columns
    check_and_sort_columns

emptied by

    remove_table_data
    build_and_execute_commands
    check_and_sort_columns
    normalize_table_names

read by

    print_table_data
    print_unused_table_data
    build_commands

=item $self->{BAD_TABLE_DATA}

is initially empty. Is needed data is stored withing that hash
using the same conventions as for $self->{TABLE_DATA}.

filled by

    build_and_execute_commands
    check_and_sort_columns
    normalize_table_names

read by

    print_bad_table_data

emptied by

    remove_bad_table_data

=item $self->{TABLE_PROCS}

filled by

    get_procedures

read by

    build_commands
    build_and_execute_commands

=item $self->{PARAMS}

=item $self->{STATUS}

=back

=cut

=head1 UNDERSTANDING COLUMN SORT

The are serveral public/private methods sorting table data by
comparing the column names within the data with column names
of a list, called @field_pattern, which is constructed appropriate
by the package itself.

Besides some magic behaviour column sort depends on the following
parameters:

=over 4

=item $mode

=item $add_missing_values

=item $exact_matching

=back

Usually $mode is the objects main working mode set at the objects
creation time or via $client->mode($mode). $mode influences the
column list @field_pattern which is the basis for sorting data
for each table. If $mode equals "select" then @field_pattern
will be simple a list of all columns of the corresponding database
table. In all other cases we first look at RCMADM.RCM_TABLES for 
a insert/update/delete procedure for the table. If a corresponding
procedure exists @field_pattern will be set to the argument list
of that procedure. Otherwise @field_pattern is constructed using
the column list of the table as explained below.

Say $line contains a data record (sequence of <column>="<value>"
pairs) belonging to table $table. @field_pattern is the corresponding
column order which is to achieve. Then, in principle, the sorting
works as follows: we loop over @field_pattern and search for the
current field in $line. If it is present the corresponding
<column>="<value>" pair is appended to the sort result. Otherwise
if $exact_matching is off (=0) we look for a column name which
is almost equal to the field we work on. (See below to understand
what is meant with "almost equal".) If that fails or if $exact_matching
is on (=1) the current field is not part of $line. If $add_missing_values
is off (=0) we skip to the next field name of @field_pattern. If
$add_missing_values is on (=1) we add an empty value for that field
to the result (<field>="").

If $line contains columns which do not occur in @field_pattern
the correspondinng <column>="<value>" pairs will not occur
in the sort result.

Most of the insert/update/delete procedures possess an argument
"exec_mode". For that argument a special behaviour is implemented:
If $add_missing_values or $exact_matching is on the pair
<column>="<value>" pair
exec_mode="$self->{PARAMS}->{exec_mode}" is added to the sort result.

If $line contains a column name twice or more the last value will
overrule all values found previously. This behaviour takes place
before the sort against @field_pattern will start.

=over 4

=item $mode = "select"

@field_pattern is always the list of columns of $table.

If $exact_matching is off and we look for <column> we use
as search patterns (within $line) <column>, new_<column>, and 
old_<column> in that order. E.g. we try to find the column value 
pair for column 'ip_address' then we look for 'ip_address' within 
$line. If that fails we look for 'new_ip_address' and as last try
for 'old_ip_address'. If one if these tries succeeds the result
will be stored as 'ip_address="<value>"' where <value> comes from
the column value pair found within $line.

=item $mode = "insert"

If RCMADM.RCM_TABLES.INS_PROC contains a procedure name for $table
@field_pattern is the argument list of that procedure. Otherwise
we take the column list of $table and prepend the column name
with 'new_', e.g. the column name 'ip_address' will be translated
into 'new_ip_address'.

If $exact_matching is off and we look for new_<column> we use
as search patterns (within $line) new_<column>, <column>, and 
old_<column> in that order.

=item $mode = "update"

If RCMADM.RCM_TABLES.UPD_PROC contains a procedure name for $table
@field_pattern is the argument list of that procedure. Otherwise
@field_pattern is the column list of $table each column name
with prefix 'new_' followd by the list of columns forming
the primary key of $table each with prefix 'old_'.

If $exact_matching is off and we look for new_<column> we use
as search patterns (within $line) new_<column>, <column>, and 
old_<column> in that order. If we look for old_<column> the
search order is old_<column>, <column>, and new_<column>.

=item $mode = "delete"

If RCMADM.RCM_TABLES.DEL_PROC contains a procedure name for $table
@field_pattern is the argument list of that procedure. Otherwise
we take a list of the columns of $table forming the primary key
and prepend each column name with 'old_'.

If $exact_matching is off and we look for old_<column> we use
as search patterns (within $line) old_<column>, <column>, and 
new_<column> in that order.

=back
 
There are several public methods which are based on the internal
sorting algorithms. They mainly differ w.r.t to the settings
of $add_missing_values and $exact_matching:

=over 4

=item sort_columns

    $add_missing_columns = 0
    $exact_matching = 0

=item check_and_sort_columns

    $add_missing_columns = 0
    $exact_matching = 1

If check_and_sort_columns finds data records not having all
columns requested by @field_pattern those data records are moved
from the internal data hash to the error data hash. 

=item fillup_and_sort_columns

    $add_missing_columns = 1
    $exact_matching = 0

=back

=cut

# ---- private methods --------------------------------------------------

=head1 PRIVATE METHODS

Some of the private methods have names following a special naming convention.
Note that some methods rely on these conventions.

=over 4

=item naming convention for conversion methods

    _<format>_2_internal (...)

    _internal_2_<format> (...)

=item naming convention for private methods used for column sort

    _prepare_<mode>_columns (...)

=back

=cut

# ------------------------------------------------------------------------- #
# SUB _sort_columns
# ------------------------------------------------------------------------- #

=head2 _sort_columns ($mode [, $add_missing_columns])

=cut

# SUB _sort_columns
# ------------------------------------------------------------------------- #
#
#  asks _get_column_list() for an order to achieve
#  goal: prepare internal data for file output using the results of
#       _get_column_list()
#  algorithm: columns not yielded by _get_column_list() will be ignored
#             columns requested by  _get_column_list() but not present
#             will be ignored if $add_missing_columns = 0 or will be
#             added with value "" if $add_missing_columns = 1, respectively
#
sub _sort_columns {  
    my $self = shift;
    my $data_hash = $self->{TABLE_DATA}; # since we are not going to sort
                                         # $self->{BAD_TABLE_DATA} we do
                                         # not need $data_hash from the
                                         # parameter list
    my $mode = shift; # is a mandatory parameter here!
    my $add_missing_columns = shift || 0; # 
    my $exact_matching = shift || 0;
    my ($status, $msg);
    my ($line,$table,@field_pattern,$sort_proc);

    # TODO the question is: is a column sort desired for "select" mode?
    $sort_proc = "_prepare_" . $mode . "_columns";

    foreach $table (keys %{$data_hash}) {
	if ( $self->debug >= 3 ) {
	    print STDERR " * * * sorting columns of table \"" . $table .
		"\" for \"" . $mode . "\"\n";
	}
	# build column list 
	@field_pattern = $self->_get_column_list ($table, $mode);

	# use column spec to sort table data
	for (my $i = 0; $i <= $#{$data_hash->{$table}}; $i++ ) {
	    ${$data_hash->{$table}}[$i] = 
	    $self->$sort_proc (${$data_hash->{$table}}[$i], 
		$add_missing_columns, $exact_matching, @field_pattern);
	}
    }
    # set status
    $self->{STATUS}->{column_sort_done} = 1;
    $self->{STATUS}->{column_sort_mode} = $mode;
    $self->{STATUS}->{column_sort_add_values} = $add_missing_columns;
    $self->{STATUS}->{column_sort_exact_match} = $exact_matching;

}
# ------------------------------------------------------------------------- #

# ------------------------------------------------------------------------- #
# SUB _sort_columns_with_check
# ------------------------------------------------------------------------- #

=head2 _sort_columns_with_check ($mode [, $add_missing_columns])

=cut

# SUB _sort_columns_with_check
# ------------------------------------------------------------------------- #
sub _sort_columns_with_check {  
    my $self = shift;
    my $mode = shift; # is a mandatory parameter here!
    my $add_missing_columns = shift || 0; # it is not advised to use
                            # the "add missing column" value when you
                            # want to make a real check, but you can.
    my $exact_matching = 1; # check makes sense only in conjunction with
                            # exact matching

    my $data_hash = $self->{TABLE_DATA};
    my $error_hash = $self->{BAD_TABLE_DATA};
    my $error_cnt = 0;
    
    my ($status, $msg);
    my ($table,@field_pattern,$sort_proc);

    # TODO the question is: is a column sort desired for "select" mode?
    $sort_proc = "_prepare_" . $mode . "_columns";

    foreach $table (keys %{$data_hash}) {
	if ( $self->debug >= 3 ) {
	    print STDERR " * * * sorting and check columns of table \"" 
		. $table . "\" for \"" . $mode . "\"\n";
	}
	# build column list 
	@field_pattern = $self->_get_column_list ($table, $mode);

	# use column spec to sort table data
	my $line_count = $#{$data_hash->{$table}};
	for (my $i = 0; $i <= $line_count; $i++ ) {
	    my $line = shift @{$data_hash->{$table}};
	    if ( $self->debug >= 4 ) {
		print STDERR " * * * * record: $line\n"; 
	    }

	    my $new_line = $self->$sort_proc ($line, $add_missing_columns, 
					      $exact_matching, @field_pattern);

	    # check whether $sort_proc was successful:
	    # the number of <column>="<value>" pairs in $line must
	    # match the number of fields in @field_pattern
	    my @temp = _split_line_order_ccvv ($new_line);
	    if ( (2 * @field_pattern) != @temp ) {
		# move original data to $self->{BAD_TABLE_DATA}
		$error_hash->{$table} = [] 
		    if (! defined $error_hash->{$table} );
		push (@{$error_hash->{$table}}, $line);	
		$error_cnt++;

	    } else { # push sorted data back to data hash
		push (@{$data_hash->{$table}}, $new_line );
	    }
	}
	# if $data_hash->{$table} is now an empty list remove it
	# from the data hash
	delete $data_hash->{$table} if ( $#{$data_hash->{$table}} < 0);
    }
    # set status
    $self->{STATUS}->{column_sort_done} = 1;
    $self->{STATUS}->{column_sort_mode} = $mode;
    $self->{STATUS}->{column_sort_add_values} = $add_missing_columns;
    $self->{STATUS}->{column_sort_exact_match} = $exact_matching;

    return $error_cnt;
}
# ------------------------------------------------------------------------- #

# ------------------------------------------------------------------------- #
# SUB _prepare_select_columns
# ------------------------------------------------------------------------- #

=head2 _prepare_select_column ($line_to_sort, $add_missing_columns, $exact_matching, @field_pattern)

=cut

# SUB _prepare_select_columns
# ------------------------------------------------------------------------- #
# $line (plain format) is scanned for <column>="<value>" pairs
# the ordering of the result is determined by @field_pattern (which is
# nothing but a column list)
# the treatment of missing data depends on $add_missing _columns
sub _prepare_select_columns {
    my $self = shift;
    my $line = shift;        # contains line to sort
    my $add_missing_columns = shift; 
          # 0: take just the data which is present 
          # 1: if a colum/value pair is missing generate
          #    a pair with value=""
    my $exact_matching = shift;
          # 0: intelligent mode on to find mathing column names
          # 1: column name must match exactly
    my @field_pattern = @_;  # contains order of fields for output
                             # (it is possible to use this sub
                             #  to select a subset of fields)
    my @sorted_fields = ();  # to mark fields found
                             # useful if field from @field_pattern are 
                             # missing in @data
    my @sorted_values = ();

    # make a hash with column_names as keys
    # if a column occurs more than once the last value wins!
    my %data = _split_line_order_cvcv ($line);

    foreach $field (@field_pattern) {
#	if ($self->debug >= 4) {
#	    print STDERR " * * * * look for field: $field (1st try)\n";
#	}
	# 1st try: look for column with the same name
	if ( defined $data{$field} ) {
	    push (@sorted_values, $data{$field});
	    push (@sorted_fields, $field);
	} elsif (! $exact_matching) {
#	    if ($self->debug >= 4) {
#		print STDERR " * * * * look for field: $field "
#		    . "mode: $mode (2nd and 3rd try)\n";
#	    }
	    # 2nd try: convert "new_<column>" to "<column>"
	    if ( defined $data{"new_" . $field} ) {
		push (@sorted_values, $data{"new_" . $field});
		push (@sorted_fields, $field);
	    # 3rd try: convert "old_<column>" to "<column>"
	    } elsif ( defined $data{"old_" . $field} ) {
		push (@sorted_values, $data{"old_" . $field});
		push (@sorted_fields, $field);
	    # 4th try: add column with empty value
	    } elsif ($add_missing_columns ) {
		push (@sorted_values, "");
		push (@sorted_fields, $field);
	    }
        # add column with empty value if $exact_matching is active
	} elsif ($add_missing_columns ) {
	    push (@sorted_values, "");
	    push (@sorted_fields, $field);
	}
	    
    }
    
    return _compose_line_order_ccvv (@sorted_fields, @sorted_values);
} # sub _prepare_select_columns 

# ------------------------------------------------------------------------- #
# SUB _prepare_insert_columns
# ------------------------------------------------------------------------- #

=head2 _insert_select_column ($line_to_sort, $add_missing_columns, $exact_matching, @field_pattern)

=cut

# SUB _prepare_insert_columns
# ------------------------------------------------------------------------- #
#
# $line (plain format) is scanned for <column>="<value>" pairs
# the ordering of the result is determined by @field_pattern (which is
# nothing but a column list)
# the treatment of missing data depends on $add_missing _columns
sub _prepare_insert_columns {
    my $self = shift;
    my $line = shift;        # contains line to sort
    my $add_missing_columns = shift; 
          # 0: take just the data which is present 
          # 1: if a colum/value pair is missing generate
          #    a pair with value=""
    my $exact_matching = shift;
          # 0: intelligent mode on to find mathing column names
          # 1: column name must match exactly
    my @field_pattern = @_;  # contains order of fields for output
                             # (it is possible to use this sub
                             #  to select a subset of fields)
    my @sorted_fields = ();  # to mark fields found
                             # useful if field from @field_pattern are 
                             # missing in @data
    my @sorted_values = ();

    # make a hash with column_names as keys
    # if a column occurs more than once the last value wins!
    my %data = _split_line_order_cvcv ($line);

    foreach $field (@field_pattern) {
#	if ($self->debug >= 4) {
#	    print STDERR " * * * * look for field: $field (1st try)\n";
#	}
	# magic behaviour for column "execmode"
	if ( $field eq "execmode" ) {
	    if ($add_missing_columns || $exact_matching) {
		push (@sorted_values, $self->exec_mode);
		push (@sorted_fields, $field);
	    } else {
		next;
	    }
	# magic behaviour for column "scope"
	} elsif ( $field eq "scope" ) {
	    # ...just add the line: scope = ""
	    push (@sorted_values, "");
	    push (@sorted_fields, $field);
	# 1st try: look for column with the same name
	} elsif ( defined $data{$field} ) {
	    push (@sorted_values, $data{$field});
	    push (@sorted_fields, $field);
	} elsif (! $exact_matching) {
	    # 2nd try & 3rd try
	    # if $add_missing_columns = 1 the 4th try (as a final resort)
	    # consists of inserting a blank value 
	    my $temp_field = $field;
	    $temp_field =~ s/^new_//; 
	    # TODO if that fails we can complain that @field_pattern
	    # is wrong!
#	    if ($self->debug >= 4) {
#		print STDERR " * * * * look for field: $field "
#		    . "mode: $mode (2nd and 3rd try)\n";
#	    }
	    # 2nd try: convert "<column>" to "new_<column>"
	    if ( defined $data{$temp_field} ) {
		push (@sorted_values, $data{$temp_field});
		push (@sorted_fields, $field);
	    # 3rd try: convert "old_<column>" to "new_<column>"
	    } elsif ( defined $data{"old_" . $temp_field} ) {
		push (@sorted_values, $data{"old_" . $temp_field});
		push (@sorted_fields, $field);
	    # 4th try: add column with empty value
	    } elsif ($add_missing_columns ) {
		push (@sorted_values, "");
		push (@sorted_fields, $field);
	    }
        # add column with empty value if $exact_matching is active
	} elsif ($add_missing_columns ) {
	    push (@sorted_values, "");
	    push (@sorted_fields, $field);
	}
	    
    }
    
    return _compose_line_order_ccvv (@sorted_fields, @sorted_values);
} # sub _prepare_insert_columns 

# ------------------------------------------------------------------------- #
# SUB _prepare_update_columns
# ------------------------------------------------------------------------- #

=head2 _prepare_update_column ($line_to_sort, $add_missing_columns, $exact_matching, @field_pattern)

=cut

# SUB _prepare_update_columns
# ------------------------------------------------------------------------- #
#
# $line (plain format) is scanned for <column>="<value>" pairs
# the ordering of the result is determined by @field_pattern (which is
# nothing but a column list)
# the treatment of missing data depends on $add_missing _columns
sub _prepare_update_columns {
    my $self = shift;
    my $line = shift;        # contains line to sort
    my $add_missing_columns = shift; 
          # 0: take just the data which is present 
          # 1: if a colum/value pair is missing generate
          #    a pair with value=""
    my $exact_matching = shift;
          # 0: intelligent mode on to find mathing column names
          # 1: column name must match exactly
    my @field_pattern = @_;  # contains order of fields for output
                             # (it is possible to use this sub
                             #  to select a subset of fields)
    my @sorted_fields = ();  # to mark fields found
                             # useful if field from @field_pattern are 
                             # missing in @data
    my @sorted_values = ();

    # make a hash with column_names as keys
    # if a column occurs more than once the last value wins!
    my %data = _split_line_order_cvcv ($line);

    foreach $field (@field_pattern) {
	if ($self->debug >= 4) {
	    print STDERR " * * * * field: $field\n";
	}
	# magic behaviour for column "execmode"
	if ( $field eq "execmode" ) {
	    if ($add_missing_columns || $exact_matching) {
		push (@sorted_values, $self->exec_mode);
		push (@sorted_fields, $field);
	    } else {
		next;
	    }
	# magic behaviour for column "scope"
	} elsif ( $field eq "scope" ) {
	    # ...just add the line: scope = ""
	    push (@sorted_values, "");
	    push (@sorted_fields, $field);
	# 1st try: look for column with the same name
	} elsif ( defined $data{$field} ) {
	    push (@sorted_values, $data{$field});
	    push (@sorted_fields, $field);
	} elsif (! $exact_matching) {
	    my $temp_field = $field;
	    my $temp_prefix = "";
	    if ($field =~ /^new_/) {
		$temp_field =~ s/^new_//;
		$temp_prefix = "old_";
	    } elsif ($field =~ /^old_/) {
		$temp_field =~ s/^old_//;
		$temp_prefix = "new_";
	    }
	    #else {
	    # TODO if we arrive here we can complain that @field_pattern
	    # is wrong!		  
	    #}
#	    if ($self->debug >= 4) {
#		print STDERR " * * * * look for field: $field "
#		    . "mode: $mode (2nd and 3rd try)\n";
#	    }
	    # 2nd try: convert "<column>" to "new/old_<column>"
	    if ( defined $data{$temp_field} ) {
		push (@sorted_values, $data{$temp_field});
		push (@sorted_fields, $field);
	    # 3rd try: convert "old/new_<column>" to "new/old_<column>"
	    } elsif ( defined $data{$temp_prefix . $temp_field} ) {
		push (@sorted_values, $data{$temp_prefix . $temp_field});
		push (@sorted_fields, $field);
	    # 4th try: add column with empty value
	    } elsif ($add_missing_columns ) {
		push (@sorted_values, "");
		push (@sorted_fields, $field);
	    }
        # add column with empty value if $exact_matching is active
	} elsif ($add_missing_columns ) {
	    push (@sorted_values, "");
	    push (@sorted_fields, $field);
	}
    }
    
    return _compose_line_order_ccvv (@sorted_fields, @sorted_values);
} # sub _prepare_update_columns 

# ------------------------------------------------------------------------- #
# SUB _prepare_delete_columns
# ------------------------------------------------------------------------- #

=head2 _prepare_delete_column ($line_to_sort, $add_missing_columns, $exact_matching, @field_pattern)

=cut

# SUB _prepare_delete_columns
# ------------------------------------------------------------------------- #
#
# $line (plain format) is scanned for <column>="<value>" pairs
# the ordering of the result is determined by @field_pattern (which is
# nothing but a column list)
# the treatment of missing data depends on $add_missing _columns
sub _prepare_delete_columns {
    my $self = shift;
    my $line = shift;        # contains line to sort
    my $add_missing_columns = shift; 
          # 0: take just the data which is present 
          # 1: if a colum/value pair is missing generate
          #    a pair with value=""
    my $exact_matching = shift;
          # 0: intelligent mode to find matching column names
          # 1: column name must match exactly
    my @field_pattern = @_;  # contains order of fields for output
                             # (it is possible to use this sub
                             #  to select a subset of fields)
    my @sorted_fields = ();  # to mark fields found
                             # useful if field from @field_pattern are 
                             # missing in @data
    my @sorted_values = ();

    # make a hash with column_names as keys
    # if a column occurs more than once the last value wins!
    my %data = _split_line_order_cvcv ($line);

    foreach $field (@field_pattern) {
#	if ($self->debug >= 4) {
#	    print STDERR " * * * * look for field: $field (1st try)\n";
#	}
	# magic behaviour for column "execmode"
	if ( $field eq "execmode" ) {
# TODO if successful put " || $exact_matching " in all routines
	    if ($add_missing_columns || $exact_matching) {
		push (@sorted_values, $self->exec_mode);
		push (@sorted_fields, $field);
	    } else {
		next;
	    }
	# 1st try: look for column with the same name
	} elsif ( defined $data{$field} ) {
	    push (@sorted_values, $data{$field});
	    push (@sorted_fields, $field);
	} elsif (! $exact_matching) {
	    my $temp_field = $field;
	    $temp_field =~ s/^old_//; 
	    # TODO if that fails we can complain that @field_pattern
	    # is wrong!
#	    if ($self->debug >= 4) {
#		print STDERR " * * * * look for field: $field "
#		    . "mode: $mode (2nd and 3rd try)\n";
#	    }
	    # 2nd try: convert "<column>" to "old_<column>"
	    if ( defined $data{$temp_field} ) {
		push (@sorted_values, $data{$temp_field});
		push (@sorted_fields, $field);
	    # 3rd try: convert "new_<column>" to "old_<column>"
	    } elsif ( defined $data{"new_" . $temp_field} ) {
		push (@sorted_values, $data{"new_" . $temp_field});
		push (@sorted_fields, $field);
	    # 4th try: add column with empty value
	    } elsif ($add_missing_columns ) {
		push (@sorted_values, "");
		push (@sorted_fields, $field);
	    }
        # add column with empty value if $exact_matching is active
	} elsif ($add_missing_columns ) {
	    push (@sorted_values, "");
	    push (@sorted_fields, $field);
	}
	    
    }
    
    return _compose_line_order_ccvv (@sorted_fields, @sorted_values);
} # sub _prepare_delete_columns 

# ------------------------------------------------------------------------- #
# SUB _get_column_list
# ------------------------------------------------------------------------- #

=head2 _get_column_list ($table [, $mode])

=cut

# SUB _get_column_list
# ------------------------------------------------------------------------- #
#  build list of columns in for usage within sort_line_columns() 
#  usually called from _sort_columns()
#                   or _prepare_columns()
#  those two function will modify the results if needed
#
#  usage: _get_column_list (<table_name> [, <mode>])
#  if <mode> is not specified $self->{PARAMS}->{mode} is used
#
# here Susi::Desription is used
# hence most of the stuff will fail if database user is 'rcmview' 
sub _get_column_list {
    my $self = shift;
    my $table = shift;
    my $mode = shift || $self->mode;
    my $procedure = "";
    my @result = ();

  SWITCH: {
      if ($mode eq "select") {
	  @result = $self->get_table_columns ($table);
	  last SWITCH;
      }

# for all other modes: 1st decide whether to use a procedure or not
# then use Susi::Description for table or procedure respectively
# to build column_list

# TODO print some warning message if ($self->{SUSI}->user eq "rcmview")
# because then all the following stuff is bound to fail

      # try to find a procedure for $mode, $table
      $procedure = $self->_get_procedure ($table, $mode);
      # TODO we could replace $self->_get_procedure by
      # $self->{TABLE_PROCS} if we assume that the latter structure
      # has been filled before using the correct $mode setting

      # if a procedure has been found we simply return the argument list
      # for all modes except "select"
      if ( $procedure ne "") {
	  # TODO do some error check here?
	  # for example we could check $desc->type() eq PROCEDURE
	  my $desc = Susi::Description->new($self->{SUSI}, $procedure);
	  @result = $desc->fields();
	  if ($self->debug >= 4) {
	      print STDERR " * * * * building column list using " . 
		  "variables of procedure \"" .
		  $procedure . "\":\n";
#	      foreach (@result) {
#		  print STDERR "\t$_\n";
#	      }
	  }
	  last SWITCH;
      } else {
	  # if no procedure is known we describe the table itself and
	  # generate a column list depending of $mode
	  my $desc = Susi::Description->new($self->{SUSI}, $table);
	  # TODO do some error check here?
	  # for example we could check $desc->type() eq TABLE

	  if ($mode eq "insert") {
	      # return the column list with prefix "new_"
	      @result = map { "new_" . lc($_) } $desc->fields();
	      last SWITCH;
          }
	  if ($mode eq "update") {
	      # add prefix "new_" to elements of column list
	      # append a list of the primary key columns with prefix "old_"
	      @result = $desc->fields();
	      @result = map { "new_" . lc($_) } @result; 
	      push (@result, map { "old_" . lc($_) } $desc->pk_fields());
	      last SWITCH;
	  }
	  if ($mode eq "delete") {
	      # request a list of the primary key columns
	      @result = $desc->pk_fields();
	      @result = map { "old_" . lc($_) } @result; 
	  }
	  

      }

      # TODO cry when arriving here
  }
    if ($self->debug >= 4) {
	print STDERR " * * * * column list for table \"" .
	    $table . "\" for mode \"" . $mode . "\":\n";
	foreach (@result) {
	    print STDERR "\t$_\n";
	}
    }
    return @result;
} # sub _get_column_list

# ------------------------------------------------------------------------- #
# SUB _get_procedure
# ------------------------------------------------------------------------- #

=head2 _get_procedure ($table [, $mode])

=cut

# SUB _get_procedure
# ------------------------------------------------------------------------- #
#  ask RCMADM.RCM_TABLES for insert/update/delete procedure depending on
#  the mode
#  returns the name of the procedure if present or nothing else
#
#  usage: _get_procedure (<table_name> [, <mode>])
#  if <mode> is not specified $self->{PARAMS}->{mode} is used
#
sub _get_procedure {
    my $self = shift;
    my $table = shift;
    my $mode = shift || $self->mode;
    my ($status,$msg,$query);
    my $column_to_use = "";
    my $owner = "";

  SWITCH: {
      if ($mode eq "select") { return ""; last SWITCH;} # nothing to do
      if ($mode eq "insert") {$column_to_use = "ins_proc"; last SWITCH;}
      if ($mode eq "update") {$column_to_use = "upd_proc"; last SWITCH;}
      if ($mode eq "delete") {$column_to_use = "del_proc"; last SWITCH;}
  }

    # try to read procedure from rcm
    $query = "select $column_to_use from rcmadm.rcm_tables " . 
	"where table_name = '" . uc($table) . "'";

    ($status, $msg) = $self->{SUSI}->query($query);
  Carp::croak("Error reading from RCM -- $msg\nLast action -- $query\n") 
      if ($status != 1403 && $status > 0);
	chomp ($msg);
    if ($msg ne "") {
	if ($self->debug >= 4) {
	    print STDERR " * * * * table: \"$table\" mode: \"$mode\" " .
		"procedure: $msg\n" 
	}
	return $msg;
    } else {
	if ($self->debug >= 4) {
	    print STDERR " * * * * table: \"$table\" mode: \"$mode\" " .
		"no procedure found\n" 
	}
    }
    # when arrived here we havn't found something

    # TODO:  we can skip all the following stuff if we are sure
    # that normalize_table_names has been run before arriving here
    #  (one possibility: get_procedures and sort_columns should 
    #   ensure that normalize_table_names has been run)
    if ($table =~ /^\w+\.\w+/ ) {
	# no sound second try available 
	return "";
    }

    # start 2nd try: searching for "RCM.<table>" 
    $query = "select $column_to_use from rcmadm.rcm_tables " . 
	"where table_name = 'RCM." . uc($table) . "'";

    ($status, $msg) = $self->{SUSI}->query($query);
  Carp::croak("Error reading from RCM -- $msg\nLast action -- $query\n") 
      if ($status != 1403 && $status > 0);
    chomp ($msg);
    if ($msg ne "") {
	if ($self->debug >= 4) {
	    print STDERR " * * * * table: \"RCM.$table\" mode: \"$mode\" " .
		"procedure: $msg\n" 
	}
	return $msg;
    } else {
	# give up
	if ($self->debug >= 4) {
	    print STDERR " * * * * table: \"RCM.$table\" mode: \"$mode\" " .
		"no procedure found\n" 
	}
	return ""; 
    }
	
} # sub _get_procedure



# ------------------------------------------------------------------------- #
# SUB _build_command
# ------------------------------------------------------------------------- #

=head2 _build_command ($table, $line [, $mode])

=cut

# SUB _build_command
# ------------------------------------------------------------------------- #
#
# assume $self->{TABLE_PROC} has been filled before using the
# correct $mode setting
# and that _prepare_<mode>_columns had been run for the
# correct $mode
#
# TODO possibly split it into 3 subs for performance reasons
# ------------------------------------------------------------------------- #
# run before:
# get_procedures()
sub _build_command {
    my $self = shift;
    my $table = shift;
    my $line = shift;
    my $mode = shift || $self->mode;
    my $command = "";
    my $procedure;

    return $command if ($mode eq "select");

    # $line could be empty if something has gone wrong earlier
    return $command if ($line eq "");

    my @data = _split_line_order_ccvv ($line);
    my $no_of_cols = ($#data +1 )/2;

    # replace "'" by "''" within data
    for (my $i=$no_of_cols; $i <= $#data; $i++ ) {
	$data[$i] =~ s/'/''/g; #'
    }

    if (($procedure = $self->{TABLE_PROCS}->{$table}) ne "") {
	# build function call
	$command = "begin " . $procedure . "(";
	for (my $i=$no_of_cols; $i <= $#data; $i++ ) {
	    $command .= "'" . $data[$i] . "',";
	}
	$command =~ s/,$/); end;/; 
    } else {
	# build sql command
      SWITCH: {
	  if ($mode eq "insert") {
	      $command = "insert into " . $table . " (";
	      for (my $i=0; $i < $no_of_cols; $i++ ) {
		  $data[$i] =~ /^new_(.*)/; # truncate leading "new_"
		  $command .= $1 . ",";
	      }
	      $command =~ s/,$/) values (/;
	      for (my $i=$no_of_cols; $i <= $#data; $i++ ) {
		  $command .= "'" . $data[$i] . "',";
	      }
	      $command =~ s/,$/)/; # without trailing ';' ! 
	      last SWITCH;
	  }
	  if ($mode eq "update") {
	      $command = "update " . $table . " set";
	      my $i=0;
	      while ($data[$i] !~ /^old_/) {
		  $data[$i] =~ /^new_(.*)/; # truncate leading "new_" 
		  $command .= " " . $1 . "='" . 
		      $data[$i+$no_of_cols] . "',";
		  $i++;
	      }
	      $command =~ s/,$/ where/;
	      while ($i < $no_of_cols) {
		  $data[$i] =~ /^old_(.*)/; # truncate leading "old_" 
		  $command .= " $1='" . $data[$i+$no_of_cols]
		      . "' and";
		   $i++; 
	      }
	      $command =~ s/ and$//; # without trailing ';' ! 
	      last SWITCH;
	  }
	  if ($mode eq "delete") {
	      $command = "delete from " . $table . " where";
	      for (my $i=0; $i < $no_of_cols; $i++ ) {
		  $data[$i] =~ /^old_(.*)/; # truncate leading "old_" 
		  $command .= " $1='" . $data[$i+$no_of_cols]
		      . "' and";
	      }
	      $command =~ s/ and$//; # without trailing ';' ! 
	      last SWITCH;
	  }
      } # SWITCH
    } 

    return $command;

} # sub _build_command 


# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = #
# SUBs to convert betwenn several formats and internal representation
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = #

#
# ------------------------------------------------------------------------- #
# SUB: _internal_2_plain  
# ------------------------------------------------------------------------- #

=head2 _internal_2_plain ($data_hash, $table)

=cut

# SUB: _internal_2_plain  
# ------------------------------------------------------------------------- #
#
# convert _internal representation to "plain" format [write "plain"]
# usage:
#  @out_array = _internal_2_plain ( [<print_just_data_of_that_table_name>])
# or
#  $buffer = _internal_2_plain ([<print_just_data_of_that_table_name>])
#
# ------------------------------------------------------------------------- #
# 
sub _internal_2_plain {
    my $self = shift;
    my $data_hash = shift; 
    my $table = shift;  # optional argument 
    my @out_array = ();
    my @ordered_table_list = ();
    my ($line,$field);

    if (defined $table) {
	@ordered_table_list = ($table);
    } else {
	# TODO table sort makes sense only if $data_hash = $self->{TABLE_DATA}
	if ($self->{PARAMS}->{table_sort}) {
	    # unused entries in %table_hash will not be detected so far!!!
	    @ordered_table_list = $self->get_table_order ();
	} else {
	    @ordered_table_list = sort keys %{$data_hash};
	}
    }
    foreach $table (@ordered_table_list) {
	foreach $line (@{$data_hash->{$table}}) {
	    push (@out_array, $table . $fsep . $line);
	}
    }

    wantarray ? @out_array : join "\n", @out_array;

} # sub _internal_2_plain 

#
# ------------------------------------------------------------------------- #
# SUB: _plain_2_internal
# ------------------------------------------------------------------------- #

=head2 _plain_2_internal (@buffer)

=cut

# SUB: _plain_2_internal
# ------------------------------------------------------------------------- #
#
# convert plain format to internal representation [read "plain"]
# 
# usage:
#  _plain_2_internal (@in_array)
#
# ------------------------------------------------------------------------- #
# 
sub _plain_2_internal {
    my $self = shift;
    my $data_hash = $self->{TABLE_DATA}; # not need to change this via arg
    my @in_array = @_;   # is expected to contain lines without trailing '\n'
    my ($line,$table);

    foreach $line (@in_array) {
	($table) = $line =~ /^(.*?)(?=$fsep)/;
#	($table) = $line =~ /^([^$fsep]*)/;
	$line =~ s/^$table$fsep//;
	$data_hash->{$table} = [] 
	    if (! defined $data_hash->{$table} );
	push (@{$data_hash->{$table}}, $line);	
    }
	    
} # sub _plain_2_internal

#
# ------------------------------------------------------------------------- #
# SUB: _internal_2_stanza  
# ------------------------------------------------------------------------- #

=head2 _internal_2_stanza ($data_hash, $table)

=cut

# SUB: _internal_2_stanza  
# ------------------------------------------------------------------------- #
#
# convert _internal representation to "stanza" format [write "stanza"]
# usage:
#  @out_array = _internal_2_stanza ([<print_just_data_of_that_table_name>])
# or
#  $buffer = _internal_2_stanza ([<print_just_data_of_that_table_name>])
#
# ------------------------------------------------------------------------- #
# 
sub _internal_2_stanza {
    my $self = shift;
    my $data_hash = shift; 
    my $table = shift;   # optional
    my @out_array = ();
    my @ordered_table_list = ();
    my ($line,$field);

    if (defined $table) {
	@ordered_table_list = ($table);
    } else {
	# TODO table sort makes sense only if $data_hash = $self->{TABLE_DATA}
	if ($self->{PARAMS}->{table_sort}) {
	    # unused entries in %table_hash will not be detected so far!!!
	    @ordered_table_list = $self->get_table_order ();
	} else {
	    @ordered_table_list = sort keys %{$data_hash};
	}
    }
    foreach $table (@ordered_table_list) {
	foreach $line (@{$data_hash->{$table}}) {
	    push (@out_array, "");
	    push (@out_array, "$table:");
	    foreach $field (split /$fsep/, $line) {
		$field =~ s/$asgn_char/ = /;
		push (@out_array, "\t$field");
	    }
	}
    }

    wantarray ? @out_array : join "\n", @out_array;

} # sub _internal_2_stanza

#
# ------------------------------------------------------------------------- #
# SUB: _stanza_2_internal
# ------------------------------------------------------------------------- #

=head2 _stanza_2_internal (@buffer)

=cut

# SUB: _stanza_2_internal
# ------------------------------------------------------------------------- #
#
# convert stanza format to internal representation [read "stanza"]
# 
# usage:
#  _stanza_2_internal (@in_array)
#
# ------------------------------------------------------------------------- #
# 
sub _stanza_2_internal {
    my $self = shift;
    my $data_hash = $self->{TABLE_DATA}; # not need to change this via arg
    # "value lines" must have the form:
    #  <field> = <value> 
    # or
    #  <field> = "<value>"
    # white spaces are ignored except between double quotes
    my @in_array = @_;   # is expected to contain lines without trailing '\n'
    my ($line,$table,$field,$value);
    my $new_line = "";
    my ($org_line,$line_no) = ("", 0); # for debugging purposes

    while ( defined ($org_line = $line = shift (@in_array)) ) {
	$line_no++;
	# a better re would be ^([\w\d_]\.)?[\w\d_]+:  since
	# we expect at most one . within the tablename
	if ((my $temp_table) = $line =~ /^([\w\d\._]*):/) {  
            # begin of new stanza found
	    # store parsing result of previous stanza
	    if ($new_line ne "") {
		# if $table is unknown => make new anonymous list
		$data_hash->{$table} = [] 
		    if (! defined $data_hash->{$table} );
		push (@{$data_hash->{$table}}, $new_line);
	    }
	    $table = $temp_table;
	    $new_line = "";
	} elsif ( $line !~ /^\s*$/ ) { # ignore blank lines
            # TODO possibly ignore also lines starting with # to support 
            #      the "still-to-do-files" created by rcm_insert.pl
	    # $line seems to be a "value line"
	    ($field, $value) = ($line =~ /^(.*?)=(.*)$/);
	    $field =~ s/^\s+//; $field =~ s/\s+$//;
	    $value =~ s/^\s+//; $value =~ s/\s+$//;
	    if ($value =~ /^\".*\"$/) {
		$value =~ s/^\"//; $value =~ s/\"$//;
	    }
	    #print STDERR "FIELD=$field VALUE=$value\n";
	    _complain($line_no, $org_line, "<field>=\"<value>\"") 
		unless ( $field );
	    $new_line .= $fsep if ($new_line ne "");
	    $new_line .= $field . $asgn_char. $quote_char . 
		$value . $quote_char;
	}

    }
    # store parsing result of last stanza
    push (@{$data_hash->{$table}}, $new_line) if ($new_line ne "");
	    
} # sub _stanza_2_internal


#
# ------------------------------------------------------------------------- #
# SUB: _internal_2_passwd  
# ------------------------------------------------------------------------- #

=head2 _internal_2_passwd ($data_hash, $table)

=cut

# SUB: _internal_2_passwd  
# ------------------------------------------------------------------------- #
#
# convert _internal representation to "passwd" format [write "passwd"]
# usage:
#  @out_array = _internal_2_passwd ([<print_just_data_of_that_table_name>])
# or
#  $buffer = _internal_2_passwd ([<print_just_data_of_that_table_name>])
#
# used globals: %table_hash, $susi
# ------------------------------------------------------------------------- #
# 
sub _internal_2_passwd {
    my $self = shift;
    my $data_hash = shift; 
    my $table = shift; # optional argument
    my @out_array = ();
    my @ordered_table_list = ();
    my ($line,$field);
    my ($new_line,@data, $no_of_cols);

    if (defined $table) {
	@ordered_table_list = ($table);
    } else {
	# TODO table sort makes sense only if $data_hash = $self->{TABLE_DATA}
	if ($self->{PARAMS}->{table_sort}) {
	    # unused entries in %table_hash will not be detected so far!!!
	    @ordered_table_list = $self->get_table_order ();
	} else {
	    @ordered_table_list = sort keys %{$data_hash};
	}
    }
    foreach $table (@ordered_table_list) {
	# skip when table contains no data 
	# (prevent access to non-existing array)
	next if (! defined ($data_hash->{$table}));
	next unless (@{$data_hash->{$table}});
	push (@out_array, "");
	push (@out_array, "#");
	push (@out_array, "# FORMAT of table $table:");
	push (@out_array, "#");
	push (@out_array, "#");
	# write column spec using the first entry
	$new_line = "";
	@data = _split_line_order_ccvv ($data_hash->{$table}->[0]);
	$no_of_cols = ($#data + 1)/2;
	for (my $i = 0; $i < $no_of_cols; $i++ ) {
	    $new_line .= ":" . $data[$i];
	}
	$new_line =~ s/^://;  # remove leading ':' 
        push (@out_array, "# $new_line");
	push (@out_array, "#");
	my $no_of_recs = scalar(@{$data_hash->{$table}});
	push (@out_array, "## $no_of_recs record". 
	      (($no_of_recs == 1) ? '' : 's'));
        foreach $line (@{$data_hash->{$table}}) {
	    $new_line = "";
	    @data = _split_line_order_ccvv ($line);
	    $no_of_cols = ($#data + 1)/2;
	    for (my $i = 0; $i < $no_of_cols; $i++ ) {
		# do ':' to special character substitution
		$data[$no_of_cols + $i] =~ s/:/$passwd_replace_colon/eg;
		$new_line .= ":" . $data[$no_of_cols + $i];
	    }
	    $new_line =~ s/^://;  # remove leading ':' 
	    push (@out_array, "$new_line");
	}
	push (@out_array, "");   
	push (@out_array, "# ----------------------------------------" . 
	      "----------------------------------- #");   
	push (@out_array, "");   
    }

    wantarray ? @out_array : join "\n", @out_array;

} # sub _internal_2_passwd

#
# ------------------------------------------------------------------------- #
# SUB: _passwd_2_internal
# ------------------------------------------------------------------------- #

=head2 _passwd_2_internal (@buffer)

=cut

# SUB: _passwd_2_internal
# ------------------------------------------------------------------------- #
#
# convert old h2p ascii format to internal representation [read "passwd"]
# usage:
#  _passwd_2_internal (@in_array)
#
# used globals: %table_hash
# ------------------------------------------------------------------------- #
#
sub _passwd_2_internal {
    my $self = shift;
    my $data_hash = $self->{TABLE_DATA}; # not need to change this via arg
    my @in_array = @_;   # is expected to contain lines without trailing '\n'
    my ($line,$table,$field,$value);
    my @fields = ();     # empty list be default
    my @values;

    my $new_line = "";
    my ($org_line,$line_no) = ("", 0); # for debugging purposes

    while ( defined ($org_line = $line = shift (@in_array)) ) 
    {
      $line_no++;
      if ( $line =~ /^(?:#\s*|\s*)$/ ) { # empty line or empty comment line
	   ; # skip to next line
      } elsif ( $line =~ /^#\s*-*\s*#\s*$/ ) { # separater line
	   ; # skip to next line
      } elsif ( $line =~ /^##/ ) { # lines starting with two # are ignored completely
	   ; # skip to next line
      } elsif ( $line  =~ /^#\s+FORMAT\s+of\s+table\s+([\w\.]+):/ ) 
# $line  =~ /^#\s+FORMAT\s+of\s+table\s+([^\s:]+):/ old pattern
      {  # new FORMAT begin found 
	  $table = $1;
	  # if $table is unknown => make new anonymous list
	  $data_hash->{$table} = [] 
	      if (! defined $data_hash->{$table} );
	  @fields = ();                # empty column specification
      } elsif ( $line =~ /^#/ ) {      # this match should contain 
                                       #   the column specification
	  if (@fields) {               # no FORMAT line was found before
	      _complain ($line_no, $org_line, "# FORMAT of table <table_name>:");
	  } else {
	      $line  =~ s/^#\s*//;
	      @fields = split (':',$line);
	      _complain ($line_no, $org_line, "# <col1>:<col2>:...") if (! @fields);
	  }
      } else {                         # this must be a data line!
	  if (!@fields) {              # no column specification
	      _complain ($line_no, $org_line, "# <col1>:<col2>:...");
	  } else {                     # read data 
	      # the third argument of 'split' ignores superflous fields
	      # at and of line
	      @values = split /:/,$line, $#fields +1 ;
	      # but if there are too less fields we complain.
	      if ($#values != $#fields) {
		  my $msg = "Line $line_no contains too less data fields ($#values got, $#fields expected)";
		  Carp::croak $msg;
	      }
	      # do special character to ':' substitution
	      foreach (@values) {
		  s/$passwd_replace_colon/:/g;
	      }
	      $new_line = 
		  _compose_line_order_ccvv (@fields, @values);
	      # store parsing result
	      push (@{$data_hash->{$table}}, $new_line);
	  }
      }
    } # while;

} # sub _passwd_2_internal

#
# ------------------------------------------------------------------------- #
# SUB: _internal_2_xml
# ------------------------------------------------------------------------- #

=head2 _internal_2_xml ($data_hash, $table)

=cut

# SUB: _internal_2_xml
# ------------------------------------------------------------------------- #
#
# convert _internal representation to "xml" format [write "xml"]
# usage:
#  @out_array = _internal_2_xml ([<print_just_data_of_that_table_name>])
# or
#  $buffer = _internal_2_xml ([<print_just_data_of_that_table_name>])
#
# used globals: %table_hash, $susi
# ------------------------------------------------------------------------- #
#
sub _internal_2_xml {
    my $self = shift;
    my $data_hash = shift; 
    my $table = shift;  # optional argument

    my $buffer;
    my @ordered_table_list = ();
    if (defined $table) {
	@ordered_table_list = ($table);
    } else {
	# TODO table sort makes sense only if $data_hash = $self->{TABLE_DATA}
	if ($self->{PARAMS}->{table_sort}) {
	    # unused entries in %table_hash will not be detected so far!!!
	    @ordered_table_list = $self->get_table_order ();
	} else {
	    @ordered_table_list = sort keys %{$data_hash};
	}
    }

    # short cut:
    # if there is no data at all for the requested tables we return
    # an empty string instead of an empty XML structure (<rcm_data></rcm_data>)
    # (this ensures correcte behaviour if _internal_2_xml is called
    # via print_unused_table_data
    my $data_there = 0;
    foreach $table (@ordered_table_list) {
	if (@{$data_hash->{$table}}) {
	    $data_there = 1;
	    last;
	}
    }
    return unless $data_there;

    eval ("use XML::Writer; 1;") or die "can't load XML::Writer (not installed?)";
    my $writer = XML::Writer->new(OUTPUT => \$buffer,
				  DATA_MODE => 1,
				  DATA_INDENT => 2,
				  ENCODING => 'utf-8',
				 );
    # we need to define some master element
    $writer->startTag('rcm_data');
    foreach $table (@ordered_table_list) {
	foreach $line (@{$data_hash->{$table}}) {
	    $writer->startTag('table', 'name' => $table);
	    my %data = _split_line_order_cvcv ($line);
	    foreach my $col (keys %data) {
		$writer->startTag('field', 'name' => $col);
		# write content as CDATA section or not?
		if ($xml_use_cdata) {
		    $writer->cdata($data{$col});
		} else {
		    my $string = $data{$col};
		    # replacing '<', '>' not needed
		    #$string =~ s/</$xml_replace_lt/g;
		    #$string =~ s/>/$xml_replace_gt/g;
		    $writer->characters($string);
		}
		$writer->endTag('field');
	    }
	    $writer->endTag('table');
	}
    }
    $writer->endTag('rcm_data');
    $writer->end();

    wantarray ? split "\n", $buffer : $buffer;
}

#
# ------------------------------------------------------------------------- #
# SUB: _xml_2_internal
# ------------------------------------------------------------------------- #

=head2 _xml_2_internal (@buffer)

=cut

# SUB: _xml_2_internal
# ------------------------------------------------------------------------- #
#
# convert XML data to internal representation [read "xml"]
# usage:
#  _xml_2_internal (@in_array)
#
# used globals: %table_hash
# ------------------------------------------------------------------------- #
#
sub _xml_2_internal {
    my $self = shift;
    my $data_hash = $self->{TABLE_DATA}; # no need to change this via arg


    eval ("use XML::DOM; 1;") or die "can't load XML::DOM (not installed?)";

    # Problem: XML::DOM can only parse file
    # but in this context we get the file already as array of lines
    # nasty workaround: write data back to file :-(((
    # before processing. buh!
    my $tmp_file = "/tmp/".File::Basename::basename($0).".$$";
    open(TMP, ">", $tmp_file) or die "can't write temporary file $tmp_file: $@";
    foreach (@_) { print TMP $_, "\n"; }
    close(TMP);

    my $parser = XML::DOM::Parser->new;
    my $doc = $parser->parsefile ($tmp_file);
    foreach my $tnode ($doc->getElementsByTagName('table')) {
	my $tattrMap = $tnode->getAttributes; # XML::DOM::NamedNodeMap
	my $tnameAttr = $tattrMap->getNamedItem('name'); # XML::DOM::Attr
	if ($tnameAttr) {
	    my $table = $tnameAttr->getValue;
	    if ($table) {
		$data_hash->{$table} = [] 
		    if (! defined $data_hash->{$table} );
		my $new_line = '';
		foreach my $cnode ($tnode->getElementsByTagName('field')) {
		    my $cattrMap = $cnode->getAttributes; # XML::DOM::NamedNodeMap
		    my $cnameAttr = $cattrMap->getNamedItem('name'); # XML::DOM::Attr

		    if ($cnameAttr) {
			my $column = $cnameAttr->getValue;
			if ($column) {
			    # try to get data
			    my $data_node = $cnode->getFirstChild;
			    if (defined $data_node) {
				my $dnode_type = $data_node->getNodeName;
				my $data;
				if ($dnode_type eq '#cdata-section') {
				    # $data_node if of type XML::DOM::CDATASection
				    $data = $data_node->getData;
				} elsif ($dnode_type eq '#text') {
				    # $data_node if of type XML::DOM::Text
				    $data = $data_node->getData;
				    # special character translation not needed
				    #$data =~ s/$xml_replace_gt/>/g;
				    #$data =~ s/$xml_replace_lt/</g;
				} else {
				    Carp::croak("Unexcepted child element of type \"$dnode_type\" encountered within \"field\" element of XML data");
				}
				$new_line .= $fsep if ($new_line ne '');
				$new_line .= $column . $asgn_char. $quote_char . 
				  $data . $quote_char;
			    } else {
				# complain loudly
			    }
			} else {
			    Carp::croak("Found \"field\" element in XML data with empty \"name\" attribute.");
			}
		    } else {
			Carp::croak("Found \"field\" element in XML data without \"name\" attribute.");		    }
		}
		push (@{$data_hash->{$table}}, $new_line);
	    } else {
		Carp::croak("Found \"table\" element in XML data with empty \"name\" attribute.");
	    }
	} else {
	   Carp::croak("Found \"table\" element in XML data without \"name\" attribute.");
       }
    }

    $doc->dispose;
    unlink $tmp_file;
}

#
# ------------------------------------------------------------------------- #
# SUB: _internal_2_html  
# ------------------------------------------------------------------------- #

=head2 _internal_2_html ($data_hash, $table)

=cut

# SUB: _internal_2_html  
# ------------------------------------------------------------------------- #
#
# convert _internal representation to "html" format [write "html"]
# usage:
#  @out_array = _internal_2_html ([<print_just_data_of_that_table_name>])
# or
#  $buffer = _internal_2_html ([<print_just_data_of_that_table_name>])
#
# used globals: %table_hash, $susi
# ------------------------------------------------------------------------- #
# 
sub _internal_2_html {
    my $self = shift;
    my $data_hash = shift; 
    my $table = shift;  # optional argument
    my @out_array = ();
    my @ordered_table_list = ();
    my ($line,$field);
    my ($new_line,@data, $no_of_cols);

    if (defined $table) {
	@ordered_table_list = ($table);
    } else {
	# TODO table sort makes sense only if $data_hash = $self->{TABLE_DATA}
	if ($self->{PARAMS}->{table_sort}) {
	    # unused entries in %table_hash will not be detected so far!!!
	    @ordered_table_list = $self->get_table_order ();
	} else {
	    @ordered_table_list = sort keys %{$data_hash};
	}
    }
    push (@out_array, "<html>");
    push (@out_array, "<body>");
    foreach $table (@ordered_table_list) {
	# skip when table contains no data 
	# (prevent access to non-existing array)
	next if (! defined ($data_hash->{$table}));
	push (@out_array, "");
	push (@out_array, "<b><i style='color:darkred'>" . uc($table) . "</i></b>");
	push (@out_array, "<table style='border-top:1pt solid black; border-bottom:1pt solid black'>");
	# write column spec using the first entry
	$new_line = "  <tr bgcolor='#bbbbbb'>";
	@data = _split_line_order_ccvv ($data_hash->{$table}->[0]);
	$no_of_cols = ($#data + 1)/2;
	for (my $i = 0; $i < $no_of_cols; $i++ ) {
	    $new_line .= "<th style='border-bottom:1pt solid black;padding-left:10px;padding-right:20px'>" . $data[$i] . "</th>";
	}
	$new_line .= "</tr>";
	push (@out_array, $new_line);
	$idx = 0;
	foreach $line (@{$data_hash->{$table}}) {
	    if ($idx++ % 2 == 0) {
		$new_line = "  <tr bgcolor='#ffffff'>";
	    } else {
		$new_line = "  <tr bgcolor='#dddddd'>";
	    }
	    @data = _split_line_order_ccvv ($line);
	    $no_of_cols = ($#data + 1)/2;
	    for (my $i = 0; $i < $no_of_cols; $i++ ) {
		if ($data[$no_of_cols + $i] ne "") {
		    $new_line .=  "<td style='padding-left:10px;padding-right:20px'>" . $data[$no_of_cols + $i] . "</td>";
		} else {
		    $new_line .=  "<td style='padding-left:10px;padding-right:20px'>&nbsp;</td>";
		}
	    }
	    $new_line .= "</tr>";
	    push (@out_array, $new_line);
	}
	push (@out_array, "</table>");
	push (@out_array, "<p></p>");
    }
    push (@out_array, "</body>");
    push (@out_array, "</html>");
    
    wantarray ? @out_array : join "\n", @out_array;

} # sub _internal_2_html 

# ------------------------------------------------------------------------- #
# SUB: _internal_2_sql  
# ------------------------------------------------------------------------- #

=head2 _internal_2_sql ($data_hash, $table)

for each table in data hash each stored record (list of column name/value pairs) is translated into a suitable select statement like this:

  select * from <table> where <col1> = '<val1> [and <col2> = '<val2> ...]

the result ist the list of all such select statements.

a suitable sort_column call on the data hash should ensure that there are all not empty values are there.

Translating a data hash into SQL format could be useful to feed loaded or fetched data back to new collect_table_data() requests.

=cut

# SUB: _internal_2_sql  
# ------------------------------------------------------------------------- #
#
# convert _internal representation to "sql" format [write "sql"]
# usage:
#  @out_array = _internal_2_sql ([<print_just_data_of_that_table_name>])
# or
#  $buffer = _internal_2_sql ([<print_just_data_of_that_table_name>])
#
# used globals: %table_hash, $susi
# ------------------------------------------------------------------------- #
# 
sub _internal_2_sql {
    my $self = shift;
    my $data_hash = shift; 
    my $table = shift;  # optional argument
    my @out_array = ();
    my @ordered_table_list = ();
    my ($line,$field);
    my ($new_line,@data, $no_of_cols);

    my $empty_fields_as_any = 0; # DESIGN DECISION OPEN!

    if (defined $table) {
	@ordered_table_list = ($table);
    } else {
	# TODO table sort makes sense only if $data_hash = $self->{TABLE_DATA}
	if ($self->{PARAMS}->{table_sort}) {
	    # unused entries in %table_hash will not be detected so far!!!
	    @ordered_table_list = $self->get_table_order ();
	} else {
	    @ordered_table_list = sort keys %{$data_hash};
	}
    }
    foreach $table (@ordered_table_list) {
	# skip when table contains no data 
	# (prevent access to non-existing array)
	next if (! defined ($data_hash->{$table}));
	foreach $line (@{$data_hash->{$table}}) {
	    my $new_line = 'select * from '.$table.' where ';
	    my %data = _split_line_order_cvcv ($line);
	    foreach my $col (sort keys %data) {
		my $val = $data{$col};
		my $append = ' and ';
		if ($val) {
		    $new_line .=  $col."='".$data{$col}."'";
		} else {
		    if ($empty_fields_as_any) {
			# simply do nothing
			$append = '';
		    } else {
			# empty_fields_as_null
			$new_line .=  $col.' is null';
		    }
		}
		$new_line .= $append;
	    }
	    #remove last ' and ':
	    $new_line =~ s/ and $//;
	    push(@out_array, $new_line);
	}
    }

    wantarray ? @out_array : join "\n", @out_array;

} # sub _internal_2_html 

# ------------------------------------------------------------------------- #
# SUB: _internal_2_csv
# ------------------------------------------------------------------------- #

=head2 _internal_2_csv ($data_hash, $table)

It is quite similar to the 'passwd' format but instead of writing a header (that is usuable for reading that data back) it will simply write an additional line containing the field names (in uppercase)

=cut

# SUB: _internal_2_csv
# ------------------------------------------------------------------------- #
#
# convert _internal representation to "csv" format 
# usage:
#  @out_array = _internal_2_csv ([<print_just_data_of_that_table_name>])
# or
#  $buffer = _internal_2_csv ([<print_just_data_of_that_table_name>])
#
# used globals: %table_hash, $susi
# ------------------------------------------------------------------------- #
# 
sub _internal_2_csv {
    my $self = shift;
    my $data_hash = shift; 
    my $table = shift; # optional argument
    my @out_array = ();
    my @ordered_table_list = ();
    my ($line,$field);
    my ($new_line,@data, $no_of_cols);

    if (defined $table) {
	@ordered_table_list = ($table);
    } else {
	# TODO table sort makes sense only if $data_hash = $self->{TABLE_DATA}
	if ($self->{PARAMS}->{table_sort}) {
	    # unused entries in %table_hash will not be detected so far!!!
	    @ordered_table_list = $self->get_table_order ();
	} else {
	    @ordered_table_list = sort keys %{$data_hash};
	}
    }
    foreach $table (@ordered_table_list) {
	# skip when table contains no data 
	# (prevent access to non-existing array)
	next if (! defined ($data_hash->{$table}));
	next unless (@{$data_hash->{$table}});
	# write column spec using the first entry
	$new_line = "";
	@data = _split_line_order_ccvv ($data_hash->{$table}->[0]);
	$no_of_cols = ($#data + 1)/2;
	for (my $i = 0; $i < $no_of_cols; $i++ ) {
	    $new_line .= ":" . uc($data[$i]);
	}
	$new_line =~ s/^://;  # remove leading ':' 
        push (@out_array, "$new_line");
        foreach $line (@{$data_hash->{$table}}) {
	    $new_line = "";
	    @data = _split_line_order_ccvv ($line);
	    $no_of_cols = ($#data + 1)/2;
	    for (my $i = 0; $i < $no_of_cols; $i++ ) {
		# do ':' to special character substitution
		$data[$no_of_cols + $i] =~ s/:/$passwd_replace_colon/eg;
		$new_line .= ":" . $data[$no_of_cols + $i];
	    }
	    $new_line =~ s/^://;  # remove leading ':' 
	    push (@out_array, "$new_line");
	}
	$new_line =~ s/^://;  # remove leading ':' 
	$new_line = ":" x $no_of_cols;
	push (@out_array, $new_line);
    }

    wantarray ? @out_array : join "\n", @out_array;

} # sub _internal_2_passwd

# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = #
# SUBs to manipulate internal representation
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = #

# ------------------------------------------------------------------------- #
# SUB _concat_data_lines
# ------------------------------------------------------------------------- #
#
# usage: _concat_data_lines ( $line1, $line2, ...)
#
# class method
# ------------------------------------------------------------------------- #
sub _concat_data_lines {
    my $self = shift; # ignore it!

    return join "$fsep", @_;
}

# ------------------------------------------------------------------------- #
# SUB _complain (no class method!)
# ------------------------------------------------------------------------- #
#
# usage: _complain ( <string_that_caused_error_during_parsing>,
#                   <string_pattern_expected> )
# 
# ------------------------------------------------------------------------- #
sub _complain {
    my $line_no = shift;
    my $bad_string = shift;
    my $expect_string = shift;
    my $msg = "something seems to be wrong in line $line_no with string:\n" 
	. $bad_string . "\n";
    if (defined ($expect_string)) {
	$msg .= "I expect something like:\n" . $expect_string . "\n";
    }
    Carp::croak $msg;
}

# ------------------------------------------------------------------------- #
# SUB _split_line_order_cvcv
# ------------------------------------------------------------------------- #
#   
#  internal conversion : string -> list
# ------------------------------------------------------------------------- #
sub _split_line_order_cvcv {  # order refers to result
    my $line = shift || '';	# nothing in -> nothing out
    my @result = ();
    my $field;

    foreach $field (split /$fsep/, $line) { # <col>="<val>" pairs
# new pattern: allows $quote_char within <val>
	$field =~ /^([^$asgn_char]*)$asgn_char$quote_char(.*)$quote_char$/;
# old pattern:
#	$field =~ /^([^$asgn_char]*)$asgn_char$quote_char([^$quote_char]*)$quote_char$/;
	push (@result, $1); push (@result, $2);
    }

    # return (<col1>,<val1>,<col2>,<val2>,...)
    return @result; 
}

# ------------------------------------------------------------------------- #
# SUB _split_line_order_ccvv
# ------------------------------------------------------------------------- #
#   
#  internal conversion : string -> list
# ------------------------------------------------------------------------- #
sub _split_line_order_ccvv {  # order refers to result   
    my $line = shift || '';	# nothing in -> nothing out
    my @fields = ();
    my @values = ();
    my $field;

    foreach $field (split /$fsep/, $line) { # <col>="<val>" pairs
# new pattern: allows $quote_char within <val>
	$field =~ /^([^$asgn_char]*)$asgn_char$quote_char(.*)$quote_char$/;
# old pattern:
#	$field =~ /^([^$asgn_char]*)$asgn_char$quote_char([^$quote_char]*)$quote_char$/;
	push (@fields, $1); push (@values, $2);
    }
    
    # return (<col1>,<col2>,...,<val1>,<val2>,...)
    return (@fields, @values); 
}

# ------------------------------------------------------------------------- #
# SUB _compose_line_order_cvcv
# ------------------------------------------------------------------------- #
#   
#  internal conversion : list -> string 
# ------------------------------------------------------------------------- #
sub _compose_line_order_cvcv {  # order refers to input
    my %data = @_;       # list <col1> <val1> <col2> <val> ...
    my $result = "";

    foreach my $col (keys %data) {
	my $val = $data{$col};
	# shrink empty strings
	$val = "" if ($val =~ /^\s*$/);
	$result .= $fsep if ($result ne "");
	$result .= $col . $asgn_char . 
	    $quote_char . $val . $quote_char;
    }
    return $result;
}

# ------------------------------------------------------------------------- #
# SUB _compose_line_order_ccvv
# ------------------------------------------------------------------------- #
#   
#  internal conversion : list -> string 
# ------------------------------------------------------------------------- #
sub _compose_line_order_ccvv {  # order refers to input 
    my @data = @_;       # list <col1> <col2> ... <val1> <val2> ... 
    my $result = "";
    my $no_of_cols = ($#data + 1)/2;

    for (my $i = 0; $i < $no_of_cols; $i++ ) {
	# shrink empty strings
	$data[$no_of_cols + $i] = "" if ($data[$no_of_cols + $i] =~ /^\s*$/);
	$result .= $fsep if ($result ne "");
	$result .= $data[$i] . $asgn_char . 
	    $quote_char . $data[$no_of_cols + $i] . $quote_char;
    }
    return $result;
}


1;

__END__

# ------------------------------------------------------------------------- #
# more POD 
# ------------------------------------------------------------------------- #

=head1 SEE ALSO

Susi::Client
Susi::Description

=head1 AUTHOR

Frank-Christian Otto, <Frank-Christian.Otto@de.ibm.com>

S<(C) Copyright IBM Corporation 2000,2004>

=cut

