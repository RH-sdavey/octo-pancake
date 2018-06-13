#!/usr/bin/perl -w
#   $Id: appl_template.pl,v 1.14 2011/07/05 09:45:55 Frank-Christian_Otto Exp $
# ------------------------------------------------------------------------- #
#
#   RCM - Reliable Configuration Management
#
#   (C) Copyright IBM Corporation 1999,2004,2008
#   All Rights Reserved.
#
# ------------------------------------------------------------------------- #
#
#   SOS - batch tool set
#
# ------------------------------------------------------------------------- #
#
#   Module:	appl_template.pl
#
#   Author:     Andreas Jung
#
#   Date:	6.2.2001
#
#   Purpose:	maintains a table with a blob column that is able to store
#		a template file for a certain application
#
#   Modified: 11/2008 by Maurice Brinkmann - configuration file handling enhanced 
#
#		see usage/pod for details
#
#		This program requires the DBI and DBD::Oracle libraries
#		if access = dbi was chosen
#
# ------------------------------------------------------------------------- #

use strict;

use Getopt::Long;
use File::Basename;

use lib (dirname($0) . "/../lib"); 
use Susi::CommonTools;
use Susi::Defaults;

my ($hostid, $service, $function, $filename, $fullname);
my ($access, $mode);

my $LONG_RAW_TYPE=24;		# Oracle type id for blobs / Raw binary data
my $BLOB_TYPE=113;		# Oracle type id for blobs

my $db;				# dbi handle
my $jamaika;			# http handle for jamaika

my $use_dbi		= 0;	# experimental .. if DBI available
my $use_jamaika		= 1;	# preferred access mode

my ($help, $man, $config_file, $debug);
my ($rcm_host, $rcm_port, $rcm_inst, $rcm_user, $rcm_pwd);
my $rcm_customer_context;

format APPL_FILES_TOP =
Service      Function         Filename
------------ ---------------- --------------------------------------
.

format APPL_FILES =
@<<<<<<<<<<< @<<<<<<<<<<<<<<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$service, $function, $filename
.

if (! GetOptions( "help|?"		=> \$help,
			"man"			=> \$man,
		    "C|config-file=s"			   => \$config_file,
			"d|debug:+"	       	=> \$debug,
		  "access=s"	=> \$access,
		  "mode=s"	=> \$mode,
		  "service=s"	=> \$service,
		  "function=s"	=> \$function,
		  "filename=s"	=> \$filename,
		  "fullname=s"	=> \$fullname,
			# RCM Options:
			"user=s"		=> \$rcm_user,
			"password=s"		=> \$rcm_pwd,
			"S|server=s"     	=> \$rcm_host,
			"port=s"       	=> \$rcm_port,
			"instance=s"   	=> \$rcm_inst,
		)) {
    print STDERR "\n### wrong Arguments ###\n\n";
    &Usage; 
    exit 1;
}

if ($help) {
    &Usage;
    exit 0;
}

manual () if ($man);

if ($access && uc($access) eq 'DBI') {
    $use_dbi = 1;
    $use_jamaika = 0;
} elsif ($access && uc($access) eq 'JAMAIKA') {
    $use_dbi = 0;
    $use_jamaika = 1;
} else {
    $use_dbi = 1;
    $use_jamaika = 1;
}

# defaults for database access
my %DefParams;
$DefParams{'dontask4pwd'} = '1' if ($rcm_pwd || $rcm_user);
$DefParams{'config_file'} = $config_file if ($config_file);
my $defaults = Susi::Defaults::init(\%DefParams);

$rcm_port   = $defaults->{'port'}	unless ($rcm_port);
$rcm_host   = $defaults->{'server'}	unless ($rcm_host);
$rcm_inst   = $defaults->{'inst'}	unless ($rcm_inst);
unless ($rcm_customer_context) {
    $rcm_customer_context = $defaults->{'customer'} if
      $defaults->{'customer'};
}

if ($rcm_user) {
    unless ($rcm_pwd) {
	if ($rcm_user eq $defaults->{'user'} and $defaults->{'password'}) {
	    $rcm_pwd = $defaults->{'password'};
	} else {
	    $rcm_pwd = get_password($rcm_user);
	}
    }
} elsif ($defaults->{'user'}) {
    $rcm_user = $defaults->{'user'};
    $rcm_pwd = $defaults->{'password'} unless ($rcm_pwd);
} else {
    # very unlikely case
    print STDERR "username for RCM query:";
    $rcm_user = <STDIN>;
    chomp $rcm_user;
    $rcm_pwd = get_password($rcm_user);
}

   
# try dbi connection to RCM database
if ($use_dbi) {
    $debug && print STDERR "* trying DBI...\n";
    print STDERR "* connecting to database $rcm_user", 
             ($debug > 2) ? "/$rcm_pwd" : "", 
             "\@$rcm_host",
             ($debug > 1) ? " Inst:$rcm_inst Port:$rcm_port" : "",
             "\n" 
        if ($debug);    
    if (eval('use DBI; use DBD::Oracle; 1;') ) {
	# Use Perl DBI/DBD to connect to DB
	my $rcm_connector = "dbi:Oracle:host=$rcm_host;sid=rcm";
	$debug && print STDERR "* connector    = $rcm_connector\n";
	$debug && print STDERR "* login/passwd = $rcm_user/$rcm_pwd\n";
	
	$ENV{ORACLE_HOME} = "/dev/null" unless $ENV{ORACLE_HOME};
	$db = DBI->connect($rcm_connector, $rcm_user, $rcm_pwd,
			   {PrintError => 1, RaiseError => 1, AutoCommit => 1});
	if ($db) {
	    $debug && print STDERR "* connected to db per DBI/DBD\n";
	    $use_dbi = 1;
	    $use_jamaika = 0;
	} else {
	    print STDERR "could not connect to db per DBI/DBD:\n$DBI::errstr\n";
	    $use_dbi = 0;
	    $use_jamaika = 1;
	}
    } else {
	$use_dbi = 0;
	$debug && print STDERR "could not load DBI/DBD modules\n";
    }
}

# try connection via jamaika server
if ($use_jamaika) {
    $debug && print STDERR "* trying Jamaika...\n";
    unless (eval('use Susi::Jamaika; 1;')) {
	print STDERR "Sorry, can't use the Jamaika module. There are other Perl modules missing\n\n";
	print STDERR $@, "\n";
	exit 1;
    }
    my $url = 'HTTP://'.$rcm_host.':8080';
    $jamaika = new Jamaika( { 'jamaika_url'  => $url,
			      'rcm_user'     => $rcm_user,
			      'rcm_password' => $rcm_pwd,
			      'debug' => $debug,
			  });
    if ($jamaika) {
	$use_jamaika = 1;
	$debug && print STDERR "* connected to Jamaika server $url\n";
    } else {
	print STDERR "had Problems to use Jamaika\n";
	exit 1;
    }
}

if (! $mode) {
    print STDERR "assuming select mode...\n";
    $mode = 'select';
}

if ($mode =~ /select|insert|delete|list/) {
    $service  = (defined $service) ? 
	$service : &inquire ("echo", "Service  : ");
}

if ($mode =~ /select|insert|delete/) {
    $function = (defined $function ) ?
	$function  : &inquire ("echo", "Function : ");
    $filename = (defined $filename) ? 
	$filename : &inquire ("echo", "Filename : ");
}

# Check args
if ($mode eq "select") {
    if ($use_dbi) {
	dbi_select();
    } elsif ($use_jamaika) {
        my $out = $jamaika->get_template({'service'  => $service,
					  'function' => $function,
					  'filename' => $filename });
	print STDOUT $_, "\n" foreach (@{$out});
    }
} elsif ($mode eq "insert") {
    $fullname = (defined $fullname) ? 
        $fullname : &inquire ("echo", "FQ local filename: ");
    if ($use_dbi) {
	dbi_insert();
    } elsif ($use_jamaika) {
	my $out = $jamaika->put_template({ 'service'  => $service,
					   'function' => $function,
					   'filename' => $filename,
					   'file_content' => [$fullname] });
	$debug && print STDERR $_, "\n" foreach (@{$out});
    }
} elsif ($mode eq "delete") {
    if ($use_dbi) {
	dbi_delete();
    } elsif ($use_jamaika) {
	my $out = $jamaika->delete_template({ 'hostid'   => $hostid,
					      'service'  => $service,
					      'function' => $function,
					      'filename' => $filename });
	$debug && print STDERR $_, "\n" foreach (@{$out});
    }
} elsif ($mode eq "list") {
    if ($use_dbi) {
	dbi_list();
    } elsif ($use_jamaika) {
	jam_list();
    }
} else {
    &Usage;
    exit 0;
}
	
exit(0);


# ----- FUNCTIONS --------------------------------------------------------- #

# ------------------------------------------------------------------------- #
#   Procedure:	jam_list
#   Arguments:	none
#   Returnvalue:none
#   Purpose:	list records in the appl_template table. 
#		access via jamaica server
# ------------------------------------------------------------------------- #
sub jam_list
{
    my $records = $jamaika->get_template_list({ 'service'  => $service,
						'function' => $function });
    my $row = 0;
    if (@{$records}){
	printf ("%-18s %-18s %-40s\n", "Service", "Function", "Filename");
	print '-'x75, "\n";
    } else {
	print "No data found\n";
	return;
    }
    foreach my $record (@{$records}) {
	$service = ${$record}{service};
	$function = ${$record}{function};
	$filename = ${$record}{filename};
	printf ("%-18s %-18s %-40s\n", $service, $function, $filename);
	$row++;
    }
    
    $debug && print STDERR "* $row rows fetched\n";
}


# ------------------------------------------------------------------------- #
#   Procedure:	dbi_list
#   Arguments:	none
#   Returnvalue:none
#   Purpose:	list records in the appl_file table
# ------------------------------------------------------------------------- #
sub dbi_list
{
    my ($sql, $sth, $rc, $row);
    my ($and_function, $and_filename);

    unless ($service) {
	print STDERR "Please supply a service\n";
	return undef;
    }

    $and_function = ($function) ? "and function = '$function'" : '';
    $and_filename = ($filename) ? "and filename like '$filename'" : '';

    $debug && print STDERR "* reading records for $hostid...\n";

    $sql = "select service, function, filename from rcm.appl_template 
		where service = '$service'
		$and_function $and_filename";

    $debug && print STDERR "* SQL: $sql\n";

    $sth = $db->prepare ($sql) || 
	die "Can't prepare statement: $DBI::errstr";
    $rc = $sth->execute ||
	die "Can't execute statement: $DBI::errstr";

$~ = 'APPL_FILES';
$^ = 'APPL_FILES_TOP';

    $row = 0;
    while (($service, $function, $filename) = $sth->fetchrow_array) {
	write;
	$row++;
    }

    if (!$row) {
	print STDERR "No data found\n";
    } else {
	$debug && print STDERR "* $row rows fetched\n";
    }
}


# ------------------------------------------------------------------------- #
#   Procedure:	dbi_insert
#   Arguments:	none
#   Returnvalue:none
#   Purpose:	insert a row with a blob object into the rcm database
# ------------------------------------------------------------------------- #
sub dbi_insert
{
    my $fullname = (defined $fullname) ? 
        $fullname : &inquire ("echo", "Full Name: ");
    my ($buf, $bytes);
    my $sql = "insert into rcm.appl_template " .
              "(service, function, filename, appl_template)" .
              " values " .
              "('$service', '$function', '$filename', :lob)";

    $debug && print STDERR "* SQL: $sql\n";

    my $stmt = $db->prepare($sql) || die "\nPrepare error: $DBI::errstr\n";
    my %attrib;

    open(LOB, "$fullname");
    $bytes = 0;
    $bytes = read(LOB, $buf, 500000);
    
    print STDERR "Read $bytes bytes...\n";
    close(LOB);
    
    $attrib{'ora_type'} = $BLOB_TYPE;
    $stmt->bind_param(":lob", $buf, \%attrib);  
    $stmt->execute() || die "\nExecute error: $DBI::errstr\n";
    print STDERR "record inserted\n";
}


# ------------------------------------------------------------------------- #
#   Procedure:	dbi_select
#   Arguments:	none
#   Returnvalue:none
#   Purpose:	select column with a BLOB object from rcm database
# ------------------------------------------------------------------------- #
sub dbi_select
{
    $db->{LongReadLen}=500000;
	
    my $sql = "select appl_template from rcm.appl_template " .
              "where  service = '$service' and" .
              "       function = '$function' and" .
              "       filename = '$filename'";

    $debug && print STDERR "* SQL: $sql\n";

    my $stmt = $db->prepare($sql) || 
	die "\nPrepare error: $DBI::errstr\n";

    $stmt->execute() || die "\nExecute error: $DBI::errstr\n";

    my $row = 0;
    while (my $blob = $stmt->fetchrow) {
	$row++;
	$debug && printf STDERR "* Fetching row %d \n", $row;
	print STDOUT $blob;
    }
    $stmt->finish();
    
    if (!$row) {
	print STDERR "No data found\n";
    } else {
	$debug && print STDERR "* Complete\n";
    }
}


# ------------------------------------------------------------------------- #
#   Procedure:	dbi_delete
#   Arguments:	none
#   Returnvalue:none
#   Purpose:	delete row with a BLOB object from rcm database
# ------------------------------------------------------------------------- #
sub dbi_delete
{
    my $sql = "delete from rcm.appl_template " .
              "where  service  = '$service' and" .
              "       function = '$function' and" .
              "       filename = '$filename'";

    $debug && print STDERR "* SQL: $sql\n";

    my $stmt = $db->prepare($sql) || 
	die "\nPrepare error: $DBI::errstr\n";

    $stmt->execute() || die "\nExecute error: $DBI::errstr\n";
    print STDERR "record deleted\n";
}


# ------------------------------------------------------------------------- #
#   inquire - get input string from keyboard
#
#   $1	- mode: "echo" or "noecho"
#   $2	- Promptstring
# ------------------------------------------------------------------------- #
sub inquire {
    my ($mode, $str) = @_;
    my $val;
    my $noecho = 0;

    open INPUT, "</dev/tty";
    print STDERR "$str";
    if ($mode eq "noecho") {
	system "stty -echo < /dev/tty > /dev/tty 2>&1";
	$noecho = 1;
    }
    chomp($val = <INPUT>);
    if ($noecho) {
	system "stty echo < /dev/tty > /dev/tty 2>&1";
	print STDERR "\n";
    }
    close INPUT;
    return $val;
}

# ------------------------------------------------------------------------- #
#   Procedure:	Usage
#   Arguments:	none
#   Returnvalue:none
#   Purpose:	print the usage of this module
# ------------------------------------------------------------------------- #
sub Usage {

    print <<EOF

  Usage: $0 [Options] --mode [insert|select|delete|list]

  Options:
    --service		major application identifier (service:function)
    --function		specific function of the application
    --filename		the file will be stored under this name
    --fullname		path to the file on the local machine (insert)
    --mode			[insert|select|delete|list] (select)
    
  General Options:
    -C | --config-file <config_file>	reads rcm options from that file or creates it
    -d | --debug <level>    prints debug messages
    -? | --help				prints this message
         --man				prints man page (basically POD)

  RCM Options:
    --user <user>           database account. (Def: preset)
    --password <password>   database password (Def: preset)
    -S | --server <host>    rcm database server (Def: preset RCM server)

  see 'perldoc appl_template.pl' for more information and examples

EOF
;
}

__END__

# ------------------------------------------------------------------------- #
#   documentation in POD
# ------------------------------------------------------------------------- #

=pod

=head1 NAME

appl_template.pl - store a template file in a blob object

=head1 SYNOPSIS

appl_template.pl [Options] --mode [insert|select|delete|list]

=head1 DESCRIPTION

This script is able to insert, delete and select a template file into a blob object in the rcm database. The record constisting of service, function, filename, appl_file and description will be stored in the RCM.APPL_TEMPLATE table. The values for service, function and filename are the key to the stored file and must be supplied. If they are not supplied as commandline parameter they will be inquired from the program. In case of inserting a record the location of the file must be given by the fullname parameter.

Selecting a record/file from the table will be performed with a standard readonly account. Select, Insert and Delete works only with a personalized account which must be authentificated by a password.

Invoking the script in list mode will cause appl_template.pl to retreive the filenames stored for an application (S:F). 

The SOS Mask Top->Applications->APPL_TEMPLATE shows which templates are already stored in this table. It cannot display the content of the file because in the surrent version the susiserver is not able to deal with BLOB database objects.
Ths sripts uses the perl dbi module to handle these BLOBs. So this scripts work correctly only on machines where perl:dbi is installed.

Please note that special permission is required in order to access the application templates stored in RCM.APPL_TEMPLATE.

=head1 OPTIONS

=over 4

=item B<--service> I<service>

The major application identifier in the sense of the way applications are identified as service:function in RCM.

=item B<--function> I<function>

specific function of the application

=item B<--filename> I<identifier>

The template file will be stored under this name in the appl_template table. The filename is not neccessary the fully qualified filename where the template will be stored on the machine.

=item B<--fullname> I<filename>

Fully qualified filename where the template file will be read from during insert. In this sense this option only makes sense for insert.

=item B<--mode> I<mode>

Operation mode of appl_template.pl. 

=over 8

=item I<list>

List all filenames stores for a given service:function

=item I<select>

Select the content of a given filename identified by service:function:filename

=item I<insert>

Store a template file on the RCM Server.

=item I<delete>

Remove a given filename from the RCM.APPL_TEMPLATE entitiy in the RCM Database 

=back

=item B<--user> I<rcm-user>

Database account to connect to the rcm database. Only necessary if different from user stored in your personal defaults.

=item B<--password> I<password>

Depending on your personal defaults a stored password is used automatically. If no stored password is available you will be prompted for it.

You will also prompted for a password if you are connection to a user different from the defaults (by means of --user).

If you want to prevent that behavior can you provide the password on the command line with option --password.

NOTE: the password needs to be given as plain text and might be visible in the process list.

=item B<-S|--server> I<database-server>

hostname of the machine, that runs the rcm database. Useful to connect other machines than the productive database.

=item B<--debug>

prints some debug messages

=item B<--help|?>

print a usage

=back

=head1 EXAMPLES

  # list files stored for a given Service:Function
  appl_template.pl --mode list --service xServ --function xFunc 

  # insert a template (/tmp/my_template) into the appl_template table
  appl_template.pl --mode insert --service xServ --function xFunc 
    --filename xTemplate  --fullname /tmp/my_template

  # read a file from the appl_template table. The search criteria will be 
  # inquired  since they aren't supplied on the command line
  appl_template.pl --mode select > /tmp/xxx

  # delete a template file from the appl_template table
  appl_template.pl --mode delete 
    --service xServ --function xFunc --filename xTemplate

=head1 AUTHOR

S<Andreas Jung>

=cut

# ------------------------------------------------------------------------- #
