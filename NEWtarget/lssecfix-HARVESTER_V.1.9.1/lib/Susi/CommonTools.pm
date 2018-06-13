#   @(#) $Id: CommonTools.pm,v 1.4 2009/03/30 06:14:37 Frank-Christian_Otto Exp $
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

=pod

=head1 NAME

CommonTools.pm  - helper functions for Rcm:utilities

=head1 SYNOPSIS

 use Susi::CommonTools;

=head1 DESCRIPTION

Some helper functions to be used in Rcm:utilities

=head1 AUTHOR

S<Frank-Christian Otto>, S<Andreas Jung>

S<(C) Copyright IBM Corporation 2000,2004>

=cut

# ---------------------------------------------------------------------------#

package Susi::CommonTools;

use Exporter;
@ISA = ('Exporter');
@EXPORT = qw( manual get_password error);

# just a test with the Term::ReadKey Module. 
# This could be the solution for the problem with missing non-echo-mode 
# on windows systems. Unfortunately ReadKey is not plain Perl. 
# It needs a binary which we would have to provide for each platform.
#use Term::ReadKey;

my $os_type='';
my ($echooff_cmd, $echoon_cmd);

if (exists $ENV{'OS'} and $ENV{'OS'}=~ /^windows/i) {
    if ((exists $ENV{'OSTYPE'} and $ENV{'OSTYPE'}=~ /cygwin/i) ||
	(exists $ENV{'MAKE_MODE'} and $ENV{'MAKE_MODE'}=~ /unix/i) ||
	(exists $ENV{'TERM'} and $ENV{'TERM'}=~ /cygwin/i) ) {
	$os_type = 'cygwin';
    } else {
	$os_type = 'windows';
    }
} else {
    $os_type = 'unix';
}


if ($os_type eq 'windows') {
    # unfortunately this doesn't work properly
    # the command window seems not to have an non echo mode
    $echooff_cmd = '@echo off';
    $echoon_cmd = '@echo on';
} elsif ($os_type eq 'cygwin') {
    $echooff_cmd = 'stty -echo';
    $echoon_cmd = 'stty echo';
} else {
    $echooff_cmd= 'stty -echo';
    $echoon_cmd ='stty echo';
}

# ------------------------------------------------------------------------- #
#  SUB error
# ------------------------------------------------------------------------- #
sub error {
    my $msg = shift;
    my $rc = shift;
    $rc = 1 unless defined $rc;

    print STDERR "$msg\n";
    exit $rc;
}

# ------------------------------------------------------------------------- #
#  SUB manual
# ------------------------------------------------------------------------- #
sub manual {
    my $POD2TEXT_PATH1 = '/usr/db/perl/CURRENT/bin';
    my $POD2TEXT_PATH2 = '/opt/Perl/bin';
    my $POD2TEXT_NAME = 'pod2text';
    my $POD2TEXT;

    if (-x $POD2TEXT_PATH1 . "/" . $POD2TEXT_NAME) {
	$POD2TEXT = $POD2TEXT_PATH1 . "/" . $POD2TEXT_NAME
    } elsif (-x $POD2TEXT_PATH2 . "/" . $POD2TEXT) {
	$POD2TEXT = $POD2TEXT_PATH2 . "/" . $POD2TEXT_NAME
    } else { # last try: perhaps pod2text can be found via the path variable
	$POD2TEXT = $POD2TEXT_NAME
    }
    system ("$POD2TEXT $0");
 
    exit 0;
}

# ------------------------------------------------------------------------- #
# SUB get_password
#
# usage: get_password ( <rcm_user> )
#    read and return a password
#    if (<rcm_user> == rcmview) no user action is necessary
# ------------------------------------------------------------------------- #
sub get_password {
    my $rcm_user = shift;
    my $passwd;

    if ( $ENV{USER} and $ENV{USER} eq $rcm_user ) {
	return $ENV{SOSPASSWD} if $ENV{SOSPASSWD};
    }

#    print STDERR "Password for $rcm_user: ";
#    ReadMode('noecho');
#    chomp($passwd = ReadLine);
#    ReadMode('normal');

    print STDERR "Password for $rcm_user: ";
    system "$echooff_cmd";
    chomp($passwd=<STDIN>);
    system "$echoon_cmd";
    print STDERR "\n";
    
    return $passwd;
}

1;

__END__

# ------------------------------------------------------------------------- #
