# $Id: Client.pm,v 1.18 2009/10/06 15:20:19 Andreas_Jung1 Exp $
# ------------------------------------------------------------------------- #
#
#   RCM - Reliable Configuration Management
#
#   (C) Copyright IBM Corporation 1999,2005
#   All Rights Reserved.
#
# ------------------------------------------------------------------------- #
#
#   RCM Utilities
#
# ------------------------------------------------------------------------- #

=pod

=head1 NAME

Susi::Client - Libary for access to RCM database

=head1 SYNOPSIS

  use Susi::Client;

=head1 DESCRIPTION

The Susi::Client module provides access to the RCM database for perl scripts using the susi protocol. 
The Perl DBI modules are available for all platforms and are running stable, fast and reliable but there are some good reasons to keep sticking to the susi protocol. Most important, you don't need an SQL*Net Connection available only with an large Oracle client.

=head1 METHODS

=over 4

=item B<new> I<{parameters}>

The constructor new() creates a new instance of the Susi:Client class. It can be given a anonymous hash containing settings for the RCM connection.

=item B<login>

The login method opens the connection to the database and creates a session with the user defined in the parameters. If no parameters are given, it sets some default values: 

=over 8

=item I<host> = 'rcm.rze.de.db.com'

=item I<instance> = 'rcm'

=item I<port> = '8421'

=item I<version> = '1'

=back

See the ACCESSOR FUNCTION section for more information about the parameters.

=item B<query> I<select statement>

Runs the select statement against the database and returns the rows. According to the protocol version in use the rows are separated by the row separator RSEP and the the columns are separated by the field separator FSEP. In the most commonly used version 1 the settings are RESP = '\n' and FSEP = '\t'.

=item B<open_query> I<select statement> I<handle>

Returns the column definitions of the select statement. The parameter I<handle> can be omitted if there's only one query open. If two or more queries have to be opened in parallel a handle have to be supplied to distinguish them from each other.

=item B<first_query> I<select statement> I<handle>

Return the first row of the select statement

=item B<next_query> I<select statement> I<handle>

Returns the remaining rows of the select statement

=item B<list_query> 

Returns the name (handle) of active query

=item B<close_query> I<handle>

Closes the query handle

=item B<exec_dml> I<sql>

Executes a dml statement either like 'insert into table ...' or executes a stored procedure. In case of an stored procedure the sql command has to be supplied either as anonymous BEGIN/END block or as 'exec procedure();'

=item B<exec_ddl>

Even DDL statements can be executed

=item B<commit>

Commits the previously executed dml statement if not commited internally.

=item B<rollback>

Performs a rollback on the previously executed dml statement.

=back

=head1 ACCESSOR FUNCTIONS

=over 4

=item B<host>

Sets/Returns the Hostid of the RCM Server

=item B<user>

Sets/Returns the user to login to RCM database

=item B<password>

Sets/Returns the users password

=item B<port>

Sets/Returns the port of the susiserver

=item B<instance>

Sets/Returns the Instance of the Oracle instance

=item B<version>

Sets/Returns the Version of the susi protocol

         version  |  record separator  | field separator
        ----------+--------------------+----------------- 
               1  |   '\n'             |   '\t'
               2  |   '\002' (^B)      |   '\001' (^A)

Version 2 is useful to treat entries containing '\n' or '\t'. 
You will always use the correct separators if you refer to
 $susi->RSEP and $susi->FSEP, respectively.

=back

=head1 EXAMPLE

  my $susi = Susi::Client->new( {host => 'rcmserver',
                                 user => 'you',
                                 password => 'your pasword'});
  $susi->login;

  ($status, $message) = $susi->query($sql);
  if ($status != 1403 && $status > 0) {
      die("Error reading from RCM -- $message\n") ;
  }
  chomp $message ;
  @rows = split /\n/, $message ;
  foreach $row (@rows) {
      @fields = split /\t/, $row ;
  }

=head1 REQUIRES

local installation of perl

=cut

package Susi::Client;

use Socket;
use Carp;
use Exporter;
@ISA = ('Exporter');
@EXPORT_OK = ('susi_socket', 'susi_connect', 'susi_login',
              'susi_logout', 'susi_disconnect',
              'susi_openquery', 'susi_listquery', 'susi_closequery',
              'susi_query', 'susi_firstquery', 'susi_nextquery',
              'susi_bunch', 'susi_execddl', 'susi_execdml',
              'susi_commit', 'susi_rollback',
              );

my $dbg = 0;		# > 5: print some debug info, > 6: prints lots of

my $RSEP = '\n';
my $FSEP = '\t';

my @rsep = ('', '\n', '\002');
my @fsep = ('', '\t', '\001');

sub RSEP { return $RSEP };
sub FSEP { return $FSEP };

my %defaults = ( 'server'	=> 'rcm.rze.de.db.com',
		 'port'		=> '8421',
		 'instance'	=> 'rcm',
		 'user'		=> 'rcmview',
		 'version'	=> '1'
		 );

my %SUSI_REQUESTS = (
    'QUIT',		0,
    'LOGIN',		1,
    'LOGOUT',		2,
    'OPENQUERY',	3,
    'CLOSEQUERY',	4,
    'LISTQUERY',	5,
    'FIRSTQUERY',	6,
    'NEXTQUERY',	7,
    'QUERY',		8,
    'CONNECT',		9,
    'EXECDDL',		10,
    'EXECDML',		11,
    'HELP',		12,
    'COMMIT',		13,
    'ROLLBACK',		14
);



# -------------------------------------------------------------------------
#
# OO-Interface
#
# -------------------------------------------------------------------------

# ---- Constructor --------------------------------------------------------
#	Arguments:	class (must be used as class function or method)
sub new($;$) {
    my $proto = shift;
    my $params = shift;
    
    my $class = ref $proto || $proto;
    my $self = {};
    bless $self, $class;
    
    $self->state("new");

    # set parameters supplied with the constructor
    $self->{'host'}	= ($$params{'host'})	 ? $$params{'host'}	: '';
    $self->{'port'}	= ($$params{'port'})	 ? $$params{'port'}	: '';
    $self->{'instance'} = ($$params{'instance'}) ? $$params{'instance'} : '';
    $self->{'user'}	= ($$params{'user'})	 ? $$params{'user'}	: '';
    $self->{'version'}	= ($$params{'version'})  ? $$params{'version'}	: '';
    $self->{'password'} = ($$params{'password'}) ? $$params{'password'} : '';
    $self->{'customer'} = ($$params{'customer'}) ? $$params{'customer'} : '';

    $dbg = $$params{'debug'} if $$params{'debug'};

    print STDERR $self->user, '/', $self->password, '@', $self->host, "\n" 
	if ($dbg > 5);
    
    return $self;
}


# ---- login() ------------------------------------------------------------
sub login($) {
    my $self = shift;
    my $socket;
    my $status;
    my $message;
    
    Carp::croak "wrong state for login"
	unless ($self->state eq "new");

    $self->{'host'}	= $defaults{'server'}	unless ($self->{'host'});
    $self->{'port'}	= $defaults{'port'}	unless ($self->{'port'});
    $self->{'instance'} = $defaults{'instance'} unless ($self->{'instance'});
    $self->{'version'}	= $defaults{'version'}	unless ($self->{'version'});
    $self->{'user'}	= $defaults{'user'}	unless ($self->{'user'});

    print STDERR "* socket...\n" if ($dbg > 5);
    $socket = $self->socket(&susi_socket ($self->host, $self->port));

    Carp::croak "Could not connect to $self->host:$self->port" 
	unless $socket;
    
    print STDERR "* connect...\n" if ($dbg > 5);
    unless (&susi_connect ($socket, $self->instance, $self->version)) {
	print STDERR "# could not connect to database \"".$self->instance."\" at \"".$self->host."\"\n"; 
	return;
    }
    
    print STDERR "* login...", $self->user, "/", $self->password, "\n" 
	if ($dbg > 5);

    ($status, $message) = &susi_login($socket, 
				      $self->user, $self->password);
    Carp::croak "#login error: $message on  \"".$self->instance."\" at \"".$self->host."\"\n" if ($status);
    
    $self->state("login");

    # set customer context
    $self->set_customer_context;

    return $self;
}


# ---- logout() ------------------------------------------------------------
sub logout($) {
    my $self = shift;
    my ($status, $message);
    if ($self->state eq "login") {
	($status, $message) = &susi_logout($self->socket);
    } else {
	$status = 0;
	$message = '';
    }
    return ($status, $message);
}


# ---- query() - this is why you went throught all the login-stuff --------
sub query($$) {
    my $self = shift;
    my $query = shift;
    my ($status, $message);

    if ($self->state eq "login") {
	($status, $message) = &susi_query($self->socket, $query);
    } else {
	Carp::croak "login before issueing queries";
    }
    return ($status, $message);
}


# ---- bunch() -----------------------------------------------------
sub bunch($$) {
    my $self = shift;
    my $query = shift;
    my ($status, $message);

    if ($self->state eq "login") {
	($status, $message) = &susi_bunch($self->socket, $query);
    } else {
	Carp::croak "login before issueing query";
    }
    return ($status, $message);
}


# ---- open_query() - to get a description of the query columns --------
sub open_query($$;$) {
    my $self = shift;
    my $query = shift;
    my $handle = shift || 'dummy';
    my ($status, $message);

    if ($self->state eq "login") {
	($status, $message) = &susi_openquery($self->socket, $handle, $query);
    } else {
	Carp::croak "login before issueing a query";
    }
    return ($status, $message);
}


# ---- first_query() - returns the first record of a query ------------
sub first_query($$;$) {
    my $self = shift;
    my $query = shift;
    my $handle = shift || 'dummy';
    my ($status, $message);

    if ($self->state eq "login") {
	($status, $message) = &susi_firstquery($self->socket, $handle, $query);
    } else {
	Carp::croak "login before issueing a query";
    }
    return ($status, $message);
}


# ---- next_query() - to be done after an open_query() --------
sub next_query($;$) {
    my $self = shift;
    my $handle = shift || 'dummy';
    my ($status, $message);

    if ($self->state eq "login") {
	($status, $message) = &susi_nextquery($self->socket, $handle);
    } else {
	Carp::croak "login before issueing a query";
    }
    return ($status, $message);
}


# ---- list_query() 
sub list_query($;$) {
    my $self = shift;
    my $handle = '';
    my ($status, $message);

    if ($self->state eq "login") {
	($status, $message) = &susi_listquery($self->socket, $handle);
    } else {
	Carp::croak "login before issueing a query";
    }
    return ($status, $message);
}


# ---- close_query() - to be done after an open_query() --------
sub close_query($;$) {
    my $self = shift;
    my $handle = shift || 'dummy';
    my ($status, $message);

    if ($self->state eq "login") {
	($status, $message) = &susi_closequery($self->socket, $handle);
    } else {
	Carp::croak "login before issueing a query";
    }
    return ($status, $message);
}


# ---- execdml() - be sure what you do ;-) -------------------------
sub exec_dml($$) {
    my $self = shift;
    my $query = shift;
    my ($status, $message);

    if ($self->state eq "login") {
	($status, $message) = &susi_execdml($self->socket, $query);
    } else {
	Carp::croak "login before issueing DMLs";
    }
    return ($status, $message);
}


# ---- execddl() - be even surer what you do ;-) -------------------
sub exec_ddl($$) {
    my $self = shift;
    my $query = shift;
    my ($status, $message);

    if ($self->state eq "login") {
	($status, $message) = &susi_execddl($self->socket, $query);
    } else {
	Carp::croak "login before issueing DDLs";
    }
    return ($status, $message);
}


# ---- commit() ----------------------------------------------------
sub commit($) {
    my $self = shift;
    my ($status, $message);
    if ($self->state eq "login") {
        ($status, $message) = &susi_commit($self->socket);
    } else {
	Carp::croak "login before committing";
    }
    return ($status, $message);
}


# ---- rollback() - for those faint of heart -----------------------
sub rollback($) {
    my $self = shift;
    my ($status, $message);
    if ($self->state eq "login") {
        ($status, $message) = &susi_rollback($self->socket);
    } else {
	Carp::croak "login before rollbacking";
    }
    return ($status, $message);
}



# -------------------------------------------------------------------------
#
# little helpers
#
# -------------------------------------------------------------------------

# ---- socket() -----------------------------------------------------------
sub socket($;$) {
    my $self = shift;
    my $socket = shift;

    if (defined $socket) { $self->{'socket'} = $socket }
    return $self->{'socket'};
}


# ---- state() - setting and changing of Object's state -------------------
sub state($;$) {
    my $self = shift;
    my $state = shift;
    if (defined $state) { $self->{'state'} = $state }
    return $self->{'state'};
}


# ---- host() - setting the RCM-host --------------------------------------
sub host($;$) {
    my $self = shift;
    my $host = shift;
    if (defined $host) {
        if ($self->state eq "new") {
            $self->{'host'} = $host;
        } else {
            Carp::croak "it's no good idea to change RCMhost after login";
        }
    }
    return $self->{'host'};
}


# ---- user() - setting the RCM-user for login ----------------------------
sub user($;$) {
    my $self = shift;
    my $user = shift;
    if (defined $user) { 
        if ($self->state eq "new") {
            $self->{'user'} = $user;
        } else {
            Carp::croak "it's no good idea to change RCMuser after login";
        }
    }
    return $self->{'user'};
}


# ---- port() - setting the RCM-port -------- ----------------------------
sub port($;$) {
    my $self = shift;
    my $port = shift;
    if (defined $port) { 
        if ($self->state eq "new") {
            $self->{'port'} = $port;
        } else {
            Carp::croak "it's no good idea to change the port after login";
        }
    }
    return $self->{'port'};
}


# ---- instance() - only needed when connecting a RCM Database
#                       instance not named 'rcm'  --------------------------
sub instance($;$) {
    my $self = shift;
    my $instance = shift;
    if (defined $instance) { 
        if ($self->state eq "new") {
            $self->{'instance'} = $instance;
        } else {
            Carp::croak "it's no good idea to change the instance after login";
        }
    }
    return $self->{'instance'};
}


# ---- password() - you allready guessed it -------------------------------
sub password($;$) {
    my $self = shift;
    my $password = shift;
    if (defined $password) { 
        if ($self->state eq "new") {
            $self->{'password'} = $password;
        } else {
            Carp::croak "it's no good idea to change password after login";
        }
    }
    return $self->{'password'};
}


# ---- version() - setting this controls the field/record separator --
##                   - for query responses  ------------------------------
sub version($;$) {
    my $self = shift;
    my $version = shift;
    if (defined $version) { 
        if ($self->state eq "new") {
	    Carp::croak "unsupported connect version number ($version)"
		unless ( $version == 1 or $version == 2 );  
            $self->{'version'} = $version;
	      $RSEP = $rsep[$version];
	      $FSEP = $fsep[$version];
        } else {
            Carp::croak "it's no good idea to change the version after login";
        }
    }
    return $self->{'version'};
}

# ---- set customer context -------- ----------------------------
sub set_customer_context {
    my $self = shift;
    my $customer = shift || $self->{'customer'};
    Carp::croak "#set_customer_context: you need to login first" 
	unless ($self->state eq "login");

    if (defined $customer) { 
	$self->{'customer'} = $customer;
	print STDERR "* set customer context...", $self->{'customer'}, "\n" 
	  if ($dbg > 5);
	&susi_execdml($self->socket, "begin rcmadm.cust_priv_context.set_session_cid('".$self->{'customer'}."'); end;");
	Carp::croak "#set_customer_context: $message" if ($status);
    }
    return $self->{'customer'};
}


# -----------------------------------------------------------------
#
# Procedural interface
#
# -----------------------------------------------------------------

# ----- susi_socket() ---- (exported) -----------------------------
sub susi_socket {
  my ($them,$port) = @_;
  $port = $defaults{port} unless $port;
  $them = 'localhost' unless $them;

  unless ($port =~ /^\d+$/) {
      # seems not to be a number
      # try to translate into number via getservbyname
      $port = getservbyname ($port, 'tcp');
      # fall back if it's not translatable
      $port = $defaults{port} unless ($port =~ /^\d+$/);
  }
				# blue camel, p. 352
  my $iaddr = gethostbyname ('localhost');
  my $proto = getprotobyname ('tcp');

  my $paddr = sockaddr_in(0, $iaddr);

  my $hisiaddr = inet_aton ($them) || die "Unknown host: $them";
  my $hispaddr = sockaddr_in($port, $hisiaddr) || die "socket: $!"; 

  CORE::socket(SOCKET, PF_INET, SOCK_STREAM, $proto) || die "socket: $!";
  connect (SOCKET, $hispaddr) or die "can't connect to port $port on $them\n$!";
  select(SOCKET); $| = 1; select(STDOUT);
  return SOCKET;
}


# ----- susi_connect() ---- (exported) ----------------------------
sub susi_connect {
    my $sock = shift;
    my $ora_sid = shift;
    my $version = (defined($ARGV = shift)) ? $ARGV : 1;
    my ($status, $message) =
	send_and_receive ($sock, $SUSI_REQUESTS{CONNECT}, "$ora_sid $version");
    return ($status == 0) ? 1 : 0;
}


# ----- susi_login() ---- (exported) ------------------------------
sub susi_login {
    my ($sock, $name, $passwd) = @_;
    if (!defined $passwd) {
	print "Password:";
	system 'stty', '-echo';
	chomp($passwd = <STDIN>);
	system 'stty', 'echo';
	print "\n";
    }
    my($status, $message, $length) =
	send_and_receive($sock, $SUSI_REQUESTS{LOGIN}, $name,  $passwd);
    return ($status, $message);
}


# ----- susi_disconnect() ---- (exported) -------------------------
sub susi_disconnect {
    my $sock = shift;
    close ($sock);
    return;
}


# ----- susi_logout() ---- (exported) -----------------------------
sub susi_logout {
    my $sock = shift;
    my($status, $message, $length) 
	= send_and_receive($sock, $SUSI_REQUESTS{LOGOUT});
    return ($status, $message);
}


# ----- susi_openquery() ---- (exported) --------------------------
sub susi_openquery {
    my($sock, $handle, $query) = @_;
    my($status, $message, $length) 
	= send_and_receive($sock, $SUSI_REQUESTS{OPENQUERY}, $handle,  $query);
    return ($status, substr($message, 0, $length - 1));
}


# ----- susi_listquery() ---- (exported) --------------------------
sub susi_listquery {
    my($sock) = @_;
    my($status, $message, $length) 
	= send_and_receive($sock, $SUSI_REQUESTS{LISTQUERY});
    return ($status, $message);
}


# ----- susi_closequery() ---- (exported) -------------------------
sub susi_closequery {
    my($sock, $handle) = @_;
    my($status, $message, $length) 
	= send_and_receive($sock, $SUSI_REQUESTS{CLOSEQUERY}, $handle);
    return ($status, $message);
}


# ----- susi_firstquery() ---- (exported) -------------------------
sub susi_firstquery {
    my($sock, $handle, $query) = @_;
    my($status, $message, $length) 
	= send_and_receive($sock, $SUSI_REQUESTS{FIRSTQUERY}, $handle,  $query);
    $message = substr($message, 0, $length - 1);
    return ($status, $message);
}


# ----- susi_nextquery() ---- (exported) --------------------------
sub susi_nextquery {
    my($sock, $handle) = @_;
    my($status, $message, $length) 
	= send_and_receive($sock, $SUSI_REQUESTS{NEXTQUERY}, $handle);
    $message = substr($message, 0, $length - 1);
    return ($status, $message);
}


# ----- susi_query() ---- (exported) ------------------------------
sub susi_query {
    my($sock, $query) = @_;
    my($this_count) = 0;
    my($output) = "";
    my($SUSI_COUNT_OFFSET) = 8;
    my($SUSI_NO_MORE_DATA) = 1403;
    my($SUSI_MORE_TO_COME) = 1;
    my($status, $message, $length) = (0, "", 0);
    $susi_count = 0;
    while  (1) {
	($status, $message, $length) =
	    send_and_receive($sock, $SUSI_REQUESTS{QUERY}, $query);
#	print STDERR "$message $length $status\n";
	$length -= $SUSI_COUNT_OFFSET;
	if ($status == 0) {
	    $this_count = substr($message, 0, $SUSI_COUNT_OFFSET);
	    $output .= substr($message, $SUSI_COUNT_OFFSET, $length - 1);
	    $susi_count += $this_count;
	} elsif ($status == 1403) {
	    if ($message =~ /^\d+/) {
		$this_count = substr($message, 0, $SUSI_COUNT_OFFSET);
		$output .= substr($message, $SUSI_COUNT_OFFSET, $length - 1);
		$susi_count += $this_count;
	    } else {
		$this_count = 0;
		$output = "";
	    }
	    last;
	} elsif ($status == 1) {
	    $this_count = substr($message, 0, $SUSI_COUNT_OFFSET);
	    $output .= substr($message, $SUSI_COUNT_OFFSET,  $length - 1);
	    $susi_count += $this_count;
	    $query = "";
	} else {
	    $output = $message;
	    last;
	}
    }
    return ($status, $output);
}


# ----- susi_bunch() ---- (exported) ------------------------------
sub susi_bunch {
    my($sock, $query) = @_;
    my($this_count) = 0;
    my($output) = "";
    my($SUSI_COUNT_OFFSET) = 8;
    my($SUSI_NO_MORE_DATA) = 1403;
    my($SUSI_MORE_TO_COME) = 1;
    my($status, $message, $length) = (0, "", 0);
    $susi_count = 0;
    ($status, $message, $length) =
	send_and_receive($sock, $SUSI_REQUESTS{QUERY}, $query);
    if ($status != $SUSI_NO_MORE_DATA && $status != $SUSI_MORE_TO_COME) {
	return ($status, $message);
    }
    $length -= $SUSI_COUNT_OFFSET;
    $susi_count = substr($message, 0, $SUSI_COUNT_OFFSET);
    $output .= substr($message, $SUSI_COUNT_OFFSET, $length - 1);
    return ($status, $output);
}


# ----- susi_execddl() ---- (exported) ----------------------------
sub susi_execddl {
    my($sock, $query) = @_;
    my($status, $message, $length) 
	= send_and_receive($sock, $SUSI_REQUESTS{EXECDDL},  $query);
    return ($status, $message);
}


# ----- susi_execdml() ---- (exported) ----------------------------
sub susi_execdml {
    my($sock, $query) = @_;
    my($status, $message, $length) 
	= send_and_receive($sock, $SUSI_REQUESTS{EXECDML},  $query);
    return ($status, $message);
}


# ----- susi_commit() ---- (exported) -----------------------------
sub susi_commit {
    my $sock = shift;
    my($status, $message, $length) 
	= send_and_receive($sock, $SUSI_REQUESTS{COMMIT});
    return ($status, $message);
}


# ----- susi_rollback() ---- (exported) ---------------------------
sub susi_rollback {
    my $sock = shift;
    my($status, $message, $length) 
	= send_and_receive($sock, $SUSI_REQUESTS{ROLLBACK});
    return ($status, $message);
}


# ----- send_and_receive() --- (private) --------------------------
sub send_and_receive {
    my $sock = shift;
    my $key = shift;
    my $message = "".join (' ', @_);
    my $status = 0;
    my $length = length($message);
    $SUSI_HEADER_OFFSET = 12;
    printf $sock "%04d %06d %s", $key, $length, $message;
    print STDERR "* send_and_receive : send $message\n" if ($dbg > 6);
    read($sock, $message, $SUSI_HEADER_OFFSET);
    unless ($message) {
	print STDERR "# communication error \n";
	return (-1, "", 0);
    }

    print STDERR "* send_and_receive : got $message\n" if ($dbg > 6);
    ($status, $length) = split(/\s/, $message);
    read($sock, $message, $length);
    return (int($status), $message, $length);
}

sub dokill {
    kill 9, $child if $child;
};


1;

# $Id: Client.pm,v 1.18 2009/10/06 15:20:19 Andreas_Jung1 Exp $
# ------------------------------------------------------------------------- #
