#   @(#) $Id: Description.pm,v 1.6 2005/06/22 12:24:33 ajung Exp $
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
#   Module:	Description
#
#   Author:	Werner Wiethege
#		ww's last version 1.4 97/03/21 09:59:38
#
#   Date:	3/97
#
#   Purpose:	Perl Module that delivers the Type of Database Objects
#
# ------------------------------------------------------------------------- #

=pod

=head1 NAME

Susi::Description - describe database objects

=head1 DESCRIPTION

This module provides some library functions to describe database objects.

=cut

use Carp;
use Susi::Client;

package Susi::Description;

# TODO : do some exporter stuff here!
#use Exporter();
#use vars qw(@ISA @EXPORT @EXPORT_OK);
#@ISA = qw(Exporter);
#@EXPORT = qw(&what &fields &types &dirs &routines &sizes);


# {{{ ---- Constructor --------------------------------------------------------
sub new {
   my $proto = shift;
   my $class = ref $proto || $proto;

   my $susi = shift;
   my $object = shift;
   my $owner = shift;

   my $self = {};
   bless $self, $class;

   if (! defined $susi ) {
     Carp::croak ("constructor expects already constructed Susi::Client object as 1st arg\n"); 
       # TODO improve this
   } elsif ($susi->state ne "login") {
       # fire login procedure from Susi::Client 
       $susi->login();
   }
   
    ($self->{name} = uc($object)) =~ s/^\s*(.*?)\s*$/$1/;
    $self->{user} = uc($owner) if (defined $owner);
    $self->{susi} = $susi;
    # to prevent some "uninitialized value" errors:
    $self->{pk_fields} = [];

    describe($self);
    return $self;
}
#----------------------------------------------------------------
sub type {
    $this = shift;
    return $this->{ora_type};
}
#----------------------------------------------------------------
sub fields {
    $this = shift;
    return @{$this->{args}};
}
#----------------------------------------------------------------
sub pk_fields {
    $this = shift;
    return @{$this->{pk_fields}};
}
#----------------------------------------------------------------
sub types {
    $this = shift;
    return @{$this->{ora_types}};
}
#----------------------------------------------------------------
sub sizes {
    $this = shift;
    return @{$this->{size}};
}
#----------------------------------------------------------------
sub dirs {
    $this = shift;
    return @{$this->{ora_dirs}};
}
#----------------------------------------------------------------
sub routines {
    $this = shift;
#    print keys %{$this->{components}}, "\n";
    return %{$this->{components}};
}
#----------------------------------------------------------------
sub describe {
    $this = shift;
    my @fields = split (/\./, $this->{name});
    if ($#fields == 2) {	# easy
	describe_package(@fields);
    } elsif ($#fields == 1) {	# owner.object or package.procedure
	resolve_two($this->{user}, @fields);
    } elsif ($#fields == 0) {	# anything
	my $object = shift(@fields);
	resolve_object($this);
    }
}
#----------------------------------------------------------------
sub resolve_two {
    my $sock = $this->{sock};
    my $object = $this->{name};
    my $i_am = $this->{user};
    
    my ($foo, $bar) = split(/\./, $object);
    my @results = ();
    my %results = ();
				# try my own first
    my $query = "SELECT object_type FROM user_objects 
	WHERE object_name = upper('$foo') AND object_type = 'PACKAGE'";
#    print STDERR "$query\n";
    my ($status, $message) = $this->{susi}->query($query);
    die $message if ($status != 1403 && $status != 0);
    chomp $message;
    if ($message) {
	describe_package($i_am, $foo, $bar);
	return;
    }
    $query = "SELECT owner, object_name, object_type FROM all_objects 
	WHERE owner = upper('$foo') AND object_name = upper('$bar') AND
		NOT object_type = 'PACKAGE_BODY'";
#    print STDERR "$query\n";
    ($status, $message) = $this->{susi}->query( $query);
    die $message if ($status != 0 && $status != 1403);
    chomp $message;
#    print STDERR "$message\n";
    # the following is just a workaround for the following situation:
    # if a pair of owner/name refers to two different objects
    # say to a table as well as to an index then $message consist of
    # more than one line.
    # the original code failed there.
    # the following workaround skips all but the 1st line of $message
    # (probably the wrong one!)
    #
    # just to be sure, use first line of $message only
    $message = (split (/\n/, $message) )[0];
    if ($message) {
	@results = split(/\t/, $message);
	find_object(@results);
    } else {
	$this->{ora_type} = "";
	$this->{status} = 1;
	return;
    }
}
#----------------------------------------------------------------
sub resolve_object {
				# Let me sort this out:
				# If it is an unqualified object it must be 
				# either a public synonym
				# or in the user's schema
				# the latter case has precedence
    my $sock = $this->{sock};
    my $object = $this->{name};
    my $i_am = $this->{user};
    my @results = ();
    my %results = ();
				# first check for my own
    my $query = "SELECT object_type FROM all_objects 
			WHERE object_name = upper('$object')
				AND owner = USER
				AND NOT object_type ='PACKAGE BODY'";
    my ($status, $ora_type) = $this->{susi}->query( $query);
    chomp $ora_type;
    if ($ora_type) {		# so it is my own
	find_object($i_am, $object, $ora_type);
    } else {			# let's look for public synonym
	my $query = "SELECT object_type FROM all_objects 
			    WHERE object_name = upper('$object')
				    AND owner = 'PUBLIC'
				    AND object_type ='SYNONYM'";
	($status, $message) = $this->{susi}->query( $query);
	chomp $message;
	if ($message) {		# so it is public
	    describe_synonym('PUBLIC', $object);
	}  else {
	    $this->{ora_type} = "";
	    $this->{status} = 1;
	}
    }
}
#----------------------------------------------------------------
sub find_object {
				# all but synonym are final
    my ($owner, $object, $ora_type) = @_;
    if ($ora_type eq "TABLE") {
	$this->{ora_type} = "TABLE";
	describe_view($owner, $object);
    } elsif ($ora_type eq "VIEW") {
	$this->{ora_type} = "VIEW";
	describe_view($owner, $object);
    } elsif ($ora_type eq "INDEX") {
	describe_index($owner, $object);
    } elsif ($ora_type eq "SEQUENCE") {
	describe_sequence($owner, $object);
    } elsif ($ora_type eq "PACKAGE") {
	describe_package($owner, $object);
    } elsif ($ora_type eq "PROCEDURE") {
	describe_procedure($owner, $object);
    } elsif ($ora_type eq "FUNCTION") {
	describe_procedure($owner, $object);
    } elsif ($ora_type eq "SYNONYM") {
	describe_synonym($owner, $object);
    }
}
#----------------------------------------------------------------
sub describe_view {  # for VIEW as well as TABLE
    my $sock = $this->{sock};
    my ($owner, $object) = @_;
    my $query = "SELECT * FROM $owner.$object";
    my ($status, $message) = $this->{susi}->open_query ($query);
    my $i = 0;
    @lines = split (/\n/, $message);
    foreach $line (@lines[1..$#lines]) {
	($name, $type, $size) = split(/\t/, $line);
#	print STDERR $line, "\n";
	$this->{args}[$i] = $name;
	$this->{ora_types}[$i] = $type;
	$this->{size}[$i++] = $size - 1;
    }
#    print $message;
    $this->{susi}->close_query();
    # for TABLE build primary key column list
    if ($this->{ora_type} eq "TABLE") {
	$query = "select a.column_name from all_cons_columns a, " .
	    "all_constraints b where a.owner = b.owner and a.constraint_name "
	    . "= b.constraint_name and a.table_name = b.table_name and "
	    . "b.constraint_type = 'P' and "
	    . "b.owner = '$owner' and b.table_name = '$object'";
	($status, $message) = $this->{susi}->query ($query);
	@lines = split (/\n/, $message);
	foreach $line (@lines) {
	    push( @{$this->{pk_fields}}, $line);
	}
    }
}
#----------------------------------------------------------------
sub describe_sequence {
}
#----------------------------------------------------------------
sub describe_procedure {
    ($owner, $object) = @_;
    my $sock = $this->{sock};
    $query = "SELECT text FROM all_source WHERE owner = UPPER('$owner')
			AND type = 'PROCEDURE' AND name = upper('$object')
			ORDER BY line";
    my ($status, $text) = $this->{susi}->query( $query);
    $text =~ s/(--.*)?\n/ /g;	# inline comments
    $text =~ s;/\*.*?\*/;;g;	# No comment
    $text =~ s;\s+; ;g;		# single spaces
    $text =~ s;(\W) ;$1;g;	# remove spaces next to non-word
    $text =~ s; (\W);$1;g;	# remove spaces next to non-word
    $text =~ s;^ ;;g;		# no space at start and end
    $text =~ s; $;;g;		# no space at start and end
    $object = lc($object);
    if (! $text) {
	$this->{ora_type} = "";
	$this->{status} = 1;
	return;
    }
    $text =~ /^(PROCEDURE|FUNCTION) $object\((.*?)\).*/i;
    $this->{ora_type} = uc($1);
    $this->{schema} = $owner;
    $args = $2;
#    print "$text #\n  $args\n";
    set_args($this, $args);
	
#    print "PROCEDURE ", lc(join('.', ($owner, $object))), "\n";
#    print_args($1);
}
#----------------------------------------------------------------
sub describe_synonym {
    my ($owner, $object) = @_;
    my $sock = $this->{sock};
    $object = uc($object);
    my $query = "SELECT ao.owner, object_name, object_type FROM 
		    all_synonyms asy, all_objects ao
		 WHERE asy.owner = '$owner' AND SYNONYM_NAME = '$object'
		      AND ao.owner = asy.table_owner AND
		     asy.table_name = ao.object_name";
    my ($status, $message) = $this->{susi}->query( $query);
			    # Let's assume that we only get one record
    chomp $message;
    if ($message) {
	my (@results) = split(/\t/, $message);
	find_object(@results);	# use references
    } else {
	$this->{ora_type} = "";
	$this->{status} = 1;
    }
}
#----------------------------------------------------------------
sub describe_package {
				# overloaded, if third argument is specified
				# only that proc (or function) is extracted
    my ($owner, $object, $proc) = @_;
    $object = lc($object);
#    print STDERR "OWNER/OBJECT/PROC: $owner/$object/$proc\n";
#    print STDERR join(':', @_);
    my $sock = $this->{sock};
    my $query = "SELECT LOWER(text) FROM all_source WHERE type = 'PACKAGE' AND
		 owner = UPPER('$owner') AND lower(name) = '$object' 
		ORDER BY line";
    my ($status, $text)  = $this->{susi}->query( $query);
    if ($status != 0 && $status != 1403) {
	$this->{status} = $status;
	$this->{error} = $message;
    }
    $text =~ s/(--.*)?\n/ /g;	# inline comments
    $text =~ s;/\*.*?\*/;;g;	# No comment
    $text =~ s;\s+; ;g;		# single spaces
    $text =~ s;(\W) ;$1;g;	# remove spaces next to non-word
    $text =~ s; (\W);$1;g;	# remove spaces next to non-word
    $text =~ s;^ ;;g;		# no space at start and end
    $text =~ s; $;;g;		# no space at start and end
    $text =~ s/^package\s(\w+)\s(a|i)s\s//;
    $text =~ s/\s?end(\s\w+)?;$//;
#    print STDERR "text $text\n";
    if (! $text) {
	$this->{ora_type} = "";
	$this->{status} = 1;
	$this->{error} = "Not found";
	return 1;
    }
				# RETURNS OF FUNCTION ??????
    if (defined $proc) {
	$proc = lc($proc);
	if ($text =~ /(procedure|function) $proc\((.*?)\)(return .*)?;/) {
#	    print STDERR "$proc $text\n";
	    $this->{ora_type} = uc($1);
	    $args = $2;
#	    print STDERR "$1 $args\n";
	    set_args($this, $args);
	} else {
	    $this->{ora_type} = "";
	    $this->{status} = 1;
	    $this->{error} = "Not found";
	    return 1;
	}
    } else {
	$this->{ora_type} = "PACKAGE";
	$i = 0;
#	print STDERR "$text";
	while ($text =~ s/(function|procedure) (\w+)\((.*?)\)(return .*?)?;//) {
#	    print STDERR "$2 $1\n";
	    $this->{components}->{$2} = uc($1);
	}
	$this->{status} = 0;
    }
    $this->{schema} = lc($owner);
    return 0;
}
#----------------------------------------------------------------
sub describe_index {
}
#----------------------------------------------------------------
sub print_args {
    my($args) = shift;
    @args = split(',', $args);
    foreach (@args) {
	if (/^(\w+)(\s.*)?\s(.+)$/) {
	    print "\t", lc($1), uc($2), " ";
	    $type = $3;
	    if ($type =~ /(.*)%type/i) {
		print lc($1)."%TYPE", "\n";
	    } else {
		print uc($type), "\n";
	    }
	}
    }
}

sub set_args {
    ($this, $args) = @_;
    @args = split(',', $args);
    $i = 0;
    foreach (@args) {
	if (/^(\w+)(\s.*)?\s(.+)$/) {
	    $name = lc($1);
	    $dir = uc($2); # in out inout
#		    print "\t", lc($1), uc($2), " ";
	    $ora_type = $3;
	    if ($ora_type =~ /(.*)%type/i) {
		$ora_type = lc($1)."%TYPE";
#			print "$ora_type", "\n";
	    } else {
		$ora_type = uc($ora_type);
#			print $ora_type, "\n";
	    }
	    $this->{args}[$i] = $name;
	    ($this->{ora_dirs}[$i] = $dir) =~ s/\s//g;
	    $this->{ora_types}[$i++] = $ora_type;
	}
    }
}

1;

# ------------------------------------------------------------------------- #
#   End of Description.pm
